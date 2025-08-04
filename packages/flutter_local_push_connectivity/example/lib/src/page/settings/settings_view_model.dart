import 'package:flutter/material.dart';
import '../../utils/logger.dart';

enum SettingsGroup { cellular, wifi }

class PushManagerSettings {
  String ssid;
  String mobileCountryCode;
  String mobileNetworkCode;
  String trackingAreaCode;
  String host;
  bool matchEthernet;

  PushManagerSettings({
    this.ssid = '',
    this.mobileCountryCode = '',
    this.mobileNetworkCode = '',
    this.trackingAreaCode = '',
    this.host = '',
    this.matchEthernet = false,
  });
}

class Settings {
  String uuid;
  String deviceName;
  PushManagerSettings pushManagerSettings;

  Settings({
    required this.uuid,
    required this.deviceName,
    required this.pushManagerSettings,
  });
}

class SettingsViewModel extends ChangeNotifier {
  final Logger _logger = Logger(
    prependString: 'SettingsViewModel',
    subsystem: LoggerSubsystem.general,
  );

  Settings _settings;
  bool _isAppPushManagerActive = false;
  bool _isCellularSettingsViewActive = false;
  bool _isWiFiSettingsViewActive = false;
  bool _matchEthernet = false;

  Settings get settings => _settings;
  bool get isAppPushManagerActive => _isAppPushManagerActive;
  bool get isCellularSettingsViewActive => _isCellularSettingsViewActive;
  bool get isWiFiSettingsViewActive => _isWiFiSettingsViewActive;
  bool get matchEthernet => _matchEthernet;

  set matchEthernet(bool value) {
    _matchEthernet = value;
    _settings.pushManagerSettings.matchEthernet = value;
    commit();
    notifyListeners();
  }

  SettingsViewModel()
    : _settings = Settings(
        uuid: 'default-uuid',
        deviceName: 'Default Device',
        pushManagerSettings: PushManagerSettings(),
      ) {
    _initialize();
  }

  void _initialize() {
    _matchEthernet = _settings.pushManagerSettings.matchEthernet;

    // TODO: Listen to SettingsManager.settingsPublisher
    // TODO: Listen to PushConfigurationManager.pushManagerIsActivePublisher
    // TODO: Set up proper settings state management
    // TODO: Load settings from persistent storage
  }

  void commit() {
    try {
      _logger.log('Saving updated settings');
      // TODO: Call SettingsManager.set(settings: settings)
      // TODO: Implement proper settings persistence
      // TODO: Handle settings validation
      // TODO: Handle settings save errors
    } catch (e) {
      _logger.log('Saving to settings failed with error: $e');
    }
  }

  void reset(SettingsGroup group) {
    switch (group) {
      case SettingsGroup.cellular:
        _settings.pushManagerSettings.mobileCountryCode = '';
        _settings.pushManagerSettings.mobileNetworkCode = '';
        _settings.pushManagerSettings.trackingAreaCode = '';
        break;
      case SettingsGroup.wifi:
        _settings.pushManagerSettings.ssid = '';
        break;
    }
    // TODO: Commit changes after reset
    notifyListeners();
  }

  void setMatchEthernet(bool value) {
    _matchEthernet = value;
    _settings.pushManagerSettings.matchEthernet = value;
    commit();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
