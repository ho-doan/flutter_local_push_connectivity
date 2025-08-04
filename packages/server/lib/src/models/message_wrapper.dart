import '../messages.g.dart';

extension UserPigeonJson on UserPigeon {
  Map<String, dynamic> toJson() {
    return {'deviceName': deviceName, 'deviceId': deviceId};
  }

  static UserPigeon fromJson(Map<String, dynamic> json) {
    final user = UserPigeon();
    user.deviceName = json['deviceName'] as String?;
    user.deviceId = json['deviceId'] as String?;
    return user;
  }
}

extension DirectoryPigeonJson on DirectoryPigeon {
  Map<String, dynamic> toJson() {
    return {'users': users?.map((e) => e.toJson()).toList()};
  }

  static DirectoryPigeon fromJson(Map<String, dynamic> json) {
    final directory = DirectoryPigeon();
    directory.users =
        (json['users'] as List<dynamic>?)
            ?.map((e) => UserPigeonJson.fromJson(e as Map<String, dynamic>))
            .toList();
    return directory;
  }
}

extension InvitePigeonJson on InvitePigeon {
  Map<String, dynamic> toJson() {
    return {'from': from?.toJson(), 'to': to?.toJson(), 'message': message};
  }

  static InvitePigeon fromJson(Map<String, dynamic> json) {
    final invite = InvitePigeon();
    invite.from =
        json['from'] != null
            ? UserPigeonJson.fromJson(json['from'] as Map<String, dynamic>)
            : null;
    invite.to =
        json['to'] != null
            ? UserPigeonJson.fromJson(json['to'] as Map<String, dynamic>)
            : null;
    invite.message = json['message'] as String?;
    return invite;
  }
}

extension TextMessagePigeonJson on TextMessagePigeon {
  Map<String, dynamic> toJson() {
    return {'from': from?.toJson(), 'to': to?.toJson(), 'message': message};
  }

  static TextMessagePigeon fromJson(Map<String, dynamic> json) {
    final message = TextMessagePigeon();
    message.from =
        json['from'] != null
            ? UserPigeonJson.fromJson(json['from'] as Map<String, dynamic>)
            : null;
    message.to =
        json['to'] != null
            ? UserPigeonJson.fromJson(json['to'] as Map<String, dynamic>)
            : null;
    message.message = json['message'] as String?;
    return message;
  }
}

extension CallActionPigeonJson on CallActionPigeon {
  Map<String, dynamic> toJson() {
    return {'from': from?.toJson(), 'to': to?.toJson(), 'action': action};
  }

  static CallActionPigeon fromJson(Map<String, dynamic> json) {
    final action = CallActionPigeon();
    action.from =
        json['from'] != null
            ? UserPigeonJson.fromJson(json['from'] as Map<String, dynamic>)
            : null;
    action.to =
        json['to'] != null
            ? UserPigeonJson.fromJson(json['to'] as Map<String, dynamic>)
            : null;
    action.action = json['action'] as String?;
    return action;
  }
}
