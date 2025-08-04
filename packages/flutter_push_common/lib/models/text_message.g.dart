// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextMessage _$TextMessageFromJson(Map<String, dynamic> json) => TextMessage(
  from: User.fromJson(json['from'] as Map<String, dynamic>),
  to: User.fromJson(json['to'] as Map<String, dynamic>),
  message: json['message'] as String,
);

Map<String, dynamic> _$TextMessageToJson(TextMessage instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'message': instance.message,
    };
