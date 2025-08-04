import 'dart:convert';

import 'package:flutter_push_common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';
import 'enums.dart';

part 'call_action.g.dart';

@JsonSerializable()
class Call extends BaseModel {
  final User from;
  final User to;
  final CallAction action;

  const Call({required this.from, required this.to, required this.action});

  factory Call.fromJson(Map<String, dynamic> json) => _$CallFromJson(json);
  Map<String, dynamic> toJson() => _$CallToJson(this);

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }

  @override
  Call copyWith({User? from, User? to, CallAction? action}) => Call(
    from: from ?? this.from,
    to: to ?? this.to,
    action: action ?? this.action,
  );
}
