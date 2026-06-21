// test/vitals_aggregator_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/mock_vitals_stream.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/vitals_aggregator_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/hive_store.dart';

void main() {
  setUp(() async {
    // Fresh Hive instance for each test, using a temp directory
    await HiveStore.init(testPath: './test/hive_testing_path');
  });

  tearDown(() async {
    await Hive.deleteFromDisk(); // clean up after each test
  });

  test('saves and retrieves a five-min reading', () async {
    final reading = VitalReadings(
      heartRate: 75,
      spo2: 98,
      temp: 36.6,
      timestamp: DateTime.now(),
    );
    print(
      '→ Created reading: HR=${reading.heartRate}, SpO2=${reading.spo2}, Temp=${reading.temp}',
    );

    await HiveStore.saveFiveMin(reading);
    print('→ Saved to Hive');

    final results = await HiveStore.getAllFiveMin();
    print(
      '→ Retrieved ${results.length} reading(s): HR=${results.first.heartRate}',
    );

    expect(
      results.length,
      1,
      reason: 'Expected exactly one reading after one save',
    );
    expect(results.first.heartRate, 75);
    print('✅ Test passed — value matches what was saved');
  });

  test('clearAll empties the box', () async {
    await HiveStore.saveFiveMin(
      VitalReadings(
        heartRate: 75,
        spo2: 98,
        temp: 36.6,
        timestamp: DateTime.now(),
      ),
    );
    await HiveStore.clearAll();

    final results = await HiveStore.getAllFiveMin();
    expect(results.length, 0);
  });

  test('VitalsAggregator computes correct average via public API', () async {
    final aggregator = VitalsAggregator(testMode: true); // 15s / 30s intervals
    aggregator.start();

    // Feed two known readings
    aggregator.onReading(
      VitalReadings(
        heartRate: 70,
        spo2: 98,
        temp: 36.0,
        timestamp: DateTime.now(),
      ),
    );
    aggregator.onReading(
      VitalReadings(
        heartRate: 80,
        spo2: 96,
        temp: 37.0,
        timestamp: DateTime.now(),
      ),
    );

    // Wait past one 5-min tick (15s) AND one 30-min tick (30s)
    await Future.delayed(Duration(seconds: 31));

    final result = await aggregator.finalize();

    expect(result, isNotNull);
    expect(result!.heartRate, 75); // (70 + 80) / 2
    expect(result.spo2, 97);
    expect(result.temp, 36.5);
  });

  test(
    'full pipeline: mock stream feeds aggregator correctly',
    () async {
      final aggregator = VitalsAggregator(testMode: true);
      addTearDown(aggregator.stop);

      StreamSubscription<VitalReadings>? sub;
      addTearDown(
        () => sub?.cancel(),
      ); // cancel stream too, not just aggregator

      aggregator.start();

      final receivedReadings = <double>[];
      sub = mockVitalsStream().listen((reading) {
        receivedReadings.add(reading.heartRate);
        aggregator.onReading(reading);
      });

      // Let it run through: raw readings (10s) → 5min (15s) → 30min (30s)
      await Future.delayed(Duration(seconds: 31));

      expect(
        receivedReadings.length,
        greaterThanOrEqualTo(3),
      ); // ~3 raw readings in 31s

      final result = await aggregator.finalize();
      expect(result, isNotNull);

      // Sanity check — averaged values should fall within the mock's known range
      expect(result!.heartRate, inInclusiveRange(60, 100));
      expect(result.spo2, inInclusiveRange(95, 100));
      expect(result.temp, inInclusiveRange(36, 38));
    },
    timeout: Timeout(Duration(seconds: 60)),
  );

  test(
    'recovers orphaned 5-min readings after simulated crash',
    () async {
      final aggregator1 = VitalsAggregator(testMode: true);
      addTearDown(aggregator1.stop);

      aggregator1.start();
      aggregator1.onReading(
        VitalReadings(
          heartRate: 70,
          spo2: 98,
          temp: 36,
          timestamp: DateTime.now(),
        ),
      );

      // Wait past the 15s 5-min tick, but NOT past the 30s 30-min tick
      await Future.delayed(Duration(seconds: 16));

      aggregator1.stop(); // simulate crash — stop without finalize

      // "App restarts" — new aggregator, same Hive boxes (not cleared)
      final aggregator2 = VitalsAggregator(testMode: true);
      addTearDown(aggregator2.stop);

      final result = await aggregator2.finalize();

      // Should recover the orphaned 5-min reading even though 30-min never fired
      expect(result, isNotNull);
    },
    timeout: Timeout(Duration(seconds: 60)),
  );
}
