import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/band_service.dart';
import 'package:guardian_drive_mobile/services/ble_helper.dart';
import 'package:guardian_drive_mobile/services/car_ble_service.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import '../models/enums.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert' show LineSplitter;

class BandBleService {
  // SINGLETON

  static final BandBleService instance = BandBleService._internal();
  BandBleService._internal();

  // The actual BLE library object
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // UUIDs
  static const serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const txUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
  static const rxUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';

  String? _deviceId;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _notifySubscription;

  final ValueNotifier<BleDeviceStatus> statusNotifier = ValueNotifier(
    BleDeviceStatus.disconnected,
  );

  BleDeviceStatus get status => statusNotifier.value;
  set status(BleDeviceStatus value) => statusNotifier.value = value;

  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;

  final StreamController<VitalReadings> telemetryController =
      StreamController.broadcast();
  final StreamController<String> messagesController =
      StreamController.broadcast();

  bool _readyForReadings = false;
  bool _precheckPassed = false;
  bool get precheckPassed => _precheckPassed;

  final ValueNotifier<double> bpmNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> spO2Notifier = ValueNotifier(0.0);
  final ValueNotifier<double> tempNotifier = ValueNotifier(0.0);
  // CHANGED: battNotifier is now the only value sourced from the real band
  final ValueNotifier<int> battNotifier = ValueNotifier(0);

  final ValueNotifier<bool> needsBandAdjustment = ValueNotifier(false);

  int? bandDeviceId;

  int _lastSavedBatt = -1;
  DateTime? _lastBattWrite;

  VoidCallback? _carWaitListener;

  // ── CSV config ─────────────────────────────────────────────────────────────
  String? _csvSubject = 'S01';
  // String _csvScenario = 'panic_attack'; // 1. change based on file
  String _csvScenario = 'all';
  List<_CsvRow> _csvRows = [];
  int _csvCursor = 0;
  bool _csvLoaded = false;

  // CHANGED: single timer that owns all vitals broadcasting
  Timer? _csvTimer;

  Future<void> startTestMode() async {
    print("[TEST MODE] Starting CSV playback without BLE");
    _precheckPassed = true;
    _readyForReadings = true;
    status = BleDeviceStatus.ready;
    await _loadCsvIfNeeded();
    _startCsvPlayback();
  }

