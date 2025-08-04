import 'dart:convert';

import 'package:flutter_push_common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';

part 'group.g.dart';

@JsonSerializable()
class Group extends BaseModel {
  final String id;
  final String name;
  final List<User> users;
  final List<User> admins;

  const Group({
    required this.id,
    required this.name,
    required this.users,
    required this.admins,
  });

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }

  @override
  Group copyWith({
    String? id,
    String? name,
    List<User>? users,
    List<User>? admins,
  }) => Group(
    id: id ?? this.id,
    name: name ?? this.name,
    users: users ?? this.users,
    admins: admins ?? this.admins,
  );
}
