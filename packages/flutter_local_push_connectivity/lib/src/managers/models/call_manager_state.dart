import '../../messages.g.dart';

abstract class CallManagerState {
  const CallManagerState._();

  factory CallManagerState.fromPigeon(CallManagerStatePigeon pigeon) {
    return switch (pigeon.state) {
      CallManagerStatePigeonEnum.disconnected => DisconnectedCallManagerState(),
      CallManagerStatePigeonEnum.connecting => ConnectingCallManagerState(
        user: pigeon.user!,
      ),
      CallManagerStatePigeonEnum.connected => ConnectedCallManagerState(
        user: pigeon.user!,
      ),
      CallManagerStatePigeonEnum.disconnecting => DisconnectingCallManagerState(
        terminatedReason: pigeon.terminatedReason!,
      ),
    };
  }
}

class DisconnectedCallManagerState extends CallManagerState {
  const DisconnectedCallManagerState() : super._();
}

class ConnectingCallManagerState extends CallManagerState {
  const ConnectingCallManagerState({required this.user}) : super._();

  final UserPigeon user;
}

class ConnectedCallManagerState extends CallManagerState {
  const ConnectedCallManagerState({required this.user}) : super._();

  final UserPigeon user;
}

class DisconnectingCallManagerState extends CallManagerState {
  const DisconnectingCallManagerState({required this.terminatedReason})
    : super._();

  final TerminatedReasonPigeon terminatedReason;
}
