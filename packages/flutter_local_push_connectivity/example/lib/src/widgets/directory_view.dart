import 'package:flutter/material.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';
import '../page/directory_view_model.dart';
import '../page/app_manager.dart';
import '../page/root_view_coordinator.dart';

class DirectoryView extends StatefulWidget {
  final AppManager appManager;
  final RootViewCoordinator rootViewCoordinator;
  final VoidCallback? onSettingsTap;

  const DirectoryView({
    super.key,
    required this.appManager,
    required this.rootViewCoordinator,
    this.onSettingsTap,
  });

  @override
  State<DirectoryView> createState() => _DirectoryViewState();
}

class _DirectoryViewState extends State<DirectoryView> {
  late final DirectoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DirectoryViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        leading: TextButton(
          onPressed: widget.onSettingsTap,
          child: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          return Stack(
            children: [
              // User list
              if (_viewModel.state == PushConnectionState.connected) ...[
                ListView.builder(
                  itemCount: _viewModel.users.length,
                  itemBuilder: (context, index) {
                    final user = _viewModel.users[index];
                    return _buildUserTile(user);
                  },
                ),
              ],

              // Placeholder view for other states
              if (_viewModel.state != PushConnectionState.connected) ...[
                _buildPlaceholderView(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserTile(UserPigeon user) {
    final isConnected = _viewModel.connectedUser?.uuid == user.uuid;

    return ListTile(
      onTap: () => _showUserView(user),
      title: Text(
        user.deviceName,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
      trailing: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isConnected ? Colors.blue : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildPlaceholderView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_viewModel.state.icon, size: 60, color: Colors.grey[600]),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              _viewModel.state.displayName(_viewModel.networkConfigurationMode),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserView(UserPigeon user) {
    // Use RootViewCoordinator to present the user view
    widget.rootViewCoordinator.setPresentedView(PresentedView.user(user, null));
  }
}
