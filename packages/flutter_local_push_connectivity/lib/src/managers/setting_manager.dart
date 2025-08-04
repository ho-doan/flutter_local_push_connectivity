import 'dart:async';

import 'package:flutter_local_push_connectivity/src/messages.g.dart';

class SettingsManager extends SettingsManagerHostApi {
  static final SettingsManager shared = SettingsManager._internal();

  SettingsManager._internal()
    : super(messageChannelSuffix: 'settings_manager') {
    _settingsSubscription = settingsStream.listen((settings) {
      _settings = settings;
    });
  }

  Stream<SettingsPigeon> get settingsStream =>
      onChanged(
        instanceName: 'settings_manager_settings',
      ).map((e) => e as SettingsPigeon).asBroadcastStream();

  late final StreamSubscription<SettingsPigeon> _settingsSubscription;

  SettingsPigeon _settings = SettingsPigeon(
    uuid: '',
    deviceName: '',
    pushManagerSettings: PushManagerSettingsPigeon(
      ssid: '',
      mobileCountryCode: '',
      mobileNetworkCode: '',
      trackingAreaCode: '',
      host: '',
      matchEthernet: true,
    ),
  );

  SettingsPigeon get settings => _settings;

  void dispose() {
    _settingsSubscription.cancel();
  }
}
