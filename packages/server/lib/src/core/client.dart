import 'package:flutter/widgets.dart';
import 'package:flutter_push_common/flutter_push_common.dart';

import 'network_session/connection.dart';
import 'network_session/i_network_session.dart';

enum ClientState { connected, disconnected }

/// T = ServerSocket
/// R = Socket
class Client<T, R> extends ChangeNotifier {
  Client({required this.user, required this.onDisconnected});

  final ValueChanged<Client<T, R>> onDisconnected;

  bool _isDisposed = false;

  Connection<R>? _connectionNotification;

  Connection<R>? _connectionControl;

  Connection<R>? get connectionNotification => _connectionNotification;
  Connection<R>? get connectionControl => _connectionControl;

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
