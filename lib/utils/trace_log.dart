// utils/trace_log.dart
import 'package:logger/logger.dart';

// Create a global logger instance that will be used across the app
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    // Number of method calls (stack trace depth) to show in logs
    // 0 = clean logs (no function call chain shown)
    errorMethodCount: 5,
    // How many stack trace lines to show when an ERROR occurs
    lineLength: 120,
    // Maximum number of characters per log line before wrapping
    // Higher value = fewer line breaks, more compact logs
    colors: true,
    // Enables colored output in terminal/logcat
    printEmojis: true,
    // Adds emojis to log levels
  ),
);

void traceLog(String step, [dynamic data]) {
  final timestamp = DateTime.now().toIso8601String().substring(
    11,
    19,
  ); // HH:MM:SS
  logger.i('[$timestamp] $step${data != null ? ' → $data' : ''}');
}

// // type could be 'i' , 'f' , 'd' , 'e'
// void tracelog(String? type, String step, [dynamic data]) {
//   final timestamp = DateTime.now().toIso8601String().substring(
//     11,
//     19,
//   ); // HH:MM:SS
//   switch (type) {
//     case 'i': // info
//       logger.i('\n[$timestamp] $step${data != null ? ' → $data' : ''}');
//       break;
//     case 'd': // debug
//       logger.d('\n[$timestamp] $step${data != null ? ' → $data' : ''}');
//       break;
//     case 'e': // error
//       logger.e('\n[$timestamp] $step${data != null ? ' → $data' : ''}');
//       break;
//     case 'f': // fatal
//       logger.f('\n[$timestamp] $step${data != null ? ' → $data' : ''}');
//       break;
//     default:
//       logger.d('\n[$timestamp] $step${data != null ? ' → $data' : ''}');
//   }
// }

/*
to print , use something like:

traceLog('Aggregator started');
traceLog('Raw reading received', 'HR=${r.heartRate}');

*/
