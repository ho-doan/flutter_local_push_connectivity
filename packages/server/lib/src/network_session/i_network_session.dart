import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';

enum NetworkSessionState { disconnected, connecting, connected }

abstract class NetworkSessionError extends Error {}

class NotConnectedError extends NetworkSessionError {}

class ConnectionFailedError extends NetworkSessionError {
  final Error error;
  ConnectionFailedError(this.error);
}

class ConnectionCancelledError extends NetworkSessionError {}

abstract class INetworkSession {
  final _stateController = StreamController<NetworkSessionState>.broadcast();
  NetworkSessionState _state = NetworkSessionState.disconnected;

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

  void connect(dynamic connection);
  void disconnect();

  void dispose() {
    _stateController.close();
  }
}

class TcpNetworkSession extends INetworkSession {
  Socket? _socket;

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

  void _handleData(List<int> data) {
    // Override in subclasses to handle data
  }

  void _handleError(error) {
    log('Socket error: $error');
    disconnect();
  }

  void _handleDone() {
    disconnect();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
