import 'dart:convert';

import 'package:flutter_push_common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';

part 'invite.g.dart';

@JsonSerializable()
class Invite extends BaseModel {
  final User from;
  final User to;

  const Invite({required this.from, required this.to});

  factory Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);
  Map<String, dynamic> toJson() => _$InviteToJson(this);

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }

  @override
  Invite copyWith({User? from, User? to}) =>
      Invite(from: from ?? this.from, to: to ?? this.to);
}
