import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_local_push_connectivity_method_channel.dart';

abstract class FlutterLocalPushConnectivityPlatform extends PlatformInterface {
  /// Constructs a FlutterLocalPushConnectivityPlatform.
  FlutterLocalPushConnectivityPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLocalPushConnectivityPlatform _instance = MethodChannelFlutterLocalPushConnectivity();

  /// The default instance of [FlutterLocalPushConnectivityPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterLocalPushConnectivity].
  static FlutterLocalPushConnectivityPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterLocalPushConnectivityPlatform] when
  /// they register themselves.
  static set instance(FlutterLocalPushConnectivityPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
