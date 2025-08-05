// dart run pigeon --input pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flutter_push_connectivity',
    dartOut: 'lib/src/messages.g.dart',
    swiftOut:
        'ios/flutter_push_connectivity/Sources/flutter_push_connectivity/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/hodoan/flutter_push_connectivity/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.hodoan.flutter_push_connectivity',
    ),
    // cppHeaderOut: 'windows/Messages.g.h',
    // cppSourceOut: 'windows/Messages.g.cpp',
    // cppOptions: CppOptions(namespace: 'flutter_push_connectivity'),
    // objcHeaderOut:
    //     'macos/flutter_push_connectivity/Sources/flutter_push_connectivity/Messages.g.h',
    // objcSourceOut:
    //     'macos/flutter_push_connectivity/Sources/flutter_push_connectivity/Messages.g.m',
    // objcOptions: ObjcOptions(prefix: 'flutter_push_connectivity'),
    // copyrightHeader: 'pigeons/copyright.txt',
  ),
)
// TODO(hodoan): not supported platform windows yet
@EventChannelApi()
abstract class PushConnectivityEventChannel {
  Object onChanged();
}

@HostApi()
abstract class PushConnectivityHostApi {
  @async
  void initialize(String host, int portNotification, int portControl);

  @async
  void connect();

  @async
  void disconnect();
}
