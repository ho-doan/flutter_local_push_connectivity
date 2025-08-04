import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'models/user.dart';

class HeartbeatPigeon {
  final int count;
  const HeartbeatPigeon({this.count = 0});

  Map<String, dynamic> toJson() => {'count': count};
}

class ChatClient {
  final String host;
  final int notificationPort;
  final int controlPort;
  final String deviceName;

  Socket? _notificationSocket;
  Socket? _controlSocket;
  bool _isConnected = false;
  String? _deviceId;
  Timer? _heartbeatTimer;
  int _heartbeatCount = 1;
  bool _isControlSocketResponsive = false;
  DateTime? _lastHeartbeatResponse;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _directoryController = StreamController<List<User>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _controlSocketStateController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<List<User>> get directoryStream => _directoryController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get controlSocketStateStream =>
      _controlSocketStateController.stream;
  bool get isConnected => _isConnected;
  String get deviceId => _deviceId ?? '';

  ChatClient({
    required this.host,
    required this.notificationPort,
    required this.controlPort,
    required this.deviceName,
  }) {
    _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> connect() async {
    try {
      // Connect to notification channel
      _notificationSocket = await Socket.connect(host, notificationPort);
      _setupNotificationSocket();
      await _register(_notificationSocket!, isNotification: true);

      // Connect to control channel
      _controlSocket = await Socket.connect(host, controlPort);
      _setupControlSocket();
      await _register(_controlSocket!, isNotification: false);

      _isConnected = true;
      _connectionController.add(true);

      // Start heartbeat after successful connection
      _startHeartbeat();

      log('Connected to server');
    } catch (e) {
      log('Connection failed: $e');
      disconnect();
      rethrow;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _sendHeartbeat();
    });
    // Send first heartbeat immediately
    _sendHeartbeat();
  }

