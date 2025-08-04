import '../messages.g.dart';

class ControlChannel extends ControlChannelHostApi {
  static final ControlChannel shared = ControlChannel._internal();

  ControlChannel._internal() : super(messageChannelSuffix: 'control_channel');

  Stream<PushConnectionState> get connectionState =>
      onChanged(
        instanceName: 'control_channel_connection_state',
      ).map((e) => e as PushConnectionState).asBroadcastStream();
}
