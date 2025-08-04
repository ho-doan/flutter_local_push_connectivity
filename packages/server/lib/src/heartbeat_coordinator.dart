import 'dart:async';
import 'dart:developer';

import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:server/src/errors.dart';

import 'network_session/i_network_session.dart';

enum HeartbeatStartMode { now, afterInterval }

class HeartbeatCoordinator<T> {
  final Duration interval;
  Timer? _timer;
  bool _isSessionResponsive = false;
  INetworkSession<T>? _session;
  final _isSessionResponsiveController = StreamController<bool>.broadcast();
  int _heartbeatCount = 1;
  bool _isRunning = false;

  HeartbeatCoordinator({required this.interval});

  Stream<bool> get isSessionResponsiveStream =>
      _isSessionResponsiveController.stream;
  bool get isSessionResponsive => _isSessionResponsive;
  bool get isRunning => _isRunning;

  set session(INetworkSession<T> session) {
    _session = session;
  }

  void start({HeartbeatStartMode mode = HeartbeatStartMode.now}) {
    if (_isRunning) {
      throw HeartbeatError.alreadyRunning();
    }

    if (_session == null) {
      throw SessionError.missingSession();
    }

    log('Starting heartbeat coordinator');
    _isRunning = true;

    if (mode == HeartbeatStartMode.now) {
      _sendHeartbeat();
    }

    _timer = Timer.periodic(interval, (timer) {
      _sendHeartbeat();
    });
  }

  void stop() {
    log('Stopping heartbeat coordinator');
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _setSessionResponsive(false);
  }

  void _sendHeartbeat() {
    final session = _session;
    if (session == null) {
      log('No session set for HeartbeatCoordinator');
      stop();
      throw SessionError.missingSession();
    }

    log('Sending heartbeat #$_heartbeatCount');

    session
        .request(Heartbeat(count: _heartbeatCount))
        .then((_) {
          _heartbeatCount++;
          _setSessionResponsive(true);
          log('Heartbeat successful');
        })
        .catchError((error) {
          log('Heartbeat failed: $error');
          _setSessionResponsive(false);
          if (_isRunning) {
            stop();
          }
        });
  }

  void _setSessionResponsive(bool value) {
    if (_isSessionResponsive != value) {
      _isSessionResponsive = value;
      _isSessionResponsiveController.add(value);
    }
  }

  void dispose() {
    stop();
    _isSessionResponsiveController.close();
  }
}
