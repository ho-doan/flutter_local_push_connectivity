import '../messages.g.dart';

class MessagingManager extends MessagingManagerHostApi {
  static final MessagingManager shared = MessagingManager._internal();

  MessagingManager._internal()
    : super(messageChannelSuffix: 'messaging_manager');

  Stream<TextMessagePigeon> get messagePublisher =>
      onChanged(
        instanceName: 'messaging_manager_message_publisher',
      ).map((e) => e as TextMessagePigeon).asBroadcastStream();
}
