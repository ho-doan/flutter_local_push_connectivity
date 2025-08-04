import 'dart:convert';

import 'package:flutter_push_common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';

part 'directory.g.dart';

@JsonSerializable()
class Directory extends BaseModel {
  final List<User> users;

  const Directory({required this.users});

  factory Directory.fromJson(Map<String, dynamic> json) =>
      _$DirectoryFromJson(json);
  Map<String, dynamic> toJson() => _$DirectoryToJson(this);

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }

  @override
  Directory copyWith({List<User>? users}) =>
      Directory(users: users ?? this.users);
}
