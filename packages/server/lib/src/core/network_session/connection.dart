import 'package:flutter/widgets.dart';
import 'package:flutter_push_common/flutter_push_common.dart';
import 'package:flutter_push_common/models/base_model.dart';

import 'i_network_session.dart';

/// R = Socket
class Connection<R> {
  Connection({required this.session, required this.channelType, this.uuid});

  final INetworkSession<R> session;

  final ChannelType channelType;

  final String? uuid;

  Connection copyWith({
    ValueChanged<BaseModel>? onMessage,
    INetworkSession<R>? session,
    ChannelType? channelType,
    String? uuid,
  }) {
    return Connection(
      session: session ?? this.session,
      channelType: channelType ?? this.channelType,
      uuid: uuid ?? this.uuid,
    );
  }

  void dispose() {
    session.dispose();
  }
}

class ConnectionPeding<R> extends Connection<R> {
  ConnectionPeding({required super.session, required super.channelType});
}
