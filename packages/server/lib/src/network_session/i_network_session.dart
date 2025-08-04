import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:flutter_push_common/models/base_model.dart';

enum NetworkSessionState { disconnected, connecting, connected }

abstract class NetworkSessionError extends Error {}

class NotConnectedError extends NetworkSessionError {}

class ConnectionFailedError extends NetworkSessionError {
  final Error error;
  ConnectionFailedError(this.error);
}

class ConnectionCancelledError extends NetworkSessionError {}

abstract class INetworkSession<T> {
  final _stateController = StreamController<NetworkSessionState>.broadcast();
  NetworkSessionState _state = NetworkSessionState.disconnected;

  bool disconnectOnFailure = true;

  final messageController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get messageStream => messageController.stream;

  T? connection;

  INetworkSession() {
    _stateController.add(_state);
  }

  Stream<NetworkSessionState> get stateStream => _stateController.stream;
  NetworkSessionState get state => _state;

  void _setState(NetworkSessionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  void connect(T connection);
  void disconnect();

  Future<void> send(Uint8List message);

  Future<void> request(BaseModel message) async {
    if (message is Heartbeat) {
      log('Heartbeat #${message.count}');
      return;
    }

    if (state != NetworkSessionState.connected) {
      throw StateError('Not connected');
    }

    try {
      String data;
      if (message is User) {
        data = message.toMessage();
      } else if (message is Directory) {
        data = message.toMessage();
      } else if (message is Invite) {
        data = message.toMessage();
      } else if (message is TextMessage) {
        data = message.toMessage();
      } else if (message is Call) {
        data = message.toMessage();
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

      await send(list);
    } catch (e) {
      log('Error encoding message: $e');
      if (disconnectOnFailure) {
        disconnect();
      }
    }
  }

  void dispose() {
    disconnect();
    _stateController.close();
    messageController.close();
  }
}

class TcpNetworkSession<T extends Socket> extends INetworkSession<T> {
  @override
  void connect(T connection) {
    this.connection = connection;
    _setState(NetworkSessionState.connected);

    this.connection!.listen(
      _handleData,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  @override
  void disconnect() {
    connection?.destroy();
    connection = null;
    _setState(NetworkSessionState.disconnected);
  }

  void _handleData(Uint8List data) {
    log('Received data: ${data.length}');
    try {
      if (data.isEmpty) {
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

      BaseModel message;
      if (json.containsKey('deviceName') && json.containsKey('deviceId')) {
        message = User.fromJson(json);
      } else if (json.containsKey('users')) {
        message = Directory.fromJson(json);
      } else if (json.containsKey('message')) {
        if (json.containsKey('action')) {
          message = Call.fromJson(json);
        } else {
          message = TextMessage.fromJson(json);
        }
      } else if (json.containsKey('from') && json.containsKey('to')) {
        message = Invite.fromJson(json);
      } else {
        if (json.containsKey('count')) {
          message = Heartbeat.fromJson(json);
        } else {
          throw const FormatException('Unknown message type');
        }
      }

      log('Received message: $message');

      messageController.add(message);
    } catch (e) {
      log('Error handling data: $e');
      if (disconnectOnFailure) {
        disconnect();
      }
    }
  }

  void _handleError(error) {
    log('Socket error: $error');
    if (disconnectOnFailure) {
      disconnect();
    }
  }

  void _handleDone() {
    disconnect();
  }

  @override
  Future<void> send(Uint8List message) async {
    connection!.add(message);
    await connection!.flush();
  }
}
