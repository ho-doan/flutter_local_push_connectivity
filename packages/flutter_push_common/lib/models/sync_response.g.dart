// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncResponse _$SyncResponseFromJson(Map<String, dynamic> json) => SyncResponse(
  type: json['type'] as String,
  timestamp: json['timestamp'] as String,
  data: json['data'],
);

Map<String, dynamic> _$SyncResponseToJson(SyncResponse instance) =>
    <String, dynamic>{
      'type': instance.type,
      'timestamp': instance.timestamp,
      'data': instance.data,
    };
