import 'package:equatable/equatable.dart';

import 'user.dart';

class Message extends Equatable {
  final User from;
  final User to;
  final String text;
  final DateTime timestamp;

  Message({
    required this.from,
    required this.to,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      from: User.fromJson(json['from'] as Map<String, dynamic>),
      to: User.fromJson(json['to'] as Map<String, dynamic>),
      text: json['message'] as String,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'from': from.toJson(), 'to': to.toJson(), 'message': text};
  }

  @override
  List<Object?> get props => [from, to, text, timestamp];
}

class Directory {
  final List<User> users;

  Directory({required this.users});

  factory Directory.fromJson(Map<String, dynamic> json) {
    final userList =
        (json['users'] as List<dynamic>)
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();
    return Directory(users: userList);
  }

  Map<String, dynamic> toJson() {
    return {'users': users.map((e) => e.toJson()).toList()};
  }
}
