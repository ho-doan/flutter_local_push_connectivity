// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invite _$InviteFromJson(Map<String, dynamic> json) => Invite(
  from: User.fromJson(json['from'] as Map<String, dynamic>),
  to: User.fromJson(json['to'] as Map<String, dynamic>),
);

Map<String, dynamic> _$InviteToJson(Invite instance) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
};
