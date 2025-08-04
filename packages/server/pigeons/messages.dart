// dart run pigeon --input pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(copyrightHeader: <String>[]),
  ),
)
enum ChannelType { notification, control }

enum UserStatus { online, away, busy, offline }

class UserPigeon {
  String? deviceName;
  String? deviceId;
  UserStatus? status;
}

class DirectoryPigeon {
  List<UserPigeon>? users;
}

class InvitePigeon {
  UserPigeon? from;
  UserPigeon? to;
  String? message;
}

class TextMessagePigeon {
  UserPigeon? from;
  UserPigeon? to;
  String? message;
}

class CallActionPigeon {
  UserPigeon? from;
  UserPigeon? to;
  String? action; // "start", "accept", "reject", "end"
}

class StatusUpdatePigeon {
  UserPigeon? user;
  UserStatus? status;
}

class GroupPigeon {
  String? groupId;
  String? name;
  List<UserPigeon>? members;
  UserPigeon? owner;
}

class GroupActionPigeon {
  String? action; // "create", "join", "leave", "invite"
  GroupPigeon? group;
  UserPigeon? user;
}

class SyncRequestPigeon {
  String? type; // "messages", "contacts", "groups"
  int? timestamp; // millisecondsSinceEpoch
  UserPigeon? user;
}

class SyncResponsePigeon {
  String? type;
  List<dynamic>? data;
  int? timestamp; // millisecondsSinceEpoch
}
