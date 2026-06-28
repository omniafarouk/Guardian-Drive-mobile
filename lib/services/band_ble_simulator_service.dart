import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/band_service.dart';
import 'package:guardian_drive_mobile/services/ble_helper.dart';
import 'package:guardian_drive_mobile/services/car_ble_service.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';
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

  String? _deviceId; // save device id here (the band)

  StreamSubscription? _scanSubscription; // Represents the scanning process
  StreamSubscription?
  _connectionSubscription; // Represents the connection process
  StreamSubscription? _notifySubscription; // Listens for notifications

  // bool isConnected = false;
  // final ValueNotifier<bool> connectionNotifier = ValueNotifier(false);
  // bool get isConnected => connectionNotifier.value;
  // set isConnected(bool val) => connectionNotifier.value = val;

  final ValueNotifier<BleDeviceStatus> statusNotifier = ValueNotifier(
    BleDeviceStatus.disconnected,
  );

  BleDeviceStatus get status => statusNotifier.value;
  set status(BleDeviceStatus value) => statusNotifier.value = value;

  int _reconnectAttempts = 0;

  static const int maxReconnectAttempts = 10; // 10 × 3 sec = 30 sec

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
  final ValueNotifier<int> battNotifier = ValueNotifier(0);

  final ValueNotifier<bool> needsBandAdjustment = ValueNotifier(
    false,
  ); // to handle stacking of dialogs

  int? bandDeviceId;

  int _lastSavedBatt = -1;
  DateTime? _lastBattWrite;

  VoidCallback? _carWaitListener;

  // ── CSV config ────────────────────────────────────────────────────────────
  String? _csvSubject = 'S01';
  String _csvScenario = 'fatigue'; // 'normal', 'fatigue', or 'all'
  List<_CsvRow> _csvRows = [];
  int _csvCursor = 0;
  bool _csvLoaded = false;

  Timer? _csvTimer;

  // Call this after _readyForReadings = true (in both places)
  void _startCsvPlayback() {
    _csvTimer?.cancel();
    _csvTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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

      print("CSV BPM: ${row.bpm}, SPO2: ${row.spo2}, TEMP: ${row.temp}");
    });
  }

  Future<void> _loadCsvIfNeeded() async {
    print("Loading csv ..");
    if (_csvLoaded) return;
    final raw = await rootBundle.loadString('assets/fatigue.csv');
    final lines = const LineSplitter().convert(raw);
    if (lines.isEmpty) return;

    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final iTimestamp = headers.indexOf('timestamp_s');
    final iSubject = headers.indexOf('subject_id');
    final iBpm = headers.indexOf('bpm');
    final iSpo2 = headers.indexOf('spo2');
    final iTemp = headers.indexOf('skin_temp_c');
    final iLabel = headers.indexOf('label');

    for (final line in lines.skip(1)) {
      print("Line $line");
      if (line.trim().isEmpty) continue;
      final cols = line.split(',');
      if (cols.length <= iLabel) continue;
      final rowSubject = cols[iSubject].trim();
      final rowLabel = cols[iLabel].trim();
      if (_csvSubject != null && rowSubject != _csvSubject) continue;
      if (_csvScenario != 'all' && rowLabel != _csvScenario) continue;
      _csvRows.add(
        _CsvRow(
          bpm: double.tryParse(cols[iBpm].trim()) ?? 0,
          spo2: double.tryParse(cols[iSpo2].trim()) ?? 0,
          temp: double.tryParse(cols[iTemp].trim()) ?? 0,
        ),
      );
    }
    _csvLoaded = true;
  }

  _CsvRow? _getNextCsvRow() {
    if (_csvRows.isEmpty) return null;
    final row = _csvRows[_csvCursor % _csvRows.length];
    _csvCursor++;
    return row;
  }

  // Only update batter once per meaningful battery change or once every 5 mins
  void _maybeSaveBattery(int newBatt) {
    final now = DateTime.now();
    final timeSinceLast = _lastBattWrite == null
        ? const Duration(hours: 99)
        : now.difference(_lastBattWrite!);

    final changed = (newBatt - _lastSavedBatt).abs() >= 2.0;
    final timedOut = timeSinceLast >= const Duration(minutes: 5);

    if (changed || timedOut) {
      _lastSavedBatt = newBatt;
      _lastBattWrite = now;
      BandService.patchBand(
        bandDeviceId!,
        batteryLevel: newBatt,
      ); // ← only battery, isConnected untouched
    }
  }

  Timer? _scanTimeout;
  // starts scanning
  Future<void> scanAndConnect() async {
    // await _loadCsvIfNeeded();
    // print("CSV ROWS COUNT: ${_csvRows.length}");
    // if (_csvRows.isNotEmpty) {
    //   print("FIRST ROW: bpm=${_csvRows[0].bpm}, spo2=${_csvRows[0].spo2}, temp=${_csvRows[0].temp}");
    // } else {
    //   print("CSV IS EMPTY — check asset path and column names");
    // }
    // return;
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
          // starts ble discovery
          withServices: [
            Uuid.parse(serviceUuid),
          ], // only search for devices advertising your service
          scanMode: ScanMode.lowLatency,
        )
        .listen((device) {
          print("Found device ${device.name} - ${device.id}");

          if (device.name == "ESP32_BAND") {
            print("FOUNDD $device.name");
            _scanTimeout?.cancel();
            _deviceId = device.id;
            _scanSubscription?.cancel();
            connect(device.id); // connects to esp32
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
              // _readyForReadings = false;
              if (!_precheckPassed) {
                _readyForReadings = false;
              } else {
                // reconnect: band won't re-send "P", skip straight to ready
                _readyForReadings = true;
                _startCsvPlayback();
                _csvLoaded = true;
                status = BleDeviceStatus.ready;
                print("Reconnection successful, skip straight to ready");
              }
              _reconnectAttempts = 0;
              BandService.patchBand(bandDeviceId!, isConnected: true);
              print("# OF AT ATTEMPTS RESETEDDDD $_reconnectAttempts");

              try {
                final mtu = await _ble.requestMtu(deviceId: deviceId, mtu: 247);
                print("Negotiated MTU: $mtu");
                if (mtu < 100) {
                  // MTU too small — JSON won't fit in one packet
                  // usable payload = mtu - 3 bytes ATT overhead
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
            // isConnected = false;
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
      // every notification triggers this
      final message = utf8.decode(data).trim(); // converts bytes to text
      print("CHUNK: $message");

      // HANDSHAKE PHASE
      if (!_readyForReadings) {
        if (message == "P") {
          print("Band precheck passed");
          _precheckPassed = true;
          status = BleDeviceStatus.precheckPassed;
          _readyForReadings =
              false; // not ready for readings until the car is connected too

          if (CarBleService.instance.status == BleDeviceStatus.ready) {
            status = BleDeviceStatus.ready;
            await sendCommand("R");
            print("Car already connected, sent R");
            _readyForReadings = true;
            await _loadCsvIfNeeded();
            _startCsvPlayback();
          } else {
            // ✅ car not ready yet — wait for it
            print("Car not connected yet, waiting...");
            _waitForCarThenSendR();
          }
          // await sendCommand("R");
          // print("Mobile ready, sent R");
          // _readyForReadings = true;
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
      if (message == "AD") {
        print("PLEASE ADJUST YOUR BAND");
        // messagesController.add("Please Adjust Your Band.");
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
        // messagesController.add("SENT TO BAND END TRIP, TO ENTER SLEEP MODE");
        return;
      }
      // STARTS READING
      _buffer.write(message);
      needsBandAdjustment.value = false; // not sure about its place yet

      // wait until we have at least one full message
      String text = _buffer.toString();
      print("BUFFER NOW: ${text}");

      /*** */
      // Safety net: if we never find a closing brace and the buffer
      // keeps growing (e.g. dropped packets), don't leak memory forever.
      const maxBufferLength = 512;
      if (text.length > maxBufferLength) {
        final lastOpen = text.lastIndexOf('{');
        print("Buffer overflow (${text.length} chars) - discarding stale data");
        text = lastOpen == -1 ? '' : text.substring(lastOpen);
      }
      /*** */

      // Try to extract ALL complete JSON objects
      while (true) {
        int start = text.indexOf('{');
        if (start == -1) {
          //if the buffer contains no { at all (pure garbage), it flushes cleanly rather than crashing
          break;
        }
        int end = text.indexOf('}', start);

        if (start == -1 || end == -1) break;

        final jsonStr = text.substring(start, end + 1);

        try {
          final Map<String, dynamic> data = jsonDecode(jsonStr);
          // UPDATE NOTIFIERS ↓
          // bpmNotifier.value = (data['bpm'] ?? 0).toDouble();
          // battNotifier.value = (data['BATT'] ?? 0).toInt();
          // _maybeSaveBattery(battNotifier.value);
          /*final bpm = data['bpm'];
          final spo2 = data['spO2'];
          final temp = data['temp'];

          if (bpm is! num || spo2 is! num || temp is! num) {
            print("Invalid packet: $data");
            return;
          }*/
          // telemetryController.add(data.toString());
          final csvRow = _getNextCsvRow();
          if (csvRow != null) {
            bpmNotifier.value = csvRow.bpm;
            spO2Notifier.value = csvRow.spo2;
            tempNotifier.value = csvRow.temp;
            telemetryController.add(
              VitalReadings(
                heartRate: csvRow.bpm,
                spo2: csvRow.spo2,
                temp: csvRow.temp,
                timestamp: DateTime.now(),
              ),
            );
          }
          _maybeSaveBattery(battNotifier.value);
          print("BPM: ${csvRow?.bpm}");
          print("SPO2: ${csvRow?.spo2}");
          print("TEMP: ${csvRow?.temp}");
          // print("TEMP: ${data['temp']}");
        } catch (e) {
          print("Invalid JSON: $jsonStr");
        }

        text = text.substring(end + 1);
      }

      // keep incomplete part
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

  void _reconnect() {
    if (_deviceId == null) return;
    // ADD 1 ATTEMPT TO RECONNECT
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print("Reconnect timeout");
      messagesController.add(
        "Band Connection lost. Unable to reconnect. Please check the band and try again.",
      );
      return;
    }
    _reconnectAttempts++;
    print(" Band # OF AT ATTEMPTS NOW $_reconnectAttempts");

    Future.delayed(const Duration(seconds: 3), () {
      print("Trying reconnect...");
      connect(_deviceId!);
    });
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _csvTimer?.cancel();
    if (_carWaitListener != null) {
      CarBleService.instance.statusNotifier.removeListener(_carWaitListener!);
      _carWaitListener = null;
    }
  }
}

class _CsvRow {
  final double bpm;
  final double spo2;
  final double temp;
  const _CsvRow({required this.bpm, required this.spo2, required this.temp});
}
