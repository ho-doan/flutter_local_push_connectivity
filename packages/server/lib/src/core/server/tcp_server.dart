import 'dart:io';

import 'package:flutter_push_common/flutter_push_common.dart';

import '../channel/tcp_channel.dart';
import 'i_server.dart';

class TcpServer extends IServer<ServerSocket, Socket> {
  TcpServer({required super.portNotification, required super.portControl}) {
    channelNotification = TcpChannel(
      type: ChannelType.notification,
      port: portNotification,
    );
    channelControl = TcpChannel(type: ChannelType.control, port: portControl);
  }

  @override
  Future<void> start() async {
    await channelNotification.connect();
    await channelControl.connect();
  }
}
