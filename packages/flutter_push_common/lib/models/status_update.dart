import 'dart:convert';

import 'package:flutter_push_common/models/base_model.dart';
import 'package:flutter_push_common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'status_update.g.dart';

@JsonSerializable()
class StatusUpdate extends BaseModel {
  final User user;
  final UserStatus status;

  const StatusUpdate({required this.user, required this.status});

  factory StatusUpdate.fromJson(Map<String, dynamic> json) =>
      _$StatusUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$StatusUpdateToJson(this);

  @override
  String toMessage() => jsonEncode(toJson());

  @override
  StatusUpdate copyWith({User? user, UserStatus? status}) =>
      StatusUpdate(user: user ?? this.user, status: status ?? this.status);
}
