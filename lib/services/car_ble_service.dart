import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:guardian_drive_mobile/services/ble_helper.dart';
import '../models/enums.dart';

class CarBleService {
  // SINGLETON
  static final CarBleService instance = CarBleService._internal();
  CarBleService._internal();

  // The actual BLE library object
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // UUIDs
  static const serviceUuid = '12345678-1234-1234-1234-1234567890AB';

  static const txUuid = '12345678-1234-1234-1234-1234567890AD';

  static const rxUuid = '12345678-1234-1234-1234-1234567890AC';

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

  bool _precheckPassed = false;
  bool get precheckPassed => _precheckPassed;

  int _reconnectAttempts = 0;

  static const int maxReconnectAttempts = 10; // 10 × 3 sec = 30 sec
  bool _allowReconnect = true;

  final StreamController<String> messagesController =
      StreamController.broadcast(); // crash events, status
  Timer? _scanTimeout;
  Future<void> scanAndConnect() async {
    _allowReconnect = true;
    final error = await BleHelper.checkBle(_ble);

    if (error != null) {
      status = BleDeviceStatus.disconnected;
      messagesController.add(error);
      return;
    }
    status = BleDeviceStatus.connecting;
    print("[CAR] scan and connect function called");
    _scanSubscription?.cancel();
    _scanTimeout?.cancel();
    _scanTimeout = Timer(const Duration(seconds: 30), () {
      print("Scan timed out");
      _connectionSubscription?.cancel();
      _scanSubscription?.cancel();

      status = BleDeviceStatus.disconnected;

      messagesController.add("Car not found for connection, please try again.");
    });
    _scanSubscription = _ble
        .scanForDevices(
          withServices: [Uuid.parse(serviceUuid)],
          scanMode: ScanMode.lowLatency,
        )
        .listen((device) {
          print("found DEVICE ${device.name} - ${device.id}");
          // if (device.name == "ESP32_CAR") {
          print("FOUNDD $device.name");
          _scanTimeout?.cancel();
          _deviceId = device.id;
          _scanSubscription?.cancel();
          _connect(device.id);
          // }
        });
  }

  /// Call this when driver vitals cross a critical threshold.
  /// Sends "E" (Emergency stop) to the car.
  Future<void> sendSevereCaseOccurred() async {
    if (status != BleDeviceStatus.connected) {
      print("[CAR] Cannot send emergency — not connected");
      messagesController.add(
        "Car Connection lost. Can't stop it automatically right now.",
      );
      return;
    }

    print("[CAR] SEVERE CASE — sending E to car");
    await _sendCommand("E");
    messagesController.add("Stopping the car in progress..");
  }

  Future<void> sendPredriveCheckPassed() async {
    if (status != BleDeviceStatus.connected) {
      print("[CAR] cannot send predrive check success — not connected");
      messagesController.add(
        "Car Connection lost. Predrive check sending failed.",
      );
      return;
    }

    print("Sent predrive check to car");
    await _sendCommand("P");
    // messagesController.add("PASS_CAR_CHECK");
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
              // status = BleDeviceStatus.connected;
              _reconnectAttempts = 0;
              if (!_precheckPassed) {
                status = BleDeviceStatus.connected; // wait for "P"
              } else {
                // reconnect — skip precheck, go straight to ready
                status = BleDeviceStatus.ready;
              }

              // NOTE: no need for MTU neotiation here
              // (sent and received data through this service is very small)

              _subscribeToNotifications();
            }

            if (state.connectionState == DeviceConnectionState.disconnected) {
              print("[CAR] Disconnected");
              status = BleDeviceStatus.disconnected;
              _reconnect();
            }
          },
          onError: (e) {
            print("[CAR] Connection error: $e");
            status = BleDeviceStatus.disconnected;
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
            _precheckPassed = true;
            status = BleDeviceStatus.ready;
            break;
          case "F":
            print("Car precheck failed");
            _allowReconnect = false;
            _precheckPassed = false;
            messagesController.add(
              "Car Connection failed, please contact your fleet manager.",
            );
            status = BleDeviceStatus.precheckFailed;
            break;
          case "C":
            // Car detected a crash via its own sensors
            print("[CAR] CRASH DETECTED");
            messagesController.add("CRASH_DETECTED");
            // TRIGGER SOS, OR TELL THE FLEET MANAGER?
            break;

          default:
            messagesController.add(
              "Car Connection when wrong, please contact your fleet manager.",
            );
            status = BleDeviceStatus.disconnected;
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
    if (!_allowReconnect) {
      print("[CAR] Reconnect disabled.");
      return;
    }
    if (_deviceId == null) return;

    if (_reconnectAttempts >= maxReconnectAttempts) {
      print("[CAR] Reconnect timeout");
      messagesController.add(
        "Car Connection lost. Unable to reconnect, please try again.",
      );
      return;
    }

    _reconnectAttempts++;
    Future.delayed(const Duration(seconds: 3), () {
      print("[CAR] Reconnect attempt $_reconnectAttempts");
      _connect(_deviceId!);
    });
  }

  bool isCarConnected() {
    return status == BleDeviceStatus.connected;
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
  }
}
