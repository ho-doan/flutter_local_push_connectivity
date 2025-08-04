// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncRequest _$SyncRequestFromJson(Map<String, dynamic> json) => SyncRequest(
  type: json['type'] as String,
  timestamp: json['timestamp'] as String,
  user: User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SyncRequestToJson(SyncRequest instance) =>
    <String, dynamic>{
      'type': instance.type,
      'timestamp': instance.timestamp,
      'user': instance.user,
    };
