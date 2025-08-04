// dart run pigeon --input pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flutter_local_push_connectivity',
    dartOut: 'lib/src/messages.g.dart',
    swiftOut:
        'ios/flutter_local_push_connectivity/Sources/flutter_local_push_connectivity/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/hodoan/flutter_local_push_connectivity/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.hodoan.flutter_local_push_connectivity',
    ),
    // cppHeaderOut: 'windows/Messages.g.h',
    // cppSourceOut: 'windows/Messages.g.cpp',
    // cppOptions: CppOptions(namespace: 'flutter_local_push_connectivity'),
    // copyrightHeader: 'pigeons/copyright.txt',
  ),
)
// TODO(hodoan): not supported platform windows yet
@EventChannelApi()
abstract class LocalPushConnectivityEventChannel {
  Object onChanged();
}

enum TerminatedReasonPigeon { hungUp, callFailed, unavailable }

class UserPigeon {
  String uuid;
  String deviceName;

  UserPigeon({required this.uuid, required this.deviceName});
}

class TextMessagePigeon {
  UserPigeon sender;
  UserPigeon receiver;
  String message;

  TextMessagePigeon({
    required this.sender,
    required this.receiver,
    required this.message,
  });
}

enum CallManagerStatePigeonEnum {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

enum PushConnectionState {
  configurationNeeded,
  waitingForActivePushManager,
  connecting,
  connected,
  waitingForUsers,
}

enum UserAvailabilityPigeonEnum { available, unavailable }

class UserAvailabilityPigeon {
  UserAvailabilityPigeonEnum availability;
  UserPigeon user;

  UserAvailabilityPigeon({required this.availability, required this.user});
}

enum NetworkConfigurationMode { wifi, cellular, ethernet, both }

class PushManagerSettingsPigeon {
  String ssid;
  String mobileCountryCode;
  String mobileNetworkCode;
  String trackingAreaCode;
  String host;
  bool matchEthernet;

  PushManagerSettingsPigeon({
    required this.ssid,
    required this.mobileCountryCode,
    required this.mobileNetworkCode,
    required this.trackingAreaCode,
    required this.host,
    required this.matchEthernet,
  });
}

class SettingsPigeon {
  String uuid;
  String deviceName;
  PushManagerSettingsPigeon pushManagerSettings;

  SettingsPigeon({
    required this.uuid,
    required this.deviceName,
    required this.pushManagerSettings,
  });
}

class CallManagerStatePigeon {
  CallManagerStatePigeonEnum state;
  UserPigeon? user;
  TerminatedReasonPigeon? terminatedReason;

  CallManagerStatePigeon({
    required this.state,
    this.user,
    this.terminatedReason,
  });
}

@HostApi()
abstract class CallManagerHostApi {
  @async
  void setUser(UserPigeon user);

  @async
  void setUserAvailability(UserAvailabilityPigeonEnum availability);
}

enum CallRolePigeon { sender, receiver }

@HostApi()
abstract class MessagingManagerHostApi {}

@HostApi()
abstract class ControlChannelHostApi {}

@HostApi()
abstract class UserManagerHostApi {}

@HostApi()
abstract class SettingsManagerHostApi {}

@HostApi()
abstract class LocalPushConnectivityHostApi {
  // @async
  // void initialize(LocalPushConnectivityModel model);

  // @async
  // void connect(LocalPushConnectivityModel model);

  @async
  void disconnect();

  @async
  void dispose();
}
