import 'dart:developer';
import 'dart:io';

import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:flutter_push_common/models/base_model.dart';

import '../client.dart';
import '../network_session/connection.dart';
import '../network_session/i_network_session.dart';
import '../network_session/tcp_network_session.dart';
import 'i_channel.dart';

class TcpChannel extends IChannel<ServerSocket, Socket> {
  TcpChannel({required super.type, required super.port});

  @override
  Future<ServerSocket?> connect() async {
    try {
      server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      server?.listen(
        (client) {
          setupConnection(client);
        },
        onError: (error) {
          log('TcpChannel: Error: $error');
        },
        onDone: () {
          log('TcpChannel: Done');
        },
        cancelOnError: false,
      );
      notifyListeners();
      log('${type.name}: Server listening on port $port');
      return server;
    } catch (e) {
      log('${type.name}: Error: $e');
      return null;
    }
  }

  @override
  Future<void> disconnect() async {
    for (final client in clients) {
      client.dispose();
    }
    for (final client in clientsPending) {
      client.session.dispose();
    }
    clients.clear();
    clientsPending.clear();
    server?.close();
    server = null;
    log('${type.name}: Server stopped');
    notifyListeners();
  }

  @override
  Future<void> setupConnection(Socket client) async {
    log('${type.name}: Client ${client.address.address} connected');
    final session = TcpNetworkSession(client: client, onMessage: _onMessage);

    session.addListener(_onStateChange);
    final peding = ConnectionPeding(channelType: type, session: session);
    clientsPending.add(peding);
    await session.connect();
    notifyListeners();
  }

  void _onClientConnected(Client<ServerSocket, Socket> client) {
    log('${type.name}: Client ${client.user.deviceId} connected');
    clients.removeWhere((e) => e.user.deviceId == client.user.deviceId);
    clients.add(client);
    log('${type.name}: Sending directory to client ${client.user.deviceId}');
    for (final client in clients) {
      client.connectionControl?.session.request(
        Directory(users: clients.map((e) => e.user).toList()),
      );
    }
    notifyListeners();
  }

  _onMessage((BaseModel, INetworkSession<Socket>) message) {
    log('${type.name}: Received message: ${message.$1.toMessage()}');
    if (message.$1 is User) {
      final connection = message.$2;
      ConnectionPeding<Socket>? peding;
      try {
        peding = clientsPending.firstWhere(
          (element) => element.session == connection,
          orElse: () => throw StateError('Connection not found'),
        );
      } catch (e) {
        log('no peding connection found');
      }
      if (peding != null) {
        final client = Client<ServerSocket, Socket>(
          user: message.$1 as User,
          onDisconnected: _onClientDisconnected,
        );
        if (peding.channelType == ChannelType.notification) {
          client.setNotificationConnection(peding.session);
        } else {
          client.setControlConnection(peding.session);
        }
        _onClientConnected(client);
        clientsPending.remove(peding);
        notifyListeners();
      }
      return;
    }
    log('Unknown message: ${message.$1.toMessage()}');
  }

  void _onStateChange() {
    log('${type.name}: State changed');
    notifyListeners();
  }

  void _onClientDisconnected(Client<ServerSocket, Socket> value) {
    log('${type.name}: Client ${value.user.deviceId} disconnected');
    clients.removeWhere((e) => e.user.deviceId == value.user.deviceId);

    for (final client in clients) {
      client.connectionControl?.session.request(
        Directory(users: clients.map((e) => e.user).toList()),
      );
    }
    notifyListeners();
  }
}
