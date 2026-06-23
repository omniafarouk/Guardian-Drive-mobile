import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveStore {
  static late Box _fiveMinBox;
  static late Box _thirtyMinBox;
  static bool _initialized = false;

  // Accept an optional path — if provided, skip Hive.initFlutter()
  static Future<void> init({String? testPath}) async {
    if (_initialized) return; // already done — safe to call multiple times
    if (testPath != null) {
      Hive.init(testPath); // plain Dart init, no platform channel needed
    } else {
      await Hive.initFlutter(); // real app — uses path_provider
    }

    _fiveMinBox = await Hive.openBox('five_min');
    _thirtyMinBox = await Hive.openBox('thirty_min');
  }

  static Future<void> _ensureInitialized() async {
    if (!_initialized) await init();
  }

  static Future<void> saveFiveMin(VitalReadings r) async {
    await _ensureInitialized(); // Done EveryWhere to prevent storage on empty/ un-intialized bxed
    await _fiveMinBox.add(r.toMap());
  }

  static Future<void> saveThirtyMin(VitalReadings r) async {
    await _ensureInitialized();
    await _thirtyMinBox.add(r.toMap());
  }

  static Future<List<VitalReadings>> getAllFiveMin() async {
    await _ensureInitialized();
    return _fiveMinBox.values
        .map((e) => VitalReadings.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<VitalReadings>> getAllThirtyMin() async {
    await _ensureInitialized();
    return _thirtyMinBox.values
        .map((e) => VitalReadings.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> clearFiveMin() async {
    await _ensureInitialized();
    await _fiveMinBox.clear();
  }

  static Future<void> clearAll() async {
    await _ensureInitialized();
    await _fiveMinBox.clear();
    await _thirtyMinBox.clear();
  }
}
