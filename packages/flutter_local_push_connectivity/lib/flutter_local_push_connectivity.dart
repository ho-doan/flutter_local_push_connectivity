import 'flutter_local_push_connectivity_platform_interface.dart';
// export 'package:rxdart/rxdart.dart';

export 'src/managers/setting_manager.dart';
export 'src/managers/call_manager.dart';
export 'src/managers/models/call_manager_state.dart';
export 'src/managers/messaging_manager.dart';
export 'src/managers/control_channel.dart';
export 'src/managers/user_manager.dart';
export 'src/utils/combine_latest.dart';

export 'src/messages.g.dart'
    show
        UserPigeon,
        TextMessagePigeon,
        TerminatedReasonPigeon,
        PushConnectionState,
        UserAvailabilityPigeonEnum,
        UserAvailabilityPigeon,
        CallRolePigeon;

class FlutterLocalPushConnectivity {
  Future<String?> getPlatformVersion() {
    return FlutterLocalPushConnectivityPlatform.instance.getPlatformVersion();
  }
}
