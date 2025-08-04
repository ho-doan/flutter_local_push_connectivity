import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:flutter_push_common/models/base_model.dart';

import 'api/api_handler.dart';
import 'channel.dart';
import 'client.dart';

abstract class IServer<T, R> extends ChangeNotifier {
  final int notificationPort;
  final int controlPort;
  final int apiPort;

  IServer({
    this.notificationPort = Constants.notificationPort,
    this.controlPort = Constants.controlPort,
    this.apiPort = Constants.apiPort,
  });

  Future<void> start();

  bool sendMessage(TextMessage message) {
    log('sendMessage: $message');
    final toClient = clients[message.to.deviceId];
    if (toClient == null) {
      logger('Cannot send message: recipient not found');
      return false;
    }

    toClient.send(message);
    logger(
      'Server message sent to ${message.to.deviceName}: ${message.message}',
    );
    return true;
  }

  Future<void> stop() async {
    await notificationChannel.stop();
    await controlChannel.stop();
    await apiHandler.stop();
    clients.clear();
    groups.clear();
    notifyListeners();
    logger('Server stopped');
  }

  void handleRegistration(
    User user,
    IPendingSession<T, R> session,
    ChannelType type,
  );

  void handleDisconnection(String deviceId, ChannelType type);

  void handleMessage(BaseModel message, String deviceId, ChannelType type);

  void logger(String message) {
    log('Server: $message');
    _logController.add(message);
  }

  late TCPChannel notificationChannel;
  late TCPChannel controlChannel;
  late ApiHandler apiHandler;

  final Map<String, Client> clients = {};
  final Map<String, Group> groups = {};

  final _logController = StreamController<String>.broadcast();

  Stream<String> get logStream => _logController.stream;

  List<User> get connectedClients =>
      clients.values.map((client) => client.user).toList();

  void broadcastDirectory() {
    log('broadcastDirectory');
    final directory = Directory(
      users: clients.values.map((client) => client.user).toList(),
    );

    for (final client in clients.values) {
      client.send(directory);
    }
  }

  void handleTextMessage(TextMessage textMessage, Client fromClient) {
    final toClient = clients[textMessage.to.deviceId];
    if (toClient == null) {
      logger('Recipient not found: ${textMessage.to.deviceId}');
      return;
    }
    toClient.send(textMessage);
    logger(
      'Message forwarded from ${fromClient.user.deviceName} to ${toClient.user.deviceName}',
    );
  }

  void handleNotificationMessage(BaseModel message, Client fromClient) {
    log('handleNotificationMessage: $message');

    if (message is TextMessage) {
      handleTextMessage(message, fromClient);
    } else {
      logger('Unsupported message type: ${message.runtimeType}');
    }
  }

  void _handleStatusUpdate(StatusUpdate message, Client fromClient) {
    fromClient.user = fromClient.user.copyWith(status: message.status);
    logger(
      'Status updated for ${fromClient.user.deviceName}: ${message.status}',
    );
    broadcastDirectory();
  }

  void _broadcastGroupUpdate(Group group) {
    log('broadcastGroupUpdate: $group');
    final update = GroupAction(action: GroupActionEnum.update, group: group);

    for (final member in group.users) {
      final client = clients[member.deviceId];
      if (client != null) {
        client.send(update);
      }
    }
  }

  void _handleGroupAction(GroupAction message, Client fromClient) {
    log('handleGroupAction: $message');
    switch (message.action) {
      case GroupActionEnum.create:
        if (message.group != null) {
          message.group!.admins.add(fromClient.user);
          groups[message.group!.id] = message.group!;
          logger('Group created: ${message.group!.name}');
          _broadcastGroupUpdate(message.group!);
        }
      case GroupActionEnum.join:
        final group = groups[message.group?.id];
        if (group != null) {
          group.users.add(fromClient.user);
          logger('${fromClient.user.deviceName} joined group: ${group.name}');
          _broadcastGroupUpdate(group);
        }
      case GroupActionEnum.leave:
        final group = groups[message.group?.id];
        if (group != null) {
          group.users.remove(fromClient.user);
          logger('${fromClient.user.deviceName} left group: ${group.name}');
          _broadcastGroupUpdate(group);
        }
      case GroupActionEnum.invite:
        final group = groups[message.group?.id];
        if (group != null && message.user != null) {
          final invitee = clients[message.user!.deviceId];
          if (invitee != null) {
            final invite = Invite(from: fromClient.user, to: invitee.user);
            invitee.send(invite);
            logger(
              '${fromClient.user.deviceName} invited ${invitee.user.deviceName} to group: ${group.name}',
            );
          }
        }
      case GroupActionEnum.update:
        if (message.group != null) {
          groups[message.group!.id] = message.group!;
          logger('Group updated: ${message.group!.name}');
          _broadcastGroupUpdate(message.group!);
        }
        break;
    }
  }

