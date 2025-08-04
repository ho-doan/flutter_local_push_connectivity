import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:server/src/errors.dart';
import 'package:server/src/messages.g.dart';
import 'package:server/src/network_session/i_network_session.dart';
import 'package:server/src/network_session/request_response_session.dart';

import 'heartbeat_coordinator.dart';

enum ClientState { disconnected, connected }

class Connection {
  final String uuid;
  final ChannelType type;
  final INetworkSession networkSession;
  final HeartbeatCoordinator? heartbeatCoordinator;
  final List<StreamSubscription> subscriptions;

  Connection({
    required this.uuid,
    required this.type,
    required this.networkSession,
    this.heartbeatCoordinator,
    this.subscriptions = const [],
  });
}

class Client extends ChangeNotifier {
  late UserPigeon user;
  ClientState notificationChannelState = ClientState.disconnected;
  ClientState controlChannelState = ClientState.disconnected;

  bool notificationIsResponsive = false;

  final _messageController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get messagesStream => _messageController.stream;

  final Map<ChannelType, Connection> _networkSessions = {};
  final Duration heartbeatInterval = const Duration(seconds: 10);

  late final StreamController<bool> notificationIsResponsiveController =
      StreamController<bool>.broadcast()..add(notificationIsResponsive);

  late final StreamController<ClientState>
  notificationChannelConnectedController =
      StreamController<ClientState>.broadcast()..add(notificationChannelState);

  late final StreamController<ClientState> controlChannelConnectedController =
      StreamController<ClientState>.broadcast()..add(controlChannelState);

  Client();

  void setSession(INetworkSession networkSession, ChannelType type) {
    final connectionId = DateTime.now().millisecondsSinceEpoch.toString();
    final subscriptions = <StreamSubscription>[];

    HeartbeatCoordinator? heartbeatCoordinator;

    if (networkSession is! RequestResponseSession) {
      throw SessionError.invalidSession();
    }

    heartbeatCoordinator = HeartbeatCoordinator(interval: heartbeatInterval);
    heartbeatCoordinator.session = networkSession;

    if (type == ChannelType.notification) {
      subscriptions.add(
        heartbeatCoordinator.isSessionResponsiveStream.listen((isResponsive) {
          notificationIsResponsive = isResponsive;
          notificationIsResponsiveController.add(isResponsive);
        }),
      );
    }

    // Listen to network session state changes
    subscriptions.add(
      networkSession.stateStream.listen((state) {
        switch (type) {
          case ChannelType.control:
            controlChannelState =
                state == NetworkSessionState.connected
                    ? ClientState.connected
                    : ClientState.disconnected;
            controlChannelConnectedController.add(controlChannelState);
          case ChannelType.notification:
            final newState =
                state == NetworkSessionState.connected &&
                        notificationIsResponsive
                    ? ClientState.connected
                    : ClientState.disconnected;
            if (notificationChannelState != newState) {
              notificationChannelState = newState;
              notificationChannelConnectedController.add(
                notificationChannelState,
              );
            }
        }

        if (state == NetworkSessionState.connected) {
          log('${type.name} Channel connected');
          try {
            heartbeatCoordinator?.start();
          } catch (e) {
            log(
              'Unable to start heartbeat coordinator for ${type.name} channel: $e',
            );
          }
        } else if (state == NetworkSessionState.disconnected) {
          log('${type.name} Channel disconnected');
          heartbeatCoordinator?.stop();
          cleanupSession(connectionId);
        }
      }),
    );

    if (networkSession is RequestResponseSession) {
      subscriptions.add(
        networkSession.messageStream.listen((message) {
          if (message is! HeartbeatPigeon) {
            if (message is UserPigeon) {
              user = message;
              notifyListeners();
            } else {
              _messageController.add(message);
            }
          }
        }),
      );
    }

    final connection = Connection(
      uuid: connectionId,
      type: type,
      networkSession: networkSession,
      heartbeatCoordinator: heartbeatCoordinator,
      subscriptions: subscriptions,
    );

    _networkSessions[type] = connection;
    if (type == ChannelType.control) {
      connection.heartbeatCoordinator?.start();
    }
  }

  void cleanupSession(String connectedId) {
    _networkSessions.removeWhere((key, connection) {
      if (connection.uuid == connectedId) {
        for (final subscription in connection.subscriptions) {
          subscription.cancel();
        }
        return true;
      }
      return false;
    });
  }

  void request<T>(T message, Connection connection) {
    final session = connection.networkSession as RequestResponseSession?;
    if (session == null) {
      throw SessionError.missingSession();
    }
    session.request(message);
  }

  void send(dynamic data) {
    if (data is DirectoryPigeon || data is CallActionPigeon) {
      final connection = _networkSessions[ChannelType.control];
      if (connection != null) {
        request(data, connection);
      }
    } else if (data is InvitePigeon || data is TextMessagePigeon) {
      log('Sending data: $data with type ${data.runtimeType}');
      final connection = _networkSessions[ChannelType.notification];
      if (connection != null) {
        request(data, connection);
      }
    }
  }

  @override
  void dispose() {
    for (final connection in _networkSessions.values) {
      for (final subscription in connection.subscriptions) {
        subscription.cancel();
      }
    }
    _networkSessions.clear();
    _messageController.close();
    notificationIsResponsiveController.close();
    notificationChannelConnectedController.close();
    controlChannelConnectedController.close();
    super.dispose();
  }
}
