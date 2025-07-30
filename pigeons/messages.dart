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
    cppHeaderOut: 'windows/Messages.g.h',
    cppSourceOut: 'windows/Messages.g.cpp',
    cppOptions: CppOptions(namespace: 'flutter_local_push_connectivity'),
    // copyrightHeader: 'pigeons/copyright.txt',
  ),
)
enum NetworkType {
  wifi,

  /// not support yet
  cellular,
}

enum ConnectType {
  tcp,
  tlsTcp,

  /// not support yet
  udp,

  /// not support yet
  tlsUdp,
  websocket,
  tlsWebsocket,

  /// not support yet
  mqtt,
}

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

class LocalPushConnectivityModel {
  NetworkType networkType;
  ConnectType connectType;
  String? host;
  int? port;

  /// only for [NetworkType.wifi] & Platform.isIOS
  String? ssid;

  LocalPushConnectivityModel({
    required this.networkType,
    required this.connectType,
    this.host,
    this.port,
    this.ssid,
  });
}

@HostApi()
abstract class LocalPushConnectivityHostApi {
  @async
  void initialize(LocalPushConnectivityModel model);

  @async
  void connect(LocalPushConnectivityModel model);

  @async
  void disconnect();

  @async
  void dispose();
}
