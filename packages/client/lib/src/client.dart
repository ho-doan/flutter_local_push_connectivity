import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:client/src/models/message.dart';
import 'package:client/src/models/user.dart';

enum ConnectionState { disconnected, connecting, connected }

class Client extends ChangeNotifier {
  final String host;
  final int notificationPort;
  final int controlPort;
  final User user;

  Socket? _notificationSocket;
  Socket? _controlSocket;
  final _messageController = StreamController<Message>.broadcast();
  final _directoryController = StreamController<List<User>>.broadcast();

  ConnectionState _notificationState = ConnectionState.disconnected;
  ConnectionState _controlState = ConnectionState.disconnected;

  Stream<Message> get messageStream => _messageController.stream;
  Stream<List<User>> get directoryStream => _directoryController.stream;
  ConnectionState get notificationState => _notificationState;
  ConnectionState get controlState => _controlState;

  Client({
    required this.host,
    required this.notificationPort,
    required this.controlPort,
    required this.user,
  });

  Future<void> connect() async {
    try {
      // Connect notification channel
      _setNotificationState(ConnectionState.connecting);
      _notificationSocket = await Socket.connect(host, notificationPort);
      _setupNotificationSocket();
      await _register(_notificationSocket!, isNotification: true);
      _setNotificationState(ConnectionState.connected);

      // Connect control channel
      _setControlState(ConnectionState.connecting);
      _controlSocket = await Socket.connect(host, controlPort);
      _setupControlSocket();
      await _register(_controlSocket!, isNotification: false);
      _setControlState(ConnectionState.connected);
    } catch (e) {
      disconnect();
      rethrow;
    }
  }

  void disconnect() {
    _notificationSocket?.destroy();
    _notificationSocket = null;
    _setNotificationState(ConnectionState.disconnected);

    _controlSocket?.destroy();
    _controlSocket = null;
    _setControlState(ConnectionState.disconnected);
  }

  void _setupNotificationSocket() {
    _notificationSocket?.listen(
      (data) {
        final message = _decodeMessage(data);
        if (message != null) {
          if (message is Map<String, dynamic>) {
            if (message.containsKey('message')) {
              final from = User.fromJson(
                message['from'] as Map<String, dynamic>,
              );
              final to = User.fromJson(message['to'] as Map<String, dynamic>);
              final text = message['message'] as String;

              _messageController.add(Message(from: from, to: to, text: text));
            }
          }
        }
      },
      onError: (error) {
        log('Notification socket error: $error');
        _setNotificationState(ConnectionState.disconnected);
      },
      onDone: () {
        _setNotificationState(ConnectionState.disconnected);
      },
    );
  }

  void _setupControlSocket() {
    _controlSocket?.listen(
      (data) {
        final message = _decodeMessage(data);
        if (message != null) {
          if (message is Map<String, dynamic> && message.containsKey('users')) {
            final userList =
                (message['users'] as List<dynamic>)
                    .map((e) => User.fromJson(e as Map<String, dynamic>))
                    .toList();
            _directoryController.add(userList);
          }
        }
      },
      onError: (error) {
        log('Control socket error: $error');
        _setControlState(ConnectionState.disconnected);
      },
      onDone: () {
        _setControlState(ConnectionState.disconnected);
      },
    );
  }

  Future<void> _register(Socket socket, {required bool isNotification}) async {
    final data = jsonEncode({
      'deviceName': user.deviceName,
      'deviceId': user.deviceId,
    });

    final buffer = _encodeMessage(data);
    socket.add(buffer);
    await socket.flush();
  }

  Future<void> sendMessage(String text, User recipient) async {
    if (_notificationState != ConnectionState.connected) {
      throw Exception('Not connected to notification channel');
    }

    final message = {
      'from': {'deviceName': user.deviceName, 'deviceId': user.deviceId},
      'to': {
        'deviceName': recipient.deviceName,
        'deviceId': recipient.deviceId,
      },
      'message': text,
    };

    final data = jsonEncode(message);
    final buffer = _encodeMessage(data);
    _notificationSocket?.add(buffer);
    await _notificationSocket?.flush();
  }

  List<int> _encodeMessage(String data) {
    final messageBytes = utf8.encode(data);
    final length = messageBytes.length;
    final buffer = ByteData(4 + length);

    // Write length prefix
    buffer.setInt32(0, length, Endian.big);

    // Write message data
    final list = buffer.buffer.asUint8List();
    list.setRange(4, 4 + length, messageBytes);

    return list;
  }

  dynamic _decodeMessage(List<int> data) {
    try {
      if (data.length < 4) return null;

      final buffer = ByteData.view(Uint8List.fromList(data).buffer);
      final length = buffer.getInt32(0, Endian.big);

      if (data.length < 4 + length) return null;

      final messageBytes = data.sublist(4, 4 + length);
      final messageStr = utf8.decode(messageBytes);
      return jsonDecode(messageStr);
    } catch (e) {
      log('Error decoding message: $e');
      return null;
    }
  }

  void _setNotificationState(ConnectionState state) {
    if (_notificationState != state) {
      _notificationState = state;
      notifyListeners();
    }
  }

  void _setControlState(ConnectionState state) {
    if (_controlState != state) {
      _controlState = state;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _directoryController.close();
    super.dispose();
  }
}
