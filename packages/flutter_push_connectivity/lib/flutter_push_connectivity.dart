import 'src/messages.g.dart';

class FlutterPushConnectivity extends PushConnectivityHostApi {
  FlutterPushConnectivity._()
    : super(messageChannelSuffix: 'flutter_push_connectivity');

  static final FlutterPushConnectivity instance = FlutterPushConnectivity._();
}
