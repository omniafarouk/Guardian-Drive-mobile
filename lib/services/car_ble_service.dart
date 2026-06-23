import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class CarBleService {
  // SINGLETON
  static final CarBleService instance = CarBleService._internal();
  CarBleService._internal();

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
  final ValueNotifier<bool> connectionNotifier = ValueNotifier(false);
  bool get isConnected => connectionNotifier.value;
  set isConnected(bool val) => connectionNotifier.value = val;

  bool _precheckPassed = false;
  bool get precheckPassed => _precheckPassed;

  int _reconnectAttempts = 0;

  static const int maxReconnectAttempts = 10; // 10 × 3 sec = 30 sec

  final StreamController<String> commandController =
      StreamController.broadcast(); // crash events, status

  Future<void> scanAndConnect() async {
    print("[CAR] Scanning...");
    _scanSubscription?.cancel();

    _scanSubscription = _ble
        .scanForDevices(
          withServices: [Uuid.parse(serviceUuid)],
          scanMode: ScanMode.lowLatency,
        )
        .listen((device) {
          if (device.name == "ESP32_CAR") {
            print("ESP32_CAR Found car device");
            _deviceId = device.id;
            _scanSubscription?.cancel();
            _connect(device.id);
          }
        });
  }

  /// Call this when driver vitals cross a critical threshold.
  /// Sends "E" (Emergency stop) to the car.
  Future<void> severeCaseOccurred() async {
    if (!isConnected) {
      print("[CAR] Cannot send emergency — not connected");
      commandController.add("EMERGENCY_SEND_FAILED");
      return;
    }

    print("[CAR] SEVERE CASE — sending E to car");
    await _sendCommand("E");
    commandController.add("EMERGENCY_SENT");
  }

  Future<void> sendPredriveCheckPassed() async {
    if (!isConnected) {
      print("[CAR] cannot send predrive check success — not connected");
      commandController.add("PASS_SEND_FAILED");
      return;
    }

    print("Sent predrive check to car");
    await _sendCommand("P");
    commandController.add("PASS_CAR_CHECK");
  }

  Future<void> _connect(String deviceId) async {
    _connectionSubscription?.cancel();
    print("[CAR] Connecting...");

    _connectionSubscription = _ble
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (state) async {
            if (state.connectionState == DeviceConnectionState.connected) {
              print("[CAR] Connected");
              isConnected = true;
              _reconnectAttempts = 0;
              // NOTE: no need for MTU neotiation here
              // (sent and received data through this service is very small)

              _subscribeToNotifications();
              commandController.add("CAR_CONNECTED");
            }

            if (state.connectionState == DeviceConnectionState.disconnected) {
              print("[CAR] Disconnected");
              isConnected = false;
              commandController.add("CAR_DISCONNECTED");
              _reconnect();
            }
          },
          onError: (e) {
            print("[CAR] Connection error: $e");
            isConnected = false;
            _reconnect();
          },
        );
  }

  void _subscribeToNotifications() {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(txUuid),
      deviceId: _deviceId!,
    );

    _notifySubscription?.cancel();
    _notifySubscription = _ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        final message = utf8.decode(data).trim();
        print("[CAR] Received: $message");

        switch (message) {
          case "P":
            print("Car Hardware precheck passed, car can move now");
            commandController.add("CAR CONNECTION ESTABLISHED SUCCESSFULLY");
            _precheckPassed = true;
          case "F":
            print("Car precheck failed");
            _precheckPassed = false;
            commandController.add(
              "CONNECTION FALIURE, PLEASE CONTACT YOUR FLEET MANAGER",
            );
          case "C":
            // Car detected a crash via its own sensors
            print("[CAR] CRASH DETECTED");
            commandController.add("CRASH_DETECTED");
            break;

          default:
            print("[CAR] Unknown message: $message");
        }
      },
    );
  }

  Future<void> _sendCommand(String command) async {
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

    print("[CAR] Sent: $command");
  }

  void _reconnect() {
    if (_deviceId == null) return;

    if (_reconnectAttempts >= maxReconnectAttempts) {
      print("[CAR] Reconnect timeout");
      commandController.add("CAR_UNREACHABLE");
      return;
    }

    _reconnectAttempts++;
    Future.delayed(const Duration(seconds: 3), () {
      print("[CAR] Reconnect attempt $_reconnectAttempts");
      _connect(_deviceId!);
    });
  }

  bool isCarConnected() {
    return isConnected;
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
  }
}
