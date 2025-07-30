import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity_platform_interface.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterLocalPushConnectivityPlatform
    with MockPlatformInterfaceMixin
    implements FlutterLocalPushConnectivityPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterLocalPushConnectivityPlatform initialPlatform = FlutterLocalPushConnectivityPlatform.instance;

  test('$MethodChannelFlutterLocalPushConnectivity is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterLocalPushConnectivity>());
  });

  test('getPlatformVersion', () async {
    FlutterLocalPushConnectivity flutterLocalPushConnectivityPlugin = FlutterLocalPushConnectivity();
    MockFlutterLocalPushConnectivityPlatform fakePlatform = MockFlutterLocalPushConnectivityPlatform();
    FlutterLocalPushConnectivityPlatform.instance = fakePlatform;

    expect(await flutterLocalPushConnectivityPlugin.getPlatformVersion(), '42');
  });
}
