import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../flutter_local_push_connectivity.dart';
import '../messages.g.dart';

class CallManager extends CallManagerHostApi {
  final _methodChannel = MethodChannel('call_manager_channel');
  static final CallManager shared = CallManager._internal();

  CallManager._internal() : super(messageChannelSuffix: 'call_manager') {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'updateActionsButtonsForConnectedUser':
          updateActionsButtonsForConnectedUser(call.arguments as bool);
          break;
        case 'updateHelpText':
          updateHelpText(call.arguments as String);
          break;
        case 'setUser':
          final json = jsonDecode(call.arguments as String);
          updateUser(
            UserPigeon(uuid: json['uuid'], deviceName: json['deviceName']),
          );
          break;
      }
    });
  }

  Stream<CallRolePigeon> get callRolePublisher =>
      onChanged(
        instanceName: 'call_manager_call_role',
      ).map((e) => CallRolePigeon.values[e as int]).asBroadcastStream();

  Stream<CallManagerState> get state =>
      onChanged(instanceName: 'call_manager_state')
          .map((e) => CallManagerState.fromPigeon(e as CallManagerStatePigeon))
          .asBroadcastStream();

  Stream<CallManagerState> get callState =>
      onChanged(instanceName: 'call_manager_call_state')
          .map((e) => CallManagerState.fromPigeon(e as CallManagerStatePigeon))
          .asBroadcastStream();

  final user = ValueNotifier<UserPigeon?>(null);
  final disableCallActions = ValueNotifier<bool>(false);

  final userAvailability = ValueNotifier<UserAvailabilityPigeonEnum>(
    UserAvailabilityPigeonEnum.available,
  );

  final helpText = ValueNotifier<String>('Start call');

  void updateUser(UserPigeon? user) {
    this.user.value = user;
  }

  void updateActionsButtonsForConnectedUser(bool disable) {
    log('updateActionsButtonsForConnectedUser: $disable');
    disableCallActions.value = disable;
  }

  void updateHelpText(String text) {
    log('updateHelpText: $text');
    helpText.value = text;
  }

  StreamSubscription? _userAvailabilitySubscription;

  void dispose() {
    _userAvailabilitySubscription?.cancel();
  }

  @override
  Future<void> setUser(UserPigeon user) {
    if (this.user.value?.uuid != user.uuid) {
      this.user.value = user;
      _userAvailabilitySubscription = UserManager.shared
          .userAvailabilityPublisher(user)
          .listen((e) {
            setUser(e.user);
            setUserAvailability(e.availability);
            updateActionsButtonsForConnectedUser(
              e.availability == UserAvailabilityPigeonEnum.unavailable,
            );
          });
    }
    return super.setUser(user);
  }
}
