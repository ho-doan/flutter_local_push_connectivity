
import 'flutter_local_push_connectivity_platform_interface.dart';

class FlutterLocalPushConnectivity {
  Future<String?> getPlatformVersion() {
    return FlutterLocalPushConnectivityPlatform.instance.getPlatformVersion();
  }
}
