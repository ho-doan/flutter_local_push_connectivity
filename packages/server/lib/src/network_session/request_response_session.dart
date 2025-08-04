import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:server/src/heartbeat_coordinator.dart';
import 'package:server/src/messages.g.dart';
import 'package:server/src/models/message_wrapper.dart';

import 'i_network_session.dart';

class RequestResponseSession extends INetworkSession {
  final _stateController = StreamController<NetworkSessionState>.broadcast();
  final _messageController = StreamController<dynamic>.broadcast();

  Socket? _socket;
  NetworkSessionState _state = NetworkSessionState.disconnected;
  bool _disconnectOnFailure = true;

  @override
  Stream<NetworkSessionState> get stateStream => _stateController.stream;

  @override
  NetworkSessionState get state => _state;

  Stream<dynamic> get messageStream => _messageController.stream;

  // bool get disconnectOnFailure => _disconnectOnFailure;
  set disconnectOnFailure(bool value) => _disconnectOnFailure = value;

  @override
  void connect(dynamic connection) {
    if (connection is! Socket) {
      throw ArgumentError('Connection must be a Socket');
    }

    _socket = connection;
    _setState(NetworkSessionState.connected);

    _socket!.listen(
      _handleData,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  @override
  void disconnect() {
    _socket?.destroy();
    _socket = null;
    _setState(NetworkSessionState.disconnected);
  }

  Future<void> request(dynamic message) async {
    if (message is HeartbeatPigeon) {
      return;
    }

    if (_state != NetworkSessionState.connected) {
      throw StateError('Not connected');
    }

    try {
      String data;
      if (message is UserPigeon) {
        data = jsonEncode(message.toJson());
      } else if (message is DirectoryPigeon) {
        data = jsonEncode(message.toJson());
      } else if (message is InvitePigeon) {
        data = jsonEncode(message.toJson());
      } else if (message is TextMessagePigeon) {
        data = jsonEncode(message.toJson());
      } else if (message is CallActionPigeon) {
        data = jsonEncode(message.toJson());
      } else {
        data = jsonEncode(message);
      }

      final length = data.length;
      final buffer = ByteData(4 + length);

      // Write length prefix
      buffer.setInt32(0, length, Endian.big);

      // Write message data
      final messageBytes = utf8.encode(data);
      final list = buffer.buffer.asUint8List();
      list.setRange(4, 4 + length, messageBytes);

      _socket!.add(list);
      await _socket!.flush();
    } catch (e) {
      log('Error sending message: $e');
      if (_disconnectOnFailure) {
        disconnect();
      }
      rethrow;
    }
  }

  void _setState(NetworkSessionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  void _handleData(Uint8List data) {
    try {
      if (data.length < 4) {
        throw const FormatException('Message too short');
      }

      final buffer = ByteData.view(data.buffer);
      final length = buffer.getInt32(0, Endian.big);

      if (data.length < 4 + length) {
        throw const FormatException('Incomplete message');
      }

      final messageBytes = data.sublist(4, 4 + length);
      final messageStr = utf8.decode(messageBytes);
      final json = jsonDecode(messageStr) as Map<String, dynamic>;

      dynamic message;
      if (json.containsKey('deviceName') && json.containsKey('deviceId')) {
        message = UserPigeonJson.fromJson(json);
      } else if (json.containsKey('users')) {
        message = DirectoryPigeonJson.fromJson(json);
      } else if (json.containsKey('message')) {
        if (json.containsKey('action')) {
          message = CallActionPigeonJson.fromJson(json);
        } else {
          message = TextMessagePigeonJson.fromJson(json);
        }
      } else if (json.containsKey('from') && json.containsKey('to')) {
        message = InvitePigeonJson.fromJson(json);
      } else {
        message = json;
      }

      _messageController.add(message);
    } catch (e) {
      log('Error handling data: $e');
      if (_disconnectOnFailure) {
        disconnect();
      }
    }
  }

  void _handleError(error) {
    log('Socket error: $error');
    if (_disconnectOnFailure) {
      disconnect();
    }
  }

  void _handleDone() {
    disconnect();
  }

  @override
  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
    super.dispose();
  }
}
