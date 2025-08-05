import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_push_common/flutter_push_common.dart';

import '../client.dart';
import '../network_session/connection.dart';

/// T = ServerSocket
/// R = Socket
abstract class IChannel<T, R> extends ChangeNotifier {
  IChannel({required this.type, required this.port});

  final int port;

  T? server;

  final ChannelType type;

  final Set<ConnectionPeding<R>> clientsPending = {};
  final Set<Client<T, R>> clients = {};

  List<Client<T, R>> get clientLst => clients.toList();

  Future<T?> connect();

  Future<void> disconnect();

  Future<void> setupConnection(R client);

  Future<bool> send(TextMessage message) async {
    try {
      final client = clients.firstWhere(
        (element) => element.user.deviceId == message.to.deviceId,
      );
      if (client.connectionNotification != null) {
        await client.connectionNotification?.session.request(message);
      } else {
        throw StateError('No notification connection found');
      }
      return true;
    } catch (e) {
      log('Error sending message: $e');
      return false;
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
