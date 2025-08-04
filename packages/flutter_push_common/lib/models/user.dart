import 'dart:convert';

import 'package:flutter_push_common/models/enums.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends BaseModel {
  final String? deviceName;
  final String deviceId;
  final UserStatus status;

  const User({
    required this.deviceName,
    required this.deviceId,
    this.status = UserStatus.offline,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() {
    return 'User(deviceName: $deviceName, deviceId: $deviceId, status: $status)';
  }

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }

  @override
  User copyWith({String? deviceName, String? deviceId, UserStatus? status}) =>
      User(
        deviceName: deviceName ?? this.deviceName,
        deviceId: deviceId ?? this.deviceId,
        status: status ?? this.status,
      );
}
