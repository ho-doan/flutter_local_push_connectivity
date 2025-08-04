// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Call _$CallFromJson(Map<String, dynamic> json) => Call(
  from: User.fromJson(json['from'] as Map<String, dynamic>),
  to: User.fromJson(json['to'] as Map<String, dynamic>),
  action: $enumDecode(_$CallActionEnumMap, json['action']),
);

Map<String, dynamic> _$CallToJson(Call instance) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'action': _$CallActionEnumMap[instance.action]!,
};

const _$CallActionEnumMap = {
  CallAction.connect: 'connect',
  CallAction.hangup: 'hangup',
  CallAction.unavailable: 'unavailable',
};
