import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends BaseModel {
  final String deviceName;
  final String deviceId;

  const User({required this.deviceName, required this.deviceId});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() {
    return 'User(deviceName: $deviceName, deviceId: $deviceId)';
  }

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }
}
