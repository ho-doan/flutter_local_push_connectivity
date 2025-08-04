import 'package:flutter/material.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';
import '../page/user_view_model.dart';
import '../page/root_view_coordinator.dart';

class UserView extends StatefulWidget {
  final UserViewModel viewModel;
  final RootViewCoordinator rootViewCoordinator;
  final VoidCallback? onDismiss;

  const UserView({
    super.key,
    required this.viewModel,
    required this.rootViewCoordinator,
    this.onDismiss,
  });

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, child) {
          return Stack(
            children: [
              // Dismiss button
              Positioned(
                top: 40,
                left: 20,
                child: TextButton(
                  onPressed: widget.onDismiss,
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Contact info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Contact',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            widget.viewModel.user.deviceName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Call button and help text
                    Column(
                      children: [
                        _buildCallButton(height: 75),
                        const SizedBox(height: 15),
                        ValueListenableBuilder(
                          valueListenable: widget.viewModel.helpText,
                          builder: (context, value, child) {
                            return Text(
                              value,
                              style: const TextStyle(fontSize: 14),
                            );
                          },
                        ),
                      ],
                    ),

                    // Message button
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ValueListenableBuilder(
                            valueListenable:
                                widget.viewModel.disableCallActions,
                            builder: (context, value, child) {
                              return IconButton(
                                onPressed:
                                    value
                                        ? null
                                        : () {
                                          // Use RootViewCoordinator to present messaging view
                                          widget.rootViewCoordinator
                                              .setPresentedView(
                                                PresentedView.user(
                                                  widget.viewModel.user,
                                                  null,
                                                ),
                                              );
                                          // TODO: Navigate to messaging view
                                          // TODO: Handle messaging view presentation
                                        },
                                icon: const Icon(Icons.message, size: 30),
                              );
                            },
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCallButton({required double height}) {
    return ValueListenableBuilder(
      valueListenable: widget.viewModel.disableCallActions,
      builder: (context, value, child) {
        return GestureDetector(
          onTap: value ? null : widget.viewModel.phoneButtonDidPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: height,
            height: height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getCallButtonColor(value),
            ),
            child: Icon(Icons.call_end, size: height / 2, color: Colors.white),
          ),
        );
      },
    );
  }

  Color _getCallButtonColor(bool disabled) {
    if (disabled) {
      return Colors.grey;
    }

    return switch (widget.viewModel.callState) {
      DisconnectedCallManagerState() => Colors.blue,
      ConnectingCallManagerState() => Colors.red,
      ConnectedCallManagerState() => Colors.green,
      DisconnectingCallManagerState() => Colors.yellow,
      _ => Colors.grey,
    };
  }
}
