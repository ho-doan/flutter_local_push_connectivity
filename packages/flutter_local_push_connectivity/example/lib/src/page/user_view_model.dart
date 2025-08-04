import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';
import '../utils/logger.dart';

class UserViewModel extends ChangeNotifier {
  final Logger _logger = Logger(
    prependString: 'UserViewModel',
    subsystem: LoggerSubsystem.general,
  );

  UserPigeon _user;
  CallManagerState _callState = DisconnectedCallManagerState();
  bool _disableCallActions = false;
  String _helpText = 'Start call';

  final helpText = CallManager.shared.helpText;
  bool _showMessagingView = false;

  UserPigeon get user => _user;
  final userAvailability = CallManager.shared.userAvailability;
  CallManagerState get callState => _callState;
  final disableCallActions = CallManager.shared.disableCallActions;
  bool get showMessagingView => _showMessagingView;

  UserViewModel({required UserPigeon user}) : _user = user {
    _initialize();
  }

  late final StreamSubscription<CallManagerState> _callStateSubscription;
  late final StreamSubscription<UserAvailabilityPigeon>
  _userAvailabilitySubscription;

  @override
  void dispose() {
    _callStateSubscription.cancel();
    _userAvailabilitySubscription.cancel();
    super.dispose();
  }

  void _initialize() {
    combineLatest(
      CallManager.shared.state.map((state) {
        UserPigeon? connectedUser;
        switch (state) {
          case ConnectingCallManagerState():
            connectedUser = state.user;
            break;
          case ConnectedCallManagerState():
            connectedUser = state.user;
        }

        if (connectedUser != null && connectedUser.uuid == user.uuid) {
          return DisconnectedCallManagerState();
        }

        return state;
      }).pairwiseAndFirst(),

      CallManager.shared.callRolePublisher,
      (callState, userAvailability) {
        final (tempPrevious, next) = callState;
        if (tempPrevious == null) {
          return next;
        }

        switch (tempPrevious) {
          case DisconnectingCallManagerState(:final terminatedReason):
            if (next is DisconnectedCallManagerState) {
              if (terminatedReason != TerminatedReasonPigeon.hungUp &&
                  userAvailability == CallRolePigeon.sender) {
                return next;
              }

              break;
            }

          default:
            break;
        }

        return tempPrevious;
      },
    );

    _userAvailabilitySubscription = UserManager.shared
        .userAvailabilityPublisher(user)
        .listen((e) {
          userAvailability.value = e.availability;
        });
    // TODO: Listen to ControlChannel state changes
    // TODO: Listen to UserManager availability changes
    // TODO: Set up proper state management streams
  }

  void updateUser(UserPigeon newUser) {
    _user = newUser;
    notifyListeners();
  }

  void updateCallState(CallManagerState state) {
    _callState = state;
    notifyListeners();
  }

  void setShowMessagingView(bool show) {
    _showMessagingView = show;
    // TODO: Inform MessagingManager about presented message view
    notifyListeners();
  }

  void phoneButtonDidPress() {
    switch (_callState) {
      case ConnectingCallManagerState():
      case ConnectedCallManagerState():
        // TODO: Call CallManager.endCall()
        _logger.log('Ending call');
        updateCallState(
          DisconnectingCallManagerState(
            terminatedReason: TerminatedReasonPigeon.hungUp,
          ),
        );
        break;
      case DisconnectedCallManagerState():
        // TODO: Call CallManager.sendCall(to: user)
        _logger.log('Starting call with ${_user.deviceName}');
        updateCallState(ConnectingCallManagerState(user: _user));
        break;
      default:
        break;
    }
  }

  void dismiss() {
    _showMessagingView = false;
    notifyListeners();
  }
}
