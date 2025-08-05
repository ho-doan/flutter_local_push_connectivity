import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:flutter_push_common/models/base_model.dart';

import 'i_network_session.dart';

class TcpNetworkSession extends INetworkSession<Socket> {
  TcpNetworkSession({required super.onMessage, required super.client});

  void _handleMessage(Uint8List data) {
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
          throw FormatException('Unknown message type: $json');
        }
      }

      log('Received message: ${message.toMessage()}');

      onMessage((message, this));
    } catch (e) {
      log('Error handling data: $e');
    }
  }

  @override
  Future<void> connect() async {
    setState = NetworkSessionState.connected;
    client.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  @override
  void disconnect() {
    if (!isDisposed) {
      setState = NetworkSessionState.disconnected;
    }
    client.destroy();
    client.close();
  }

  @override
  Future<void> send(Uint8List message) async {
    try {
      client.add(message);
      await client.flush();
      log('Sent message successfully');
    } catch (e) {
      log('Error sending message: $e');
    }
  }

  _handleError(Object err) {
    log('Error: $err');
    disconnect();
  }

  _handleDone() {
    log('Done');
    disconnect();
  }
}
