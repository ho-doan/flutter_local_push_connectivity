import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:flutter_push_common/models/base_model.dart';

enum NetworkSessionState { disconnected, connecting, connected }

/// R = Socket
abstract class INetworkSession<R> extends ChangeNotifier {
  INetworkSession({required this.onMessage, required this.client});

  final ValueChanged<(BaseModel, INetworkSession<R>)> onMessage;
  final R client;

  NetworkSessionState _state = NetworkSessionState.disconnected;

  NetworkSessionState get state => _state;

  bool isDisposed = false;

  set setState(NetworkSessionState value) {
    _state = value;
    if (!isDisposed) {
      notifyListeners();
    }
  }

  Future<void> connect();

  void disconnect();

  Future<void> send(Uint8List message);

  Future<void> request(BaseModel message) async {
    if (message is Heartbeat) {
      log('Heartbeat #${message.count}');
      return;
    } else {
      log('Request: ${message.toMessage()}');
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
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    disconnect();
    super.dispose();
  }
}