  void _handleSyncRequest(SyncRequest message, Client fromClient) {
    log('handleSyncRequest: $message');
    var response = SyncResponse(
      type: message.type,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      data: [],
    );

    switch (message.type) {
      case 'contacts':
        response = response.copyWith(data: connectedClients);
      case 'groups':
        response = response.copyWith(
          data:
              groups.values
                  .where((group) => group.users.contains(fromClient.user))
                  .toList(),
        );
    }

    fromClient.send(response);
    logger(
      'Sync response sent to ${fromClient.user.deviceName}: ${message.type}',
    );
  }

  void _handleCallAction(Call message, Client fromClient) {
    log('handleCallAction: $message');
    final toClient = clients[message.to.deviceId];
    if (toClient == null) {
      logger('Call recipient not found: ${message.to.deviceId}');
      return;
    }

    message = message.copyWith(from: fromClient.user);
    toClient.send(message);
    logger(
      'Call action forwarded: ${message.action} from ${fromClient.user.deviceName} to ${toClient.user.deviceName}',
    );
  }

  void handleControlMessage(BaseModel message, Client fromClient) {
    log('handleControlMessage: $message');
    if (message is StatusUpdate) {
      _handleStatusUpdate(message, fromClient);
    } else if (message is GroupAction) {
      _handleGroupAction(message, fromClient);
    } else if (message is SyncRequest) {
      _handleSyncRequest(message, fromClient);
    } else if (message is Call) {
      _handleCallAction(message, fromClient);
    }
  }
}

class TcpServer extends IServer<ServerSocket, Socket> {
  TcpServer({
    super.notificationPort = Constants.notificationPort,
    super.controlPort = Constants.controlPort,
    super.apiPort = Constants.apiPort,
  });

  @override
  Future<void> start() async {
    try {
      logger('Notification server listening on port $notificationPort');
      logger('Control server listening on port $controlPort');

      // Setup notification channel
      notificationChannel = TCPChannel(
        port: notificationPort,
        type: ChannelType.notification,
        onRegister: handleRegistration,
        onDisconnect: handleDisconnection,
        onMessage: handleMessage,
      );
      await notificationChannel.start();

      // Setup control channel
      controlChannel = TCPChannel(
        port: controlPort,
        type: ChannelType.control,
        onRegister: handleRegistration,
        onDisconnect: handleDisconnection,
        onMessage: handleMessage,
      );
      await controlChannel.start();

      // Start REST API server
      apiHandler = ApiHandler(this);
      await apiHandler.start(port: apiPort);
      logger('REST API server listening on port $apiPort');
    } catch (e) {
      logger('Failed to start server: $e');
      await stop();
      rethrow;
    }
  }

  @override
  void handleDisconnection(String deviceId, ChannelType type) {
    log('handleDisconnection: $deviceId');
    final client = clients[deviceId];
    if (client != null) {
      if (type == ChannelType.notification) {
        client.notificationChannelState = ClientState.disconnected;
      } else {
        client.controlChannelState = ClientState.disconnected;
      }

      // If both channels are disconnected, remove the client
      if (client.notificationChannelState == ClientState.disconnected &&
          client.controlChannelState == ClientState.disconnected) {
        // Update user status to offline
        client.user = client.user.copyWith(status: UserStatus.offline);
        clients.remove(deviceId);
        logger(
          'Client disconnected: ${client.user.deviceName} (${client.user.deviceId})',
        );
        notifyListeners();
        broadcastDirectory();
      }
    }
  }

  @override
  void handleMessage(BaseModel message, String deviceId, ChannelType type) {
    log('Received message _handleMessage: $message');
    final fromClient = clients[deviceId];
    if (fromClient == null) {
      if (message is Heartbeat) {
        logger('Heartbeat $deviceId #${message.count}');
      } else {
        logger('Message from unknown client: $deviceId');
      }
      return;
    }

    if (type == ChannelType.notification) {
      handleNotificationMessage(message, fromClient);
    } else {
      handleControlMessage(message, fromClient);
    }
  }

  @override
  void handleRegistration(
    User user,
    IPendingSession<ServerSocket, Socket> session,
    ChannelType type,
  ) {
    log('handleRegistration: $user');
    final deviceId = user.deviceId;
    var client = clients[deviceId];
    if (client == null) {
      client = Client<ServerSocket, Socket>();
      client.user = user;
      clients[deviceId] = client;
      logger('New client registered: ${user.deviceName} (${user.deviceId})');
    }

    log('======= handleRegistration: ${session.networkSession.runtimeType}');

    client.setSession(session.networkSession, type);

    // Send current directory to all clients when a new client connects
    if (type == ChannelType.control) {
      broadcastDirectory();
    }
    notifyListeners();
  }
}
