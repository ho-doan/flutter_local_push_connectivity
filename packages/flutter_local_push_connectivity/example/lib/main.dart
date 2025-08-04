import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';
import 'src/page/app_manager.dart';
import 'src/page/root_view_coordinator.dart';
import 'src/widgets/directory_view.dart';
import 'src/widgets/settings_view.dart';
import 'src/widgets/user_view.dart';
import 'src/page/messaging_view_model.dart';
import 'src/widgets/messaging_view.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp());
    },
    (error, stackTrace) {
      print(error);
      print(stackTrace);
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _flutterLocalPushConnectivityPlugin = FlutterLocalPushConnectivity();
  late final AppManager _appManager;
  late final RootViewCoordinator _rootViewCoordinator;

  @override
  void initState() {
    super.initState();
    _appManager = AppManager();
    _rootViewCoordinator = RootViewCoordinator();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _flutterLocalPushConnectivityPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  void dispose() {
    _appManager.dispose();
    _rootViewCoordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Local Push Connectivity',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: _HomePage(
        platformVersion: _platformVersion,
        appManager: _appManager,
        rootViewCoordinator: _rootViewCoordinator,
      ),
      // TODO: Add proper app lifecycle management
      // TODO: Handle app state changes (background/foreground)
      // TODO: Add error handling for app initialization
      // TODO: Add loading states
    );
  }
}

class _HomePage extends StatefulWidget {
  final String platformVersion;
  final AppManager appManager;
  final RootViewCoordinator rootViewCoordinator;

  const _HomePage({
    required this.platformVersion,
    required this.appManager,
    required this.rootViewCoordinator,
  });

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.rootViewCoordinator,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Main DirectoryView
              DirectoryView(
                appManager: widget.appManager,
                rootViewCoordinator: widget.rootViewCoordinator,
                onSettingsTap: () {
                  widget.rootViewCoordinator.setPresentedView(
                    PresentedView.settings(),
                  );
                },
              ),

              // Sheet/Modal for presented views
              if (widget.rootViewCoordinator.presentedView != null)
                _buildPresentedView(widget.rootViewCoordinator.presentedView!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresentedView(PresentedView presentedView) {
    switch (presentedView.type) {
      case PresentedViewType.settings:
        return _buildSettingsSheet();
      case PresentedViewType.user:
        return _buildUserSheet(presentedView);
    }
  }

  Widget _buildSettingsSheet() {
    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SettingsView(
            onDismiss: () => widget.rootViewCoordinator.dismiss(),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSheet(PresentedView presentedView) {
    if (presentedView.user == null) return const SizedBox.shrink();

    final userViewModel = widget.rootViewCoordinator.getUserViewModel(
      presentedView.user!,
    );

    // If there's a message, set up messaging view
    if (presentedView.message != null) {
      final messagingViewModel = MessagingViewModel(
        receiver: presentedView.user!,
        message: presentedView.message,
      );

      return Container(
        color: Colors.black54,
        child: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: MessagingView(
              viewModel: messagingViewModel,
              onDismiss: () => widget.rootViewCoordinator.dismiss(),
            ),
          ),
        ),
      );
    }

    // Regular user view
    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: UserView(
            viewModel: userViewModel,
            rootViewCoordinator: widget.rootViewCoordinator,
            onDismiss: () => widget.rootViewCoordinator.dismiss(),
          ),
        ),
      ),
    );
  }
}
