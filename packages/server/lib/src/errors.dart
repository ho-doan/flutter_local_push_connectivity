class NetworkError implements Exception {
  final String message;
  NetworkError(this.message);

  @override
  String toString() => message;
}

class SessionError extends NetworkError {
  SessionError(String message) : super(message);

  static SessionError missingSession() {
    return SessionError('Session not set');
  }

  static SessionError invalidSession() {
    return SessionError('Invalid session type');
  }
}

class HeartbeatError extends NetworkError {
  HeartbeatError(String message) : super(message);

  static HeartbeatError coordinatorNotFound() {
    return HeartbeatError('Heartbeat coordinator not found');
  }

  static HeartbeatError alreadyRunning() {
    return HeartbeatError('Heartbeat coordinator already running');
  }
}
