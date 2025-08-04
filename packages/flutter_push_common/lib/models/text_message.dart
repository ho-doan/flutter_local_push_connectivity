import 'dart:convert';

import 'package:flutter_push_common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

import 'base_model.dart';

part 'text_message.g.dart';

@JsonSerializable()
class TextMessage extends BaseModel {
  final User from;
  final User to;
  final String message;

  const TextMessage({
    required this.from,
    required this.to,
    required this.message,
  });

  factory TextMessage.fromJson(Map<String, dynamic> json) =>
      _$TextMessageFromJson(json);
  Map<String, dynamic> toJson() => _$TextMessageToJson(this);

  @override
  String toMessage() {
    return jsonEncode(toJson());
  }

  @override
  TextMessage copyWith({User? from, User? to, String? message}) => TextMessage(
    from: from ?? this.from,
    to: to ?? this.to,
    message: message ?? this.message,
  );
}
