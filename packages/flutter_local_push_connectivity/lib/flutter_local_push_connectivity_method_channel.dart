import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_local_push_connectivity_platform_interface.dart';

/// An implementation of [FlutterLocalPushConnectivityPlatform] that uses method channels.
class MethodChannelFlutterLocalPushConnectivity extends FlutterLocalPushConnectivityPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_local_push_connectivity');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
