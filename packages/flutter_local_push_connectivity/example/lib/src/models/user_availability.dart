import 'package:flutter_local_push_connectivity/flutter_local_push_connectivity.dart';

extension UserAvailabilityExtension on UserAvailabilityPigeonEnum {
  String get displayName {
    switch (this) {
      case UserAvailabilityPigeonEnum.available:
        return 'Available';
      case UserAvailabilityPigeonEnum.unavailable:
        return 'Unavailable';
    }
  }
}
