import 'dart:async';

import '../messages.g.dart';

class UserManager extends UserManagerHostApi {
  static final UserManager shared = UserManager._internal();

  UserManager._internal() : super(messageChannelSuffix: 'user_manager');

  Stream<List<UserPigeon>> get users =>
      onChanged(
        instanceName: 'user_manager_users',
      ).map((e) => e as List<UserPigeon>).asBroadcastStream();

  Stream<UserAvailabilityPigeon> userAvailabilityPublisher(
    UserPigeon comparedUser,
  ) => users.map((users) {
    try {
      final user = users.firstWhere((user) => user.uuid == comparedUser.uuid);
      return UserAvailabilityPigeon(
        availability: UserAvailabilityPigeonEnum.available,
        user: user,
      );
    } catch (e) {
      return UserAvailabilityPigeon(
        availability: UserAvailabilityPigeonEnum.unavailable,
        user: comparedUser,
      );
    }
  });
}
