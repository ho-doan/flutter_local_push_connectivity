import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';
import '../utils/logger.dart';
import '../utils/presenter.dart';
import 'user_view_model.dart';

class RootViewCoordinator extends ChangeNotifier implements Presenter {
  final Logger _logger = Logger(
    prependString: 'RootViewCoordinator',
    subsystem: LoggerSubsystem.general,
  );

  PresentedView? _presentedView;
  final Map<String, UserViewModel> _userViewModels = {};

  PresentedView? get presentedView => _presentedView;

  RootViewCoordinator() {
    _initialize();
  }

  late final StreamSubscription<CallManagerState> _callManagerStateSubscription;
  late final StreamSubscription<TextMessagePigeon>
  _messagingManagerMessageSubscription;

  void _initialize() {
    _callManagerStateSubscription = CallManager.shared.state.listen((state) {
      handleCallStateChange(state);
    });
    _messagingManagerMessageSubscription = MessagingManager
        .shared
        .messagePublisher
        .listen((message) {
          handleIncomingMessage(message);
        });
    // TODO: Set up proper state management streams

    // Simulate call state changes for demonstration
    _simulateCallStateChanges();
  }

  void _simulateCallStateChanges() {
    // TODO: Replace with real CallManager state listening
    // For now, we'll simulate the behavior
  }

  void setPresentedView(PresentedView? view) {
    _presentedView = view;
    notifyListeners();
  }

  UserViewModel getUserViewModel(UserPigeon user) {
    if (!_userViewModels.containsKey(user.uuid)) {
      _userViewModels[user.uuid] = UserViewModel(user: user);
    }
    return _userViewModels[user.uuid]!;
  }

  @override
  void dismiss() {
    _presentedView = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _callManagerStateSubscription.cancel();
    _messagingManagerMessageSubscription.cancel();
    super.dispose();
  }

  // Handle call state changes
  void handleCallStateChange(CallManagerState state) {
    switch (state) {
      case ConnectedCallManagerState(:final user):
        setPresentedView(PresentedView.user(user, null));
        break;
      default:
        break;
    }
  }

  // Handle incoming messages
  void handleIncomingMessage(TextMessagePigeon message) {
    final user = message.sender;
    setPresentedView(PresentedView.user(user, message));
  }
}

class PresentedView {
  final String id;
  final PresentedViewType type;
  final UserPigeon? user;
  final TextMessagePigeon? message;

  PresentedView({
    required this.id,
    required this.type,
    this.user,
    this.message,
  });

  factory PresentedView.settings() {
    return PresentedView(id: 'settings', type: PresentedViewType.settings);
  }

  factory PresentedView.user(UserPigeon user, TextMessagePigeon? message) {
    return PresentedView(
      id: 'user_${user.uuid}',
      type: PresentedViewType.user,
      user: user,
      message: message,
    );
  }
}

enum PresentedViewType { settings, user }
