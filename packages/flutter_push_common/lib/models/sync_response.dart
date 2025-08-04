import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';

part 'sync_response.g.dart';

@JsonSerializable()
class SyncResponse extends BaseModel {
  final String type;
  final String timestamp;
  final dynamic data;

  const SyncResponse({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SyncResponseToJson(this);

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }

  @override
  SyncResponse copyWith({String? type, String? timestamp, dynamic? data}) =>
      SyncResponse(
        type: type ?? this.type,
        timestamp: timestamp ?? this.timestamp,
        data: data ?? this.data,
      );
}
