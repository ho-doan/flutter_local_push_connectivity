// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Directory _$DirectoryFromJson(Map<String, dynamic> json) => Directory(
  users:
      (json['users'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$DirectoryToJson(Directory instance) => <String, dynamic>{
  'users': instance.users,
};
