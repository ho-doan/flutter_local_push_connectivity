import 'package:flutter/widgets.dart';
import 'package:flutter_push_common/flutter_push_common.dart';

import '../channel/tcp_channel.dart';

abstract class IServer<T, R> extends ChangeNotifier {
  final int portNotification;
  final int portControl;

  IServer({required this.portNotification, required this.portControl});

  late final TcpChannel channelNotification;
  late final TcpChannel channelControl;

  Future<void> start();

  Future<void> stop() async {
    await channelNotification.disconnect();
    await channelControl.disconnect();
    channelNotification.dispose();
    channelControl.dispose();
    notifyListeners();
  }

  Future<bool> send(TextMessage message) => channelNotification.send(message);
}
