// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatusUpdate _$StatusUpdateFromJson(Map<String, dynamic> json) => StatusUpdate(
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  status: $enumDecode(_$UserStatusEnumMap, json['status']),
);

Map<String, dynamic> _$StatusUpdateToJson(StatusUpdate instance) =>
    <String, dynamic>{
      'user': instance.user,
      'status': _$UserStatusEnumMap[instance.status]!,
    };

const _$UserStatusEnumMap = {
  UserStatus.online: 'online',
  UserStatus.offline: 'offline',
  UserStatus.busy: 'busy',
  UserStatus.away: 'away',
};
