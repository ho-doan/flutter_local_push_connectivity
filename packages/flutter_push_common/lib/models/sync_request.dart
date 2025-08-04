import 'dart:convert';

import 'package:flutter_push_common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';

part 'sync_request.g.dart';

@JsonSerializable()
class SyncRequest extends BaseModel {
  final String type;
  final String timestamp;
  final User user;

  const SyncRequest({
    required this.type,
    required this.timestamp,
    required this.user,
  });

  factory SyncRequest.fromJson(Map<String, dynamic> json) =>
      _$SyncRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SyncRequestToJson(this);

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }

  @override
  SyncRequest copyWith({String? type, String? timestamp, User? user}) =>
      SyncRequest(
        type: type ?? this.type,
        timestamp: timestamp ?? this.timestamp,
        user: user ?? this.user,
      );
}
