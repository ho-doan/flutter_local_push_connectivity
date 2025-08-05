// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_push_connectivity/flutter_push_connectivity.dart';
// import 'package:flutter_push_connectivity/flutter_push_connectivity_platform_interface.dart';
// import 'package:flutter_push_connectivity/flutter_push_connectivity_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockFlutterPushConnectivityPlatform
//     with MockPlatformInterfaceMixin
//     implements FlutterPushConnectivityPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final FlutterPushConnectivityPlatform initialPlatform = FlutterPushConnectivityPlatform.instance;

//   test('$MethodChannelFlutterPushConnectivity is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelFlutterPushConnectivity>());
//   });

//   test('getPlatformVersion', () async {
//     FlutterPushConnectivity flutterPushConnectivityPlugin = FlutterPushConnectivity();
//     MockFlutterPushConnectivityPlatform fakePlatform = MockFlutterPushConnectivityPlatform();
//     FlutterPushConnectivityPlatform.instance = fakePlatform;

//     expect(await flutterPushConnectivityPlugin.getPlatformVersion(), '42');
//   });
// }
