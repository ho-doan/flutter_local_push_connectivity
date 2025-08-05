import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:flutter_push_common/models/base_model.dart';

enum NetworkSessionState { disconnected, connecting, connected }

/// R = Socket
abstract class INetworkSession<R> extends ChangeNotifier {
  INetworkSession._({required this.onMessage, required this.client});

  final ValueChanged<(BaseModel, INetworkSession<R>)> onMessage;
  final R client;

  NetworkSessionState _state = NetworkSessionState.disconnected;

  NetworkSessionState get state => _state;

  bool _isDisposed = false;

  set _setState(NetworkSessionState value) {
    _state = value;
    if (!_isDisposed) {
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
    _isDisposed = true;
    disconnect();
    super.dispose();
  }
}

class TcpNetworkSession extends INetworkSession<Socket> {
  TcpNetworkSession({required super.onMessage, required super.client})
    : super._();

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
          throw const FormatException('Unknown message type');
        }
      }

      log('Received message: $message');

      onMessage((message, this));
    } catch (e) {
      log('Error handling data: $e');
    }
  }

  @override
  Future<void> connect() async {
    _setState = NetworkSessionState.connected;
    client.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: false,
    );
  }

  @override
  void disconnect() {
    if (!_isDisposed) {
      _setState = NetworkSessionState.disconnected;
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

enum ChannelType { notification, control }

/// R = Socket
class Connection<R> {
  Connection({required this.session, required this.channelType, this.uuid});

  final INetworkSession<R> session;

  final ChannelType channelType;

  final String? uuid;

  Connection copyWith({
    ValueChanged<BaseModel>? onMessage,
    INetworkSession<R>? session,
    ChannelType? channelType,
    String? uuid,
  }) {
    return Connection(
      session: session ?? this.session,
      channelType: channelType ?? this.channelType,
      uuid: uuid ?? this.uuid,
    );
  }

  void dispose() {
    session.dispose();
  }
}

enum ClientState { connected, disconnected }

/// T = ServerSocket
/// R = Socket
class Client<T, R> extends ChangeNotifier {
  Client({required this.user, required this.onDisconnected});

  final ValueChanged<Client<T, R>> onDisconnected;

  bool _isDisposed = false;

  Connection<R>? _connectionNotification;

  Connection<R>? _connectionControl;

  final User user;

  String get deviceId => user.deviceId;

  String? get deviceName => user.deviceName;

  ClientState _stateNotification = ClientState.disconnected;

  ClientState _stateControl = ClientState.disconnected;

  ClientState get stateNotification => _stateNotification;

  ClientState get stateControl => _stateControl;

  set _setStateNotification(ClientState value) {
    _stateNotification = value;
    notifyListeners();
  }

  set _setStateControl(ClientState value) {
    _stateControl = value;
    // TODO(hodoan): add heartbeat
    notifyListeners();
  }

  void setNotificationConnection(INetworkSession<R> session) {
    final connection = Connection(
      session: session,
      channelType: ChannelType.notification,
      uuid: user.deviceId,
    );
    _connectionNotification = connection;
    _setStateNotification = ClientState.connected;
    _connectionNotification?.session.addListener(_updateStateNotification);
    notifyListeners();
  }

  void setControlConnection(INetworkSession<R> session) {
    final connection = Connection(
      session: session,
      channelType: ChannelType.control,
      uuid: user.deviceId,
    );
    _connectionControl = connection;
    _setStateControl = ClientState.connected;
    _connectionControl?.session.addListener(_updateStateControl);
    notifyListeners();
  }

  void _updateStateNotification() {
    _setStateNotification =
        _connectionNotification?.session.state == NetworkSessionState.connected
            ? ClientState.connected
            : ClientState.disconnected;
    if (stateNotification == ClientState.disconnected) {
      // Prevent recursive calls during notifyListeners
      Future.microtask(() {
        if (!_isDisposed) {
          onDisconnected(this);
        }
      });
    }
  }

  void _updateStateControl() {
    _setStateControl =
        _connectionControl?.session.state == NetworkSessionState.connected
            ? ClientState.connected
            : ClientState.disconnected;
    if (stateControl == ClientState.disconnected) {
      // Prevent recursive dispose calls during notifyListeners
      Future.microtask(() {
        if (!_isDisposed) {
          disconnect();
          onDisconnected(this);
        }
      });
    }
  }

  void disconnect([bool isDisposed = false]) {
    _connectionNotification?.session.removeListener(_updateStateNotification);
    _connectionControl?.session.removeListener(_updateStateControl);
    _connectionNotification?.dispose();
    _connectionControl?.dispose();
    _connectionNotification = null;
    _connectionControl = null;
    if (isDisposed) return;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    disconnect(true);
    super.dispose();
  }
}

class ConnectionPeding<R> extends Connection<R> {
  ConnectionPeding({required super.session, required super.channelType});
}

/// T = ServerSocket
/// R = Socket
abstract class IChannel<T, R> extends ChangeNotifier {
  IChannel({required this.type, required this.port});

  final int port;

  T? _server;

  final ChannelType type;

  final Set<ConnectionPeding<R>> _clientsPending = {};
  final Set<Client<T, R>> _clients = {};

  List<Client<T, R>> get clients => _clients.toList();

  Future<T?> connect();

  Future<void> disconnect();

  Future<void> setupConnection(R client);

  Future<bool> send(TextMessage message) async {
    try {
      final client = _clients.firstWhere(
        (element) => element.user.deviceId == message.to.deviceId,
      );
      if (client._connectionNotification != null) {
        await client._connectionNotification?.session.request(message);
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

class TcpChannel extends IChannel<ServerSocket, Socket> {
  TcpChannel({required super.type, required super.port});

  @override
  Future<ServerSocket?> connect() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _server?.listen(
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
      return _server;
    } catch (e) {
      log('${type.name}: Error: $e');
      return null;
    }
  }

  @override
  Future<void> disconnect() async {
    for (final client in _clients) {
      client.dispose();
    }
    for (final client in _clientsPending) {
      client.session.dispose();
    }
    _clients.clear();
    _clientsPending.clear();
    _server?.close();
    _server = null;
    log('${type.name}: Server stopped');
    notifyListeners();
  }

  @override
  Future<void> setupConnection(Socket client) async {
    log('${type.name}: Client ${client.address.address} connected');
    final session = TcpNetworkSession(client: client, onMessage: _onMessage);

    session.addListener(_onStateChange);
    final peding = ConnectionPeding(channelType: type, session: session);
    _clientsPending.add(peding);
    await session.connect();
    notifyListeners();
  }

  void _onClientConnected(Client<ServerSocket, Socket> client) {
    log('${type.name}: Client ${client.user.deviceId} connected');
    _clients.removeWhere((e) => e.user.deviceId == client.user.deviceId);
    _clients.add(client);
    log('${type.name}: Sending directory to client ${client.user.deviceId}');
    for (final client in _clients) {
      client._connectionControl?.session.request(
        Directory(users: _clients.map((e) => e.user).toList()),
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
        peding = _clientsPending.firstWhere(
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
        _clientsPending.remove(peding);
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
    _clients.removeWhere((e) => e.user.deviceId == value.user.deviceId);

    for (final client in _clients) {
      client._connectionControl?.session.request(
        Directory(users: _clients.map((e) => e.user).toList()),
      );
    }
    notifyListeners();
  }
}

abstract class IServer<T, R> extends ChangeNotifier {
  final int portNotification;
  final int portControl;

  IServer({required this.portNotification, required this.portControl});

  late final TcpChannel _channelNotification;
  late final TcpChannel _channelControl;

  TcpChannel get channelNotification => _channelNotification;
  TcpChannel get channelControl => _channelControl;

  Future<void> start();

  Future<void> stop() async {
    await _channelNotification.disconnect();
    await _channelControl.disconnect();
    _channelNotification.dispose();
    _channelControl.dispose();
    notifyListeners();
  }

  Future<bool> send(TextMessage message) => _channelNotification.send(message);
}

class TcpServer extends IServer<ServerSocket, Socket> {
  TcpServer({required super.portNotification, required super.portControl}) {
    _channelNotification = TcpChannel(
      type: ChannelType.notification,
      port: portNotification,
    );
    _channelControl = TcpChannel(type: ChannelType.control, port: portControl);
  }

  @override
  Future<void> start() async {
    await _channelNotification.connect();
    await _channelControl.connect();
  }
}
