import 'dart:convert';

import 'package:flutter_push_common/models/group.dart';
import 'package:flutter_push_common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';
import 'enums.dart';

part 'group_action.g.dart';

@JsonSerializable()
class GroupAction extends BaseModel {
  final Group? group;
  final GroupActionEnum action;
  final User? user;

  const GroupAction({required this.group, required this.action, this.user});

  factory GroupAction.fromJson(Map<String, dynamic> json) =>
      _$GroupActionFromJson(json);
  Map<String, dynamic> toJson() => _$GroupActionToJson(this);

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }

  @override
  GroupAction copyWith({Group? group, GroupActionEnum? action, User? user}) =>
      GroupAction(
        group: group ?? this.group,
        action: action ?? this.action,
        user: user ?? this.user,
      );
}
