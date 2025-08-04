// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  deviceName: json['deviceName'] as String?,
  deviceId: json['deviceId'] as String,
  status:
      $enumDecodeNullable(_$UserStatusEnumMap, json['status']) ??
      UserStatus.offline,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'deviceName': instance.deviceName,
  'deviceId': instance.deviceId,
  'status': _$UserStatusEnumMap[instance.status]!,
};

const _$UserStatusEnumMap = {
  UserStatus.online: 'online',
  UserStatus.offline: 'offline',
  UserStatus.busy: 'busy',
  UserStatus.away: 'away',
};
