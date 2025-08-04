import 'package:flutter/material.dart';
import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';
import '../utils/logger.dart';

class MessagingViewModel extends ChangeNotifier {
  final Logger _logger = Logger(
    prependString: 'MessagingViewModel',
    subsystem: LoggerSubsystem.general,
  );

  TextMessagePigeon? _message;
  String _reply = '';
  bool _textActionsAreDisabled = false;
  final UserPigeon _receiver;

  TextMessagePigeon? get message => _message;
  String get reply => _reply;
  bool get textActionsAreDisabled => _textActionsAreDisabled;

  MessagingViewModel({required UserPigeon receiver, TextMessagePigeon? message})
    : _receiver = receiver,
      _message = message {
    _initialize();
  }

  void _initialize() {
    // TODO: Listen to MessagingManager.messagePublisher
    // TODO: Listen to ControlChannel state changes
    // TODO: Set up proper message state management
  }

  void setMessage(TextMessagePigeon? newMessage) {
    _message = newMessage;
    notifyListeners();
  }

  void setReply(String newReply) {
    _reply = newReply;
    notifyListeners();
  }

  void setTextActionsDisabled(bool disabled) {
    _textActionsAreDisabled = disabled;
    notifyListeners();
  }

  void sendMessage() {
    if (_reply.isEmpty) {
      return;
    }

    _logger.log('Sending message to ${_receiver.deviceName}: $_reply');

    // TODO: Call MessagingManager.send(message: reply, to: receiver)
    // TODO: Implement proper message sending through the messaging system
    // TODO: Handle message delivery status
    // TODO: Handle message sending errors

    _reply = '';
    notifyListeners();
  }
}
