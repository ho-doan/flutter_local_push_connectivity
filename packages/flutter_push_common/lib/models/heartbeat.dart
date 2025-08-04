import 'dart:convert';

import 'package:flutter_push_common/models/base_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'heartbeat.g.dart';

@JsonSerializable()
class Heartbeat extends BaseModel {
  final int count;

  const Heartbeat({this.count = 0});

  factory Heartbeat.fromJson(Map<String, dynamic> json) =>
      _$HeartbeatFromJson(json);
  Map<String, dynamic> toJson() => _$HeartbeatToJson(this);

  @override
  String toMessage() => jsonEncode(toJson());

  @override
  Heartbeat copyWith({int? count}) => Heartbeat(count: count ?? this.count);
}
