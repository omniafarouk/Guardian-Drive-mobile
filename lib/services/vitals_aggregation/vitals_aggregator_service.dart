import 'dart:async';

import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/hive_store.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

final Duration _fiveMinAggregatorRange = Duration(minutes: 5);
final Duration _fiveMinAggregatorTest = Duration(seconds: 10);

final Duration _thirtyminAggregatorRange = Duration(minutes: 30);
final Duration _thirtyMinAggregatorTest = Duration(seconds: 30);

class VitalsAggregator {
  final _ThirtyMinAggregator _aggregator;

  VitalsAggregator({bool testMode = false})
    : _aggregator = _ThirtyMinAggregator(testMode: testMode) {
    traceLog('VitalsAggregator created', 'testMode=$testMode');
  }

  // called at trip start
  void start() {
    traceLog('Aggregator started');
    _aggregator.start();
  }

  // TODO: Called on every Bluetooth reading (every 10s)
  void onReading(VitalReadings r) {
    traceLog('Raw reading received', 'HR=${r.heartRate}');
    _aggregator.addReading(r);
  }

  void stop() {
    traceLog('Aggregator stopped (no finalize)');
    _aggregator.stop();
  }

  // Called on trip end
  Future<VitalReadings?> finalize() async {
    traceLog('Finalize called — stopping timers');
    _aggregator.stop();

    VitalReadings? tripAvg = await _computeTripAverage();
    if (tripAvg == null) {
      traceLog('Finalize FAILED — no data found');
      throw Exception("Aggregator finalizing failed");
    }

    traceLog(
      'Finalize SUCCESS',
      'HR=${tripAvg.heartRate}, SpO2=${tripAvg.spo2}, Temp=${tripAvg.temp}',
    );
    return tripAvg;
  }
}

// ----------------------------
//  private classes for the readings flow (4 flows/stops)
// ---------------------------

// 1. Raw Buffer to read/add and save the raw values
class _RawBuffer {
  final List<VitalReadings> _readings = [];

  void add(VitalReadings reading) {
    _readings.add(reading);
  }

  // Returns _average and clears — called by the 5-min timer
  VitalReadings? flushAverage() {
    if (_readings.isEmpty) {
      traceLog('5-min flush skipped — buffer empty');
      return null;
    }

    traceLog('5-min flush — averaging ${_readings.length} raw readings');
    final avgReadings = _calulateAvgReadings(_readings);
    _readings.clear();
    return avgReadings;
  }
}

// 2. five minute aggregator to read the raw buffer values and aggregate them each 5 mins
class _FiveMinAggregator {
  final _RawBuffer _buffer = _RawBuffer();
  final Duration _interval;
  Timer? _timer;

  _FiveMinAggregator({bool testMode = false})
    : _interval = testMode ? _fiveMinAggregatorTest : _fiveMinAggregatorRange;

  void start() {
    _timer = Timer.periodic(_interval, (_) async {
      final avg = _buffer.flushAverage();
      if (avg == null) return;

      traceLog('5-min average computed', 'HR=${avg.heartRate}');
      await HiveStore.saveFiveMin(avg);
      traceLog('5-min average persisted to Hive');
    });
  }

  void addReading(VitalReadings r) => _buffer.add(r);

  // Read from Hive the aggregation values
  Future<List<VitalReadings>> flush() async {
    final readings = await HiveStore.getAllFiveMin();
    traceLog(
      '30-min flush — pulled ${readings.length} five-min readings from Hive',
    );
    await HiveStore.clearFiveMin();
    return readings;
  }

  void stop() => _timer?.cancel();
}

// 3. Thirty minute aggregator to read the 5minAggregator values and average them each 30 mins
class _ThirtyMinAggregator {
  final _FiveMinAggregator _fiveMin;
  final Duration _interval;
  Timer? _timer;

  _ThirtyMinAggregator({bool testMode = false})
    : _fiveMin = _FiveMinAggregator(testMode: testMode),
      _interval = testMode
          ? _thirtyMinAggregatorTest
          : _thirtyminAggregatorRange;

  void start() {
    _fiveMin.start();

    _timer = Timer.periodic(_interval, (_) async {
      final readings = await _fiveMin.flush();
      if (readings.isEmpty) {
        traceLog('30-min flush skipped — no five-min readings');
        return;
      }

      final avgReadings = _calulateAvgReadings(readings);
      traceLog('30-min average computed', 'HR=${avgReadings.heartRate}');
      await HiveStore.saveThirtyMin(avgReadings);
      traceLog('30-min average persisted to Hive');
    });
  }

  void addReading(VitalReadings r) => _fiveMin.addReading(r);

  void stop() {
    _timer?.cancel();
    _fiveMin.stop();
  }
}

// 4. computing trip average to return the average of all the thirtyminAggregator values along trip
// Future<VitalReadings?> _computeTripAverage() async {
//   final thirtyMinReadings = await HiveStore.getAllThirtyMin();
//   traceLog(
//     'computeTripAverage — found ${thirtyMinReadings.length} thirty-min readings',
//   );

//   if (thirtyMinReadings.isEmpty) return null;

//   return _calulateAvgReadings(thirtyMinReadings);
// }

Future<VitalReadings?> _computeTripAverage() async {
  final thirtyMinReadings = await HiveStore.getAllThirtyMin();
  final orphanedFiveMin = await HiveStore.getAllFiveMin();

  traceLog(
    'computeTripAverage',
    '${thirtyMinReadings.length} thirty-min, ${orphanedFiveMin.length} orphaned five-min',
  );

  List<VitalReadings> allReadings = [...thirtyMinReadings];

  if (orphanedFiveMin.isNotEmpty) {
    final recoveredAvg = _calulateAvgReadings(orphanedFiveMin);
    traceLog(
      'Recovered orphaned five-min readings',
      'HR=${recoveredAvg.heartRate}',
    );
    allReadings.add(recoveredAvg);
  }

  if (allReadings.isEmpty) return null;

  return _calulateAvgReadings(allReadings);
}

// ---------------------------------
// Helper functions for the calculations
// ------------------------------

VitalReadings _calulateAvgReadings(List<VitalReadings> readings) {
  final avg = VitalReadings(
    heartRate: _average(readings.map((r) => r.heartRate).toList()),
    spo2: _average(readings.map((r) => r.spo2).toList()),
    temp: _average(readings.map((r) => r.temp).toList()),
    timestamp: DateTime.now(),
  );
  return avg;
}

double _average(List<double> values) {
  return values.reduce((a, b) => a + b) / values.length;
}
