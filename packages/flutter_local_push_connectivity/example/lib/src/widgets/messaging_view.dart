import 'package:flutter/material.dart';
import '../page/messaging_view_model.dart';
import 'message_bubble_view.dart';

class MessagingView extends StatefulWidget {
  final MessagingViewModel viewModel;
  final VoidCallback? onDismiss;

  const MessagingView({super.key, required this.viewModel, this.onDismiss});

  @override
  State<MessagingView> createState() => _MessagingViewState();
}

class _MessagingViewState extends State<MessagingView> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      widget.viewModel.setReply(_textController.text);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viewModel.message == null ? 'New Message' : 'Reply'),
        leading: TextButton(
          onPressed: widget.onDismiss,
          child: const Text(
            'Done',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                widget.viewModel.textActionsAreDisabled
                    ? null
                    : () {
                      widget.viewModel.sendMessage();
                      widget.onDismiss?.call();
                      // TODO: Handle message sending feedback
                      // TODO: Show loading state while sending
                      // TODO: Handle send errors
                    },
            child: const Text(
              'Send',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Message bubble if there's a message to reply to
              if (widget.viewModel.message != null) ...[
                MessageBubbleView(message: widget.viewModel.message!),
                const SizedBox(height: 20),
              ],

              // Text input field
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText:
                      widget.viewModel.message == null ? 'Message' : 'Reply',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: !widget.viewModel.textActionsAreDisabled,
                // TODO: Add character limit validation
                // TODO: Add input validation
                // TODO: Handle keyboard events
              ),
            ],
          );
        },
      ),
    );
  }
}
