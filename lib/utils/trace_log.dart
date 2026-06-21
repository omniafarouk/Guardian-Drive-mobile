// utils/trace_log.dart
void traceLog(String step, [dynamic data]) {
  final timestamp = DateTime.now().toIso8601String().substring(
    11,
    19,
  ); // HH:MM:SS
  print('[$timestamp] $step${data != null ? ' → $data' : ''}');
}
