import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'api/api_handler.dart';
import 'channel.dart';
import 'client.dart';
import 'messages.g.dart';
import 'network_session/request_response_session.dart';

class Server extends ChangeNotifier {
  final int notificationPort;
  final int controlPort;
  final int apiPort;

  ServerSocket? _notificationServer;
  ServerSocket? _controlServer;
  ApiHandler? _apiHandler;

  final Map<String?, Client> _clients = {};
  final Map<String, GroupPigeon> _groups = {};
  final _logController = StreamController<String>.broadcast();

  Stream<String> get logStream => _logController.stream;
  List<UserPigeon> get connectedClients =>
      _clients.values
          .map((client) => client.user)
          .where((user) => user.deviceId != null)
          .toList();

  Server({
    this.notificationPort = 8080,
    this.controlPort = 8081,
    this.apiPort = 8082,
  });

  Future<void> start() async {
    try {
      // Start TCP servers
      _notificationServer = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        notificationPort,
      );
      _controlServer = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        controlPort,
      );

      _log('Notification server listening on port $notificationPort');
      _log('Control server listening on port $controlPort');

      // Setup notification channel
      Channel(
        port: notificationPort,
        type: ChannelType.notification,
        onRegister: _handleRegistration,
        onDisconnect: _handleDisconnection,
        onMessage: _handleMessage,
      );

      // Setup control channel
      Channel(
        port: controlPort,
        type: ChannelType.control,
        onRegister: _handleRegistration,
        onDisconnect: _handleDisconnection,
        onMessage: _handleMessage,
      );

