import 'dart:async';
import 'dart:math';

import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

class VitalsStreamService {
  // Singleton
  static final VitalsStreamService instance = VitalsStreamService._();
  VitalsStreamService._();

  StreamController<VitalReadings>? _controller;
  StreamSubscription? _sourceSubscription;

  // Everyone subscribes to this
  Stream<VitalReadings> get stream {
    _controller ??= StreamController<VitalReadings>.broadcast();
    return _controller!.stream;
  }

  void start() {
    if (_sourceSubscription != null) return; // already running

    _controller ??= StreamController<VitalReadings>.broadcast();

    _sourceSubscription = mockVitalsStream().listen((reading) {
      if (_controller!.hasListener) {
        _controller!.add(reading);
      }
    });

    traceLog('VitalsStreamService', 'started');
  }

  void stop() {
    _sourceSubscription?.cancel();
    _sourceSubscription = null;
    _controller?.close();
    _controller = null;
    traceLog('VitalsStreamService', 'stopped');
  }
}

/*
subscribers do
VitalsStreamService.instance.stream.listen((reading) {
  // handle reading
});

// or in a StreamBuilder
StreamBuilder<VitalReadings>(
  stream: VitalsStreamService.instance.stream,
  builder: (context, snapshot) { ... },
)

// or pass it directly to health monitor
healthMonitor.start(VitalsStreamService.instance.stream);
*/

Stream<VitalReadings> mockVitalsStream() {
  final random = Random();
  return Stream.periodic(Duration(seconds: 10), (_) {
    return VitalReadings(
      heartRate: 80 + random.nextDouble() * 40,
      spo2: 91 + random.nextDouble() * 5,
      temp: 33.5,
      timestamp: DateTime.now(),
    );
  });
}
