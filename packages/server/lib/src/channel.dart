import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:server/src/messages.g.dart';
import 'package:server/src/network_session/i_network_session.dart';
import 'package:server/src/network_session/request_response_session.dart';

class PendingSession {
  final RequestResponseSession networkSession;
  final List<StreamSubscription> subscriptions;
  final String? deviceId;

  PendingSession({
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

class Channel {
  final int port;
  final ChannelType type;
  final void Function(
    UserPigeon user,
    RequestResponseSession session,
    ChannelType type,
  )?
  onRegister;
  final void Function(String deviceId, ChannelType type)? onDisconnect;
  final void Function(dynamic message, String deviceId, ChannelType type)?
  onMessage;

  ServerSocket? _server;
  final Set<PendingSession> _pendingSessions = {};

  Channel({
    required this.port,
    required this.type,
    this.onRegister,
    this.onDisconnect,
    this.onMessage,
  });

  Future<void> start() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      log('Listening on port $port');

      _server?.listen((socket) {
        log('Received new connection');
        _setupConnection(socket);
      });
    } catch (e) {
      log('Error creating server: $e');
    }
  }

  void stop() {
    for (final session in _pendingSessions) {
      session.dispose();
    }
    _pendingSessions.clear();
    _server?.close();
    _server = null;
  }

  void _setupConnection(Socket socket) {
    final networkSession = RequestResponseSession();

    if (type == ChannelType.notification) {
      // For notification channel, we don't want to disconnect on failure
      // as the connection might succeed in the near future
      networkSession.disconnectOnFailure = false;
    }

    final subscriptions = <StreamSubscription>[];
    String? deviceId;

    void handleRegistration(UserPigeon user) {
      deviceId = user.deviceId;
      log('Received registration for user ${user.deviceName}');
      onRegister?.call(user, networkSession, type);

      final pendingSession = _pendingSessions.lookup(
        PendingSession(
          networkSession: networkSession,
          subscriptions: subscriptions,
          deviceId: deviceId,
        ),
      );
      if (pendingSession != null) {
        pendingSession.dispose();
        _pendingSessions.remove(pendingSession);
      }
    }

    // Listen for user registration and messages
    subscriptions.add(
      networkSession.messageStream.listen((message) {
        log('Received message ${type.name}: $message');
        if (message is Map &&
            message.containsKey('deviceName') &&
            message.containsKey('deviceId')) {
          final user =
              UserPigeon()
                ..deviceName = message['deviceName'] as String?
                ..deviceId = message['deviceId'] as String?;
          handleRegistration(user);
        } else if (message is UserPigeon) {
          handleRegistration(message);
        } else if (deviceId != null) {
          // Forward other messages to the handler
          onMessage?.call(message, deviceId!, type);
        } else if (message is TextMessagePigeon) {
          onMessage?.call(message, deviceId!, type);
        }
      }),
    );

    // Listen for disconnection
    subscriptions.add(
      networkSession.stateStream.listen((state) {
        if (state == NetworkSessionState.disconnected && deviceId != null) {
          onDisconnect?.call(deviceId!, type);
        }
      }),
    );

    final pendingSession = PendingSession(
      networkSession: networkSession,
      subscriptions: subscriptions,
      deviceId: deviceId,
    );

    _pendingSessions.add(pendingSession);
    networkSession.connect(socket);
  }
}
