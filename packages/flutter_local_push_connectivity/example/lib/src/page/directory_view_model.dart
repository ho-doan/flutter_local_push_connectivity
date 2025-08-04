import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';
import '../utils/logger.dart';

class DirectoryViewModel extends ChangeNotifier {
  final Logger _logger = Logger(
    prependString: 'DirectoryViewModel',
    subsystem: LoggerSubsystem.general,
  );

  PushConnectionState _state = PushConnectionState.connecting;
  List<UserPigeon> _users = [];
  UserPigeon? _connectedUser;

  PushConnectionState get state => _state;
  List<UserPigeon> get users => _users;
  UserPigeon? get connectedUser => _connectedUser;

  DirectoryViewModel() {
    _initialize();
  }
  late final StreamSubscription<PushConnectionState>
  _controlChannelSubscription;
  late final StreamSubscription<List<UserPigeon>> _userManagerSubscription;
  late final StreamSubscription<CallManagerState> _callManagerSubscription;

  void _initialize() {
    _controlChannelSubscription = ControlChannel.shared.connectionState.listen((
      state,
    ) {
      _logger.log('ControlChannel state changed: $state');
      _updateState();
    });

    _userManagerSubscription = UserManager.shared.users.listen((users) {
      _users = users;
      _updateState();
    });

    _callManagerSubscription = CallManager.shared.state.listen((state) {
      _logger.log('CallManager state changed: $state');
      switch (state) {
        case DisconnectedCallManagerState():
          setConnectedUser(null);
        case ConnectingCallManagerState(:final user):
          setConnectedUser(user);
        case ConnectedCallManagerState(:final user):
          setConnectedUser(user);
        case DisconnectingCallManagerState():
          setConnectedUser(null);
        case _:
          setConnectedUser(null);
      }
    });
  }

  void _updateState() {
    if (_users.isEmpty) {
      _state = PushConnectionState.waitingForUsers;
    } else {
      _state = PushConnectionState.connected;
    }
  }

  void updateState(PushConnectionState newState) {
    _state = newState;
    notifyListeners();
  }

  void updateUsers(List<UserPigeon> newUsers) {
    _users = newUsers;
    _updateState();
    notifyListeners();
  }

  void setConnectedUser(UserPigeon? user) {
    _connectedUser = user;
    notifyListeners();
  }

  NetworkConfigurationMode get networkConfigurationMode {
    // TODO(hodoan): check if not working, use SettingsManager.shared.settingsStream instead
    final settings = SettingsManager.shared.settings;
    final isConnectedToWiFi = settings.pushManagerSettings.ssid.isNotEmpty;
    final isConnectedToCellular =
        settings.pushManagerSettings.mobileCountryCode.isNotEmpty &&
        settings.pushManagerSettings.mobileNetworkCode.isNotEmpty;
    if (isConnectedToWiFi && isConnectedToCellular) {
      return NetworkConfigurationMode.both;
    } else if (isConnectedToWiFi) {
      return NetworkConfigurationMode.wifi;
    } else if (isConnectedToCellular) {
      return NetworkConfigurationMode.cellular;
    } else {
      return NetworkConfigurationMode.ethernet;
    }
  }

  @override
  void dispose() {
    _controlChannelSubscription.cancel();
    _userManagerSubscription.cancel();
    _callManagerSubscription.cancel();
    super.dispose();
  }
}

enum NetworkConfigurationMode { wifi, cellular, ethernet, both }

extension DirectoryStateExtension on PushConnectionState {
  String displayName(NetworkConfigurationMode networkConfigurationMode) {
    switch (this) {
      case PushConnectionState.configurationNeeded:
        return 'Configure Server and Local Push Connectivity in Settings';
      case PushConnectionState.waitingForActivePushManager:
        final uuid = SettingsManager.shared.settings.uuid;
        return switch (networkConfigurationMode) {
          NetworkConfigurationMode.wifi => 'Connect to $uuid',
          NetworkConfigurationMode.cellular =>
            'Connect to the configured cellular network',
          NetworkConfigurationMode.ethernet => 'Connect to the Ethernet cable',
          NetworkConfigurationMode.both =>
            'Connect to $uuid or the configured cellular network',
        };
      case PushConnectionState.connecting:
        return 'Connecting';
      case PushConnectionState.connected:
        return 'Connected';
      case PushConnectionState.waitingForUsers:
        return 'Waiting for contacts';
    }
  }

  IconData get icon {
    switch (this) {
      case PushConnectionState.configurationNeeded:
        return Icons.build;
      case PushConnectionState.waitingForActivePushManager:
        return Icons.warning;
      case PushConnectionState.connecting:
      case PushConnectionState.connected:
        return Icons.bolt;
      case PushConnectionState.waitingForUsers:
        return Icons.person_off;
    }
  }
}