  void _sendHeartbeat() {
    if (_controlSocket == null) {
      _heartbeatTimer?.cancel();
      return;
    }

    try {
      final heartbeat = HeartbeatPigeon(count: _heartbeatCount);
      _sendMessage(_controlSocket!, heartbeat.toJson());
      _heartbeatCount++;

      // Check if we haven't received a response in 30 seconds
      if (_lastHeartbeatResponse != null) {
        final now = DateTime.now();
        if (now.difference(_lastHeartbeatResponse!) >
            const Duration(seconds: 30)) {
          log('No heartbeat response in 30 seconds');
          _handleSocketError(isNotification: false);
        }
      }
    } catch (e) {
      log('Failed to send heartbeat: $e');
      _handleSocketError(isNotification: false);
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _notificationSocket?.destroy();
    _controlSocket?.destroy();
    _notificationSocket = null;
    _controlSocket = null;
    _isConnected = false;
    _isControlSocketResponsive = false;
    _connectionController.add(false);
    _controlSocketStateController.add(false);
    log('Disconnected from server');
  }

  void _setupNotificationSocket() {
    var buffer = <int>[];
    _notificationSocket?.listen(
      (data) {
        buffer.addAll(data);
        while (buffer.length >= 4) {
          final messageLength = ByteData.view(
            Uint8List.fromList(buffer.sublist(0, 4)).buffer,
          ).getInt32(0);
          if (buffer.length >= 4 + messageLength) {
            final messageBytes = buffer.sublist(4, 4 + messageLength);
            final message = utf8.decode(messageBytes);
            final json = jsonDecode(message);
            _handleNotificationMessage(json);
            buffer = buffer.sublist(4 + messageLength);
          } else {
            break;
          }
        }
      },
      onError: (error) {
        log('Notification socket error: $error');
        _handleSocketError(isNotification: true);
      },
      onDone: () {
        log('Notification socket closed');
        _handleSocketClosed(isNotification: true);
      },
      cancelOnError: false,
    );
  }

  void _setupControlSocket() {
    var buffer = <int>[];
    _controlSocket?.listen(
      (data) {
        log('Control socket data: $data');
        buffer.addAll(data);
        while (buffer.length >= 4) {
          final messageLength = ByteData.view(
            Uint8List.fromList(buffer.sublist(0, 4)).buffer,
          ).getInt32(0);
          if (buffer.length >= 4 + messageLength) {
            final messageBytes = buffer.sublist(4, 4 + messageLength);
            final message = utf8.decode(messageBytes);
            final json = jsonDecode(message);
            _handleControlMessage(json);
            buffer = buffer.sublist(4 + messageLength);
          } else {
            break;
          }
        }
      },
      onError: (error) {
        log('Control socket error: $error');
        // _handleSocketError(isNotification: false);
      },
      onDone: () {
        log('Control socket closed');
        // _handleSocketClosed(isNotification: false);
      },
      cancelOnError: false,
    );

    // Add periodic ping to detect server disconnection
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_controlSocket == null) {
        timer.cancel();
        return;
      }

      try {
        // Try to write 1 byte to check connection
        _controlSocket?.add([0]);
      } catch (e) {
        log('Control socket write error: $e');
        _handleSocketError(isNotification: false);
        timer.cancel();
      }
    });
  }

  void _handleSocketError({required bool isNotification}) {
    if (isNotification) {
      _notificationSocket?.destroy();
      _notificationSocket = null;
    } else {
      _controlSocket?.destroy();
      _controlSocket = null;
      _isControlSocketResponsive = false;
      _controlSocketStateController.add(false);
      _heartbeatTimer?.cancel();
    }

    if (_notificationSocket == null || _controlSocket == null) {
      _isConnected = false;
      _connectionController.add(false);

      Future.delayed(const Duration(seconds: 5), () {
        if (!_isConnected) {
          connect().catchError((e) {
            log('Reconnection failed: $e');
          });
        }
      });
    }
  }

  void _handleSocketClosed({required bool isNotification}) {
    if (isNotification) {
      _notificationSocket = null;
    } else {
      _controlSocket = null;
      _isControlSocketResponsive = false;
      _controlSocketStateController.add(false);
      _heartbeatTimer?.cancel();
    }

    if (_notificationSocket == null || _controlSocket == null) {
      _isConnected = false;
      _connectionController.add(false);

      Future.delayed(const Duration(seconds: 5), () {
        if (!_isConnected) {
          connect().catchError((e) {
            log('Reconnection failed: $e');
          });
        }
      });
    }
  }

  Future<void> _register(Socket socket, {required bool isNotification}) async {
    final registration = {'deviceName': deviceName, 'deviceId': deviceId};

    await _sendMessage(socket, registration);
    log('Registered on ${isNotification ? "notification" : "control"} channel');
  }

  Future<void> _sendMessage(Socket socket, dynamic message) async {
    final data = jsonEncode(message);
    final messageBytes = utf8.encode(data);
    final length = messageBytes.length;
    final buffer = ByteData(4 + length);

    // Write length prefix
    buffer.setInt32(0, length, Endian.big);

    // Write message data
    final list = buffer.buffer.asUint8List();
    list.setRange(4, 4 + length, messageBytes);

    socket.add(list);
    await socket.flush();
  }

  void _handleNotificationMessage(Map<String, dynamic> message) {
    if (message.containsKey('message')) {
      _messageController.add(message);
    }
  }

  void _handleControlMessage(Map<String, dynamic> message) {
    // Handle heartbeat response
    if (message.containsKey('count')) {
      _lastHeartbeatResponse = DateTime.now();
      final wasResponsive = _isControlSocketResponsive;
      _isControlSocketResponsive = true;
      if (!wasResponsive) {
        _controlSocketStateController.add(true);
      }
      return;
    }

    // Handle other control messages (directory updates, etc)
    if (message.containsKey('users')) {
      final lst = message['users'] as List<dynamic>;
      _directoryController.add(lst.map((e) => User.fromJson(e)).toList());
    }
  }

  Future<void> sendMessage(String message, String recipientId) async {
    if (!_isConnected) {
      throw Exception('Not connected to server');
    }

    final messageData = {
      'from': {'deviceName': deviceName, 'deviceId': deviceId},
      'to': {'deviceId': recipientId},
      'message': message,
    };

    await _sendMessage(_notificationSocket!, messageData);
    log('Message sent to $recipientId: $message');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _directoryController.close();
    _connectionController.close();
    _controlSocketStateController.close();
  }
}
