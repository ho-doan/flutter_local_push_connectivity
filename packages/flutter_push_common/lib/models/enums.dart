import 'package:json_annotation/json_annotation.dart';

enum ChannelType {
  @JsonValue('notification')
  notification,
  @JsonValue('control')
  control,
}

enum UserStatus {
  @JsonValue('online')
  online,
  @JsonValue('offline')
  offline,
  @JsonValue('busy')
  busy,
  @JsonValue('away')
  away,
}

enum CallAction {
  @JsonValue('connect')
  connect,
  @JsonValue('hangup')
  hangup,
  @JsonValue('unavailable')
  unavailable,
}

enum GroupActionEnum {
  @JsonValue('create')
  create,
  @JsonValue('join')
  join,
  @JsonValue('leave')
  leave,
  @JsonValue('invite')
  invite,
  @JsonValue('update')
  update,
}
