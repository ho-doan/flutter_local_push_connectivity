// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupAction _$GroupActionFromJson(Map<String, dynamic> json) => GroupAction(
  group:
      json['group'] == null
          ? null
          : Group.fromJson(json['group'] as Map<String, dynamic>),
  action: $enumDecode(_$GroupActionEnumEnumMap, json['action']),
  user:
      json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GroupActionToJson(GroupAction instance) =>
    <String, dynamic>{
      'group': instance.group,
      'action': _$GroupActionEnumEnumMap[instance.action]!,
      'user': instance.user,
    };

const _$GroupActionEnumEnumMap = {
  GroupActionEnum.create: 'create',
  GroupActionEnum.join: 'join',
  GroupActionEnum.leave: 'leave',
  GroupActionEnum.invite: 'invite',
  GroupActionEnum.update: 'update',
};