  // CHANGED: _startCsvPlayback is the single place that reads CSV rows
  // and broadcasts to telemetryController + updates bpm/spO2/temp notifiers.
  // battNotifier is NOT touched here — it comes from the real band only.
  void _startCsvPlayback() {
    _csvTimer?.cancel();
    _csvTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final row = _getNextCsvRow();
      if (row == null) return;

      bpmNotifier.value = row.bpm;
      spO2Notifier.value = row.spo2;
      tempNotifier.value = row.temp;

      telemetryController.add(
        VitalReadings(
          heartRate: row.bpm,
          spo2: row.spo2,
          temp: row.temp,
          timestamp: DateTime.now(),
        ),
      );
      BandService.sendVitals(
        heartRate: row.bpm,
        spo2: row.spo2,
        temp: row.temp,
      );

      print("[CSV] BPM: ${row.bpm}, SPO2: ${row.spo2}, TEMP: ${row.temp}");
    });
  }

  Future<void> _loadCsvIfNeeded() async {
    print("Loading csv ..");
    if (_csvLoaded) return;
    final raw = await rootBundle.loadString(
      'assets/panic_attack.csv',
    ); // 2. change when file changes
    final lines = const LineSplitter().convert(raw);
    if (lines.isEmpty) return;

    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final iSubject = headers.indexOf('subject_id');
    final iBpm = headers.indexOf('bpm');
    final iSpo2 = headers.indexOf('spo2');
    final iTemp = headers.indexOf('skin_temp_c');
    final iLabel = headers.indexOf('label');

    traceLog("label: $iLabel, subject: $iSubject");

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final cols = line.split(',');
      if (cols.length <= iLabel) continue;
      final rowSubject = cols[iSubject].trim();
      final rowLabel = cols[iLabel].trim();
      // if (_csvSubject != null && rowSubject != _csvSubject) continue;
      // if (_csvScenario != 'all' && rowLabel != _csvScenario) continue;
      _csvRows.add(
        _CsvRow(
          bpm: double.tryParse(cols[iBpm].trim()) ?? 0,
          spo2: double.tryParse(cols[iSpo2].trim()) ?? 0,
          temp: double.tryParse(cols[iTemp].trim()) ?? 0,
          // CHANGED: store remaining columns too
          label: cols[iLabel].trim(),
          subjectId: cols[iSubject].trim(),
        ),
      );
    }
    _csvLoaded = true;
    print("[CSV] Loaded ${_csvRows.length} rows");
  }

  _CsvRow? _getNextCsvRow() {
    if (_csvRows.isEmpty) return null;
    final row = _csvRows[_csvCursor % _csvRows.length];
    traceLog(
      'CSV ROW: Label: ${row.label}, subject: ${row.subjectId}, Bpm: ${row.bpm}, temp: ${row.temp}, spo2:${row.spo2}',
    );
    _csvCursor++;
    return row;
  }

  // Only update battery once per meaningful change or once every 5 mins
  void _maybeSaveBattery(int newBatt) {
    final now = DateTime.now();
    final timeSinceLast = _lastBattWrite == null
        ? const Duration(hours: 99)
        : now.difference(_lastBattWrite!);

    final changed = (newBatt - _lastSavedBatt).abs() >= 2;
    final timedOut = timeSinceLast >= const Duration(minutes: 5);

    if (changed || timedOut) {
      _lastSavedBatt = newBatt;
      _lastBattWrite = now;
      BandService.patchBand(bandDeviceId!, batteryLevel: newBatt);
    }
  }

  Timer? _scanTimeout;

  Future<void> scanAndConnect() async {
    final error = await BleHelper.checkBle(_ble);
    if (error != null) {
      status = BleDeviceStatus.disconnected;
      messagesController.add(error);
      return;
    }
    status = BleDeviceStatus.connecting;
    bandDeviceId ??= await StorageService.getDeviceId();
    if (bandDeviceId == null) {
      messagesController.add("No Band is assigned.");
      print("No band assigned for driver");
      return;
    }
    print("[BAND] scan and connect function called");
    _scanSubscription?.cancel();
    _scanTimeout?.cancel();
    _scanTimeout = Timer(const Duration(seconds: 30), () {
      print("Scan timed out");
      _connectionSubscription?.cancel();
      _scanSubscription?.cancel();
      status = BleDeviceStatus.disconnected;
      messagesController.add(
        "Band not found. Please make sure the band is powered on and nearby.",
      );
    });

    _scanSubscription = _ble
        .scanForDevices(
          withServices: [Uuid.parse(serviceUuid)],
          scanMode: ScanMode.lowLatency,
        )
        .listen((device) {
          print("Found device ${device.name} - ${device.id}");
          if (device.name == "ESP32_BAND") {
            print("FOUND ${device.name}");
            _scanTimeout?.cancel();
            _deviceId = device.id;
            _scanSubscription?.cancel();
            connect(device.id);
          }
        });
  }

  Future<void> connect(String deviceId) async {
    _connectionSubscription?.cancel();
    print("CONNECT FUNCTION CALLED");
    _connectionSubscription = _ble
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (connectionState) async {
            if (connectionState.connectionState ==
                DeviceConnectionState.connected) {
              status = BleDeviceStatus.connected;
              print("CONNECTION SUCCESSFUL");

              if (!_precheckPassed) {
                _readyForReadings = false;
              } else {
                // Reconnect: band won't re-send "P", skip straight to ready
                _readyForReadings = true;
                // CHANGED: on reconnect, restart CSV playback without reloading
                _csvLoaded = true;
                _startCsvPlayback();
                status = BleDeviceStatus.ready;
                print("Reconnection successful, skip straight to ready");
              }

              _reconnectAttempts = 0;
              BandService.patchBand(bandDeviceId!, isConnected: true);
              print("# OF ATTEMPTS RESET: $_reconnectAttempts");

              try {
                final mtu = await _ble.requestMtu(deviceId: deviceId, mtu: 247);
                print("Negotiated MTU: $mtu");
                if (mtu < 100) {
                  print(
                    "WARNING: MTU too low ($mtu), fragmentation will occur",
                  );
                }
              } catch (e) {
                print("MTU negotiation failed: $e");
              }
              _subscribeToNotifications();
            }

            if (connectionState.connectionState ==
                DeviceConnectionState.disconnected) {
              status = BleDeviceStatus.disconnected;
              print("CONNECTION STATE: DISCONNECTED");
              // CHANGED: stop CSV timer on disconnect
              _csvTimer?.cancel();
              BandService.patchBand(bandDeviceId!, isConnected: false);
              if (_carWaitListener != null) {
                CarBleService.instance.statusNotifier.removeListener(
                  _carWaitListener!,
                );
                _carWaitListener = null;
              }
              _reconnect();
            }
          },
          onError: (e) {
            print("Connection Error: $e");
            status = BleDeviceStatus.disconnected;
            // CHANGED: stop CSV timer on error too
            _csvTimer?.cancel();
            _reconnect();
          },
        );
  }

  void _waitForCarThenSendR() {
    _carWaitListener = () async {
      final carStatus = CarBleService.instance.status;
      if (carStatus == BleDeviceStatus.ready) {
        CarBleService.instance.statusNotifier.removeListener(_carWaitListener!);
        _carWaitListener = null;
        status = BleDeviceStatus.ready;
        await sendCommand("R");
        print("Car connected — sent R to band");
        _readyForReadings = true;
        // CHANGED: load CSV then start timer
        await _loadCsvIfNeeded();
        _startCsvPlayback();
      }
    };
    CarBleService.instance.statusNotifier.addListener(_carWaitListener!);
  }

  StringBuffer _buffer = StringBuffer();

  void _subscribeToNotifications() {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(txUuid),
      deviceId: _deviceId!,
    );

    _notifySubscription?.cancel();
    _notifySubscription = _ble.subscribeToCharacteristic(characteristic).listen((
      data,
    ) async {
      final message = utf8.decode(data).trim();
      print("CHUNK: $message");

      // ── HANDSHAKE PHASE ───────────────────────────────────────────────
      if (!_readyForReadings) {
        if (message == "P") {
          print("Band precheck passed");
          _precheckPassed = true;
          status = BleDeviceStatus.precheckPassed;
          _readyForReadings = false;

          if (CarBleService.instance.status == BleDeviceStatus.ready) {
            status = BleDeviceStatus.ready;
            await sendCommand("R");
            print("Car already connected, sent R");
            _readyForReadings = true;
            // CHANGED: load CSV then start timer
            await _loadCsvIfNeeded();
            _startCsvPlayback();
          } else {
            print("Car not connected yet, waiting...");
            _waitForCarThenSendR();
          }
        } else if (message == "F") {
          print("Band precheck FAILED");
          _precheckPassed = false;
          status = BleDeviceStatus.precheckFailed;
          messagesController.add(
            "Band Connection failed, please contact your fleet manager.",
          );
        }
        return;
      }

      // ── BAND CONTROL MESSAGES ─────────────────────────────────────────
      if (message == "AD") {
        print("PLEASE ADJUST YOUR BAND");
        needsBandAdjustment.value = true;
        return;
      }
      if (message == "ET") {
        print("Not adjusted for too long, will enter sleep mode");
        messagesController.add(
          "Band not adjusted for too long and will enter sleep mode. Please restart your band.",
        );
        await sendCommand("E");
        print("SENT 'E' to BAND to END TRIP, TO ENTER SLEEP MODE");
        return;
      }

      // ── BAND JSON — extract BATT only, ignore vitals ──────────────────
      // CHANGED: vitals (bpm, spO2, temp) are sourced from _csvTimer only.
      // The only value we care about from the band's JSON is BATT.
      _buffer.write(message);
      needsBandAdjustment.value = false;

      String text = _buffer.toString();
      print("BUFFER NOW: $text");

      // Safety net: prevent buffer growing unbounded on dropped packets
      const maxBufferLength = 512;
      if (text.length > maxBufferLength) {
        final lastOpen = text.lastIndexOf('{');
        print("Buffer overflow (${text.length} chars) - discarding stale data");
        text = lastOpen == -1 ? '' : text.substring(lastOpen);
      }

      while (true) {
        int start = text.indexOf('{');
        if (start == -1) break;
        int end = text.indexOf('}', start);
        if (end == -1) break;

        final jsonStr = text.substring(start, end + 1);

        try {
          final Map<String, dynamic> parsed = jsonDecode(jsonStr);
          // CHANGED: only BATT is read from the band — everything else ignored
          final batt = parsed['BATT'];
          final bandBpm = parsed['bpm'];
          final bandTemp = parsed['temp'];
          final bandSpo2 = parsed['spo2'];
          print(
            'Band Readings batt = $batt , hr = $bandBpm , temp = $bandTemp , spo2 = $bandSpo2',
          );
          if (batt is num) {
            battNotifier.value = batt.toInt();
            _maybeSaveBattery(battNotifier.value);
            print("[BAND] BATT: ${battNotifier.value}");
          }
        } catch (e) {
          print("Invalid JSON: $jsonStr");
        }

        text = text.substring(end + 1);
      }

      _buffer.clear();
      _buffer.write(text);
    });
  }

  Future<void> sendCommand(String command) async {
    if (_deviceId == null) return;

    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(rxUuid),
      deviceId: _deviceId!,
    );

    await _ble.writeCharacteristicWithoutResponse(
      characteristic,
      value: utf8.encode(command),
    );
  }

  Future<bool> stopBand() async {
    if (status == BleDeviceStatus.ready) {
      await sendCommand("T");

      // the car will disconnect itself after receiving T
      status = BleDeviceStatus.disconnected;
      return true;
    }
    // Wait for automatic reconnection
    if (status == BleDeviceStatus.connecting) {
      try {
        await statusNotifier
            .waitForValue(BleDeviceStatus.ready)
            .timeout(const Duration(seconds: 30));

        await sendCommand("T");
        return true;
      } catch (_) {
        // Timed out
      }
    }

    messagesController.add(
      "Car disconnected. Unable to notify the vehicle that the trip ended.",
    );

    return false;
  }

  void _reconnect() {
    if (_deviceId == null) return;
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print("Reconnect timeout");
      messagesController.add(
        "Band Connection lost. Unable to reconnect. Please check the band and try again.",
      );
      status = BleDeviceStatus.disconnected;
      return;
    }
    _reconnectAttempts++;
    print("Band # OF ATTEMPTS NOW: $_reconnectAttempts");

    Future.delayed(const Duration(seconds: 3), () {
      print("Trying reconnect...");
      connect(_deviceId!);
    });
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    // CHANGED: cancel CSV timer on dispose
    _csvTimer?.cancel();
    if (_carWaitListener != null) {
      CarBleService.instance.statusNotifier.removeListener(_carWaitListener!);
      _carWaitListener = null;
    }
  }
}

// CHANGED: added all CSV columns
class _CsvRow {
  final double bpm;
  final double spo2;
  final double temp;
  final String label;
  final String subjectId;

  const _CsvRow({
    required this.bpm,
    required this.spo2,
    required this.temp,
    required this.label,
    required this.subjectId,
  });
}
