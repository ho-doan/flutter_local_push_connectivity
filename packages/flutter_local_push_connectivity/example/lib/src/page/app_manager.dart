import 'package:flutter/material.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';
import '../utils/logger.dart';
import 'user_view_model.dart';

class AppManager extends ChangeNotifier {
  final Logger _logger = Logger(
    prependString: 'AppManager',
    subsystem: LoggerSubsystem.general,
  );

  final Map<String, UserViewModel> _userViewModels = {};
  final FlutterLocalPushConnectivity _plugin = FlutterLocalPushConnectivity();

  bool _isExecutingInBackground = false;
  bool get isExecutingInBackground => _isExecutingInBackground;

  AppManager() {
    _initialize();
  }

  void _initialize() async {
    try {
      // Get platform version to verify plugin is working
      final platformVersion = await _plugin.getPlatformVersion();
      _logger.log('Platform version: $platformVersion');

      // TODO: Initialize the plugin with proper configuration
      // TODO: Set up PushConfigurationManager
      // TODO: Set up MessagingManager
      // TODO: Set up CallManager
      // TODO: Set up ControlChannel
      // TODO: Register this device with the control channel
      // TODO: Request notification permissions
      // TODO: Set up app lifecycle listeners (WidgetsBindingObserver)

      _logger.log('AppManager initialized successfully');
    } catch (e) {
      _logger.log('Failed to initialize AppManager: $e');
    }
  }

  UserViewModel getViewModelForUser(UserPigeon user) {
    if (!_userViewModels.containsKey(user.uuid)) {
      _userViewModels[user.uuid] = UserViewModel(user: user);
    }
    return _userViewModels[user.uuid]!;
  }

  void setBackgroundExecution(bool isBackground) {
    _isExecutingInBackground = isBackground;
    _logger.log('App background state changed: $isBackground');

    // TODO: Implement proper background/foreground state management
    // TODO: Connect/disconnect control channel based on app state
    // TODO: Handle CallKit integration for background calls

    notifyListeners();
  }

  @override
  void dispose() {
    _logger.log('Application is terminating');
    // TODO: Properly disconnect all managers
    // TODO: Clean up resources
    super.dispose();
  }
}
