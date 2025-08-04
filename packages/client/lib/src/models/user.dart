class User {
  final String deviceName;
  final String deviceId;

  User({required this.deviceName, required this.deviceId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      deviceName: json['deviceName'] as String? ?? 'Unknown Device',
      deviceId: json['deviceId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'deviceName': deviceName, 'deviceId': deviceId};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.deviceId == deviceId;
  }

  @override
  int get hashCode => deviceId.hashCode;
}
