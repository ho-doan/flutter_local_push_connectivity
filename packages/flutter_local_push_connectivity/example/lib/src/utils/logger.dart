enum LoggerSubsystem { general, networking, heartbeat, callKit }

class Logger {
  final String prependString;
  final LoggerSubsystem subsystem;

  Logger({required this.prependString, required this.subsystem});

  void log(String message) {
    // ignore: avoid_print
    print('$prependString: $message');
  }
}