      // Start REST API server
      _apiHandler = ApiHandler(this);
      await _apiHandler?.start(port: apiPort);
      _log('REST API server listening on port $apiPort');
    } catch (e) {
      _log('Failed to start server: $e');
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    await _notificationServer?.close();
    await _controlServer?.close();
    await _apiHandler?.stop();
    _notificationServer = null;
    _controlServer = null;
    _apiHandler = null;
    _clients.clear();
    _groups.clear();
    notifyListeners();
    _log('Server stopped');
  }

  void _handleRegistration(
    UserPigeon user,
    RequestResponseSession session,
    ChannelType type,
  ) {
    final deviceId = user.deviceId;
    if (deviceId == null) {
      _log('Received registration with null deviceId');
      return;
    }

    var client = _clients[deviceId];
    if (client == null) {
      client = Client();
      client.user = user;
      _clients[deviceId] = client;
      _log('New client registered: ${user.deviceName} (${user.deviceId})');
      notifyListeners();
    }

    client.setSession(session, type);

    // Send current directory to all clients when a new client connects
    if (type == ChannelType.control) {
      _broadcastDirectory();
    }
  }

  void _handleDisconnection(String deviceId, ChannelType type) {
    final client = _clients[deviceId];
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
        client.user.status = UserStatus.offline;
        _clients.remove(deviceId);
        _log(
          'Client disconnected: ${client.user.deviceName} (${client.user.deviceId})',
        );
        notifyListeners();
        _broadcastDirectory();
      }
    }
  }

  void _handleMessage(dynamic message, String fromDeviceId, ChannelType type) {
    log('Received message _handleMessage: $message');
    final fromClient = _clients[fromDeviceId];
    if (fromClient == null) {
      _log('Message from unknown client: $fromDeviceId');
      return;
    }

    if (type == ChannelType.notification) {
      _handleNotificationMessage(message, fromClient);
    } else {
      _handleControlMessage(message, fromClient);
    }
  }

  void _handleNotificationMessage(dynamic message, Client fromClient) {
    void handleTextMessage(TextMessagePigeon textMessage) {
      final toClient = _clients[textMessage.to?.deviceId];
      if (toClient == null) {
        _log('Recipient not found: ${textMessage.to?.deviceId}');
        return;
      }
      toClient.send(textMessage);
      _log(
        'Message forwarded from ${fromClient.user.deviceName} to ${toClient.user.deviceName}',
      );
    }

    if (message is Map<String, dynamic>) {
      if (message.containsKey('message')) {
        final textMessage =
            TextMessagePigeon()
              ..from = fromClient.user
              ..to = _clients[message['to']?['deviceId']]?.user
              ..message = message['message'] as String?;
        handleTextMessage(textMessage);
      }
    } else if (message is TextMessagePigeon) {
      handleTextMessage(message);
    }
  }

  void _handleControlMessage(dynamic message, Client fromClient) {
    if (message is StatusUpdatePigeon) {
      _handleStatusUpdate(message, fromClient);
    } else if (message is GroupActionPigeon) {
      _handleGroupAction(message, fromClient);
    } else if (message is SyncRequestPigeon) {
      _handleSyncRequest(message, fromClient);
    } else if (message is CallActionPigeon) {
      _handleCallAction(message, fromClient);
    }
  }

  void _handleStatusUpdate(StatusUpdatePigeon message, Client fromClient) {
    fromClient.user.status = message.status;
    _log('Status updated for ${fromClient.user.deviceName}: ${message.status}');
    _broadcastDirectory();
  }

  void _handleGroupAction(GroupActionPigeon message, Client fromClient) {
    switch (message.action) {
      case 'create':
        if (message.group != null) {
          message.group!.owner = fromClient.user;
          _groups[message.group!.groupId!] = message.group!;
          _log('Group created: ${message.group!.name}');
          _broadcastGroupUpdate(message.group!);
        }
      case 'join':
        final group = _groups[message.group?.groupId];
        if (group != null) {
          group.members ??= [];
          if (!group.members!.contains(fromClient.user)) {
            group.members!.add(fromClient.user);
            _log('${fromClient.user.deviceName} joined group: ${group.name}');
            _broadcastGroupUpdate(group);
          }
        }
      case 'leave':
        final group = _groups[message.group?.groupId];
        if (group != null) {
          group.members?.remove(fromClient.user);
          _log('${fromClient.user.deviceName} left group: ${group.name}');
          _broadcastGroupUpdate(group);
        }
      case 'invite':
        final group = _groups[message.group?.groupId];
        if (group != null && message.user != null) {
          final invitee = _clients[message.user!.deviceId];
          if (invitee != null) {
            final invite =
                InvitePigeon()
                  ..from = fromClient.user
                  ..to = invitee.user
                  ..message = 'Invited to join group: ${group.name}';
            invitee.send(invite);
            _log(
              '${fromClient.user.deviceName} invited ${invitee.user.deviceName} to group: ${group.name}',
            );
          }
        }
    }
  }

  void _handleSyncRequest(SyncRequestPigeon message, Client fromClient) {
    final response =
        SyncResponsePigeon()
          ..type = message.type
          ..timestamp = DateTime.now().millisecondsSinceEpoch;

    switch (message.type) {
      case 'contacts':
        response.data = connectedClients;
      case 'groups':
        response.data =
            _groups.values
                .where(
                  (group) => group.members?.contains(fromClient.user) ?? false,
                )
                .toList();
    }

    fromClient.send(response);
    _log(
      'Sync response sent to ${fromClient.user.deviceName}: ${message.type}',
    );
  }

  void _handleCallAction(CallActionPigeon message, Client fromClient) {
    final toClient = _clients[message.to?.deviceId];
    if (toClient == null) {
      _log('Call recipient not found: ${message.to?.deviceId}');
      return;
    }

    message.from = fromClient.user;
    toClient.send(message);
    _log(
      'Call action forwarded: ${message.action} from ${fromClient.user.deviceName} to ${toClient.user.deviceName}',
    );
  }

  void _broadcastDirectory() {
    final directory =
        DirectoryPigeon()
          ..users = _clients.values.map((client) => client.user).toList();

    for (final client in _clients.values) {
      client.send(directory);
    }
  }

  void _broadcastGroupUpdate(GroupPigeon group) {
    final update =
        GroupActionPigeon()
          ..action = 'update'
          ..group = group;

    for (final member in group.members ?? []) {
      final client = _clients[member.deviceId];
      if (client != null) {
        client.send(update);
      }
    }
  }

  bool sendMessage(TextMessagePigeon message) {
    final toClient = _clients[message.to?.deviceId];
    if (toClient == null) {
      _log('Cannot send message: recipient not found');
      return false;
    }

    toClient.send(message);
    _log(
      'Server message sent to ${message.to?.deviceName}: ${message.message}',
    );
    return true;
  }

  void _log(String message) {
    log(message);
    _logController.add(message);
  }

  @override
  void dispose() {
    stop();
    for (final client in _clients.values) {
      client.dispose();
    }
    _clients.clear();
    _logController.close();
    super.dispose();
  }
}
