import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:flutter_push_common/models/base_model.dart';
import 'package:server/src/errors.dart';
import 'package:server/src/network_session/i_network_session.dart';

import 'heartbeat_coordinator.dart';

enum ClientState { disconnected, connected }

class Connection<R> {
  final String uuid;
  final ChannelType type;
  final INetworkSession<R> networkSession;
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

class Client<T, R> extends ChangeNotifier {
  late User user;
  ClientState notificationChannelState = ClientState.disconnected;
  ClientState controlChannelState = ClientState.disconnected;

  bool notificationIsResponsive = false;

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

  void setSession(INetworkSession<R> networkSession, ChannelType type) {
    final connectionId = DateTime.now().millisecondsSinceEpoch.toString();
    final subscriptions = <StreamSubscription>[];

    HeartbeatCoordinator? heartbeatCoordinator;

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

    // subscriptions.add(
    //   networkSession.messageStream.listen((message) {
    //     log('Received message client: $message');
    //     if (message is! Heartbeat) {
    //       if (message is User) {
    //         user = message;
    //         notifyListeners();
    //       } else {
    //         send(message);
    //       }
    //     }
    //   }),
    // );

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

  void request(BaseModel message, Connection connection) {
    final session = connection.networkSession as INetworkSession<R>?;
    if (session == null) {
      throw SessionError.missingSession();
    }
    session.request(message);
  }

  void send(BaseModel data) {
    log('Sending data: $data with type ${data.runtimeType}');
    if (data is Directory || data is Call) {
      final connection = _networkSessions[ChannelType.control];
      if (connection != null) {
        request(data, connection);
      }
    } else if (data is Invite || data is TextMessage) {
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
    notificationIsResponsiveController.close();
    notificationChannelConnectedController.close();
    controlChannelConnectedController.close();
    super.dispose();
  }
}
