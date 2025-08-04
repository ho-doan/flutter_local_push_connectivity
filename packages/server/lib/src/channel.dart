import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:flutter_push_common/models/base_model.dart';
import 'package:server/src/network_session/i_network_session.dart';

class IPendingSession<T, R> {
  final INetworkSession<R> networkSession;
  final List<StreamSubscription> subscriptions;
  final String? deviceId;

  IPendingSession({
    required this.networkSession,
    this.subscriptions = const [],
    this.deviceId,
  });

  void dispose() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }
}

typedef HandleRegistration<T, R> =
    void Function(User user, IPendingSession<T, R> session, ChannelType type);
typedef HandleDisconnect = void Function(String deviceId, ChannelType type);

typedef HandleMessage =
    void Function(BaseModel message, String deviceId, ChannelType type);

abstract class IChannel<T, R> {
  final int port;
  final ChannelType type;
  final HandleRegistration<T, R>? onRegister;
  final HandleDisconnect? onDisconnect;
  final ValueChanged<String>? onLog;
  final HandleMessage? onMessage;
  T? server;

  final Map<String, IPendingSession<T, R>> _pendingSessions = {};

  IChannel({
    required this.port,
    required this.type,
    this.onRegister,
    this.onDisconnect,
    this.onLog,
    this.onMessage,
  });

  Future<T?> start();
  Future<void> stop();
  Future<void> setupConnection(R connection);
}

class TCPChannel extends IChannel<ServerSocket, Socket> {
  TCPChannel({
    required super.port,
    required super.type,
    super.onRegister,
    super.onDisconnect,
    super.onMessage,
  });

  @override
  Future<ServerSocket?> start() async {
    try {
      server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      onLog?.call('Listening on port $port');

      server!.listen((socket) {
        onLog?.call('Received new connection');
        setupConnection(socket);
      });
      return server;
    } catch (e) {
      onLog?.call('Error creating server: $e');
      return null;
    }
  }

  @override
  Future<void> setupConnection(Socket connection) async {
    onLog?.call('Setting up connection');
    final networkSession = TcpNetworkSession<Socket>();

    if (type == ChannelType.notification) {
      // For notification channel, we don't want to disconnect on failure
      // as the connection might succeed in the near future
      networkSession.disconnectOnFailure = false;
    }

    final subscriptions = <StreamSubscription>[];
    String? deviceId;

    void handleRegistration(User user) {
      deviceId = user.deviceId;
      onLog?.call('Received registration for user ${user.deviceName}');

      var pendingSession = _pendingSessions.values.firstWhere(
        (e) => e.networkSession.hashCode == networkSession.hashCode,
      );
      // if (pendingSession == null) {
      //   pendingSession = _pendingSessions.values.firstWhere(
      //     (e) => e.networkSession.hashCode == networkSession.hashCode,
      //   );
      //   _pendingSessions.remove(pendingSession);
      //   _pendingSessions['$deviceId-${type.name}'] = pendingSession;
      // }

      // final pendingSession = _pendingSessions.lookup(
      //   IPendingSession<Socket>(
      //     networkSession: networkSession as INetworkSession<Socket>,
      //     subscriptions: subscriptions,
      //     deviceId: deviceId,
      //   ),
      // );
      onRegister?.call(user, pendingSession, type);
      pendingSession.dispose();
      _pendingSessions.remove(pendingSession);
    }

    // Listen for user registration and messages
    subscriptions.add(
      networkSession.messageStream.listen((message) {
        log('Received message channel ${type.name}: $message');
        if (message is Map &&
            message.containsKey('deviceName') &&
            message.containsKey('deviceId')) {
          final user = User.fromJson(message as Map<String, dynamic>);
          deviceId = user.deviceId;
          handleRegistration(user);
        } else if (message is User) {
          deviceId = message.deviceId;
          handleRegistration(message);
        } else if (deviceId != null) {
          // Forward other messages to the handler
          onMessage?.call(message, deviceId!, type);
        } else if (message is TextMessage) {
          onMessage?.call(message, deviceId!, type);
        }
      }),
    );

    // Listen for disconnection
    subscriptions.add(
      networkSession.stateStream.listen((state) {
        log('Network session state changed: $state');
        if (state == NetworkSessionState.disconnected && deviceId != null) {
          onDisconnect?.call(deviceId!, type);
        }
      }),
    );

    final pendingSession = IPendingSession<ServerSocket, Socket>(
      networkSession: networkSession,
      subscriptions: subscriptions,
      deviceId: deviceId,
    );

    _pendingSessions['$deviceId-${type.name}'] = pendingSession;
    networkSession.connect(connection);
  }

  @override
  Future<void> stop() async {
    for (final session in _pendingSessions.values) {
      session.dispose();
    }
    _pendingSessions.clear();
    await server?.close();
    server = null;
  }
}
