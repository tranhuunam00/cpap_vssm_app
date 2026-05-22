import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_constants.dart';

class BleService {
  BluetoothDevice? connectedDevice;

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  StreamSubscription<List<int>>? sensorSubscription;

  final StreamController<Map<String, dynamic>> sensorDataController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get sensorStream => sensorDataController.stream;

  /// =========================
  /// REQUEST PERMISSIONS
  /// =========================
  Future<void> requestPermissions() async {
    await Permission.location.request();

    await Permission.bluetooth.request();

    await Permission.bluetoothScan.request();

    await Permission.bluetoothConnect.request();

    await Permission.bluetoothAdvertise.request();
  }

  /// =========================
  /// AUTO CONNECT TO CPAP DEVICE
  /// =========================
  Future<BluetoothDevice?> autoConnect() async {
    try {
      print("REQUEST PERMISSIONS");

      await requestPermissions();

      await Future.delayed(
        const Duration(seconds: 1),
      );

      print("START SCAN");

      final completer = Completer<BluetoothDevice?>();

      Timer? timeoutTimer;

      /// stop old scan
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}

      await _scanSubscription?.cancel();

      /// =========================
      /// TIMEOUT TIMER
      /// =========================
      timeoutTimer = Timer(
        const Duration(seconds: 60),
        () async {
          if (!completer.isCompleted) {
            print("SCAN TIMEOUT");

            try {
              await FlutterBluePlus.stopScan();
            } catch (_) {}

            await _scanSubscription?.cancel();

            completer.complete(null);
          }
        },
      );

      /// =========================
      /// START SCAN
      /// =========================
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        /// avoid duplicate callback
        if (completer.isCompleted) return;

        for (ScanResult result in results) {
          final device = result.device;

          print("----------------");
          print("NAME: ${device.platformName}");
          print("RSSI: ${result.rssi}");

          final correctName = device.platformName == BleConstants.deviceName;

          final hasService = result.advertisementData.serviceUuids
              .contains(BleConstants.serviceUuid);

          if (correctName || hasService) {
            try {
              /// stop scan
              await FlutterBluePlus.stopScan();

              await _scanSubscription?.cancel();

              await Future.delayed(
                const Duration(milliseconds: 500),
              );

              print("CONNECTING...");

              /// disconnect old
              try {
                await device.disconnect();
              } catch (_) {}

              await Future.delayed(
                const Duration(milliseconds: 500),
              );

              /// connect
              await device.connect(
                timeout: const Duration(seconds: 15),
              );

              await Future.delayed(
                const Duration(seconds: 1),
              );

              /// discover services
              await device.discoverServices();

              await Future.delayed(
                const Duration(seconds: 1),
              );

              /// cancel timeout
              timeoutTimer?.cancel();

              print("CONNECTED SUCCESS");

              connectedDevice = device;

              if (!completer.isCompleted) {
                completer.complete(device);
              }
            } catch (e) {
              print("CONNECT ERROR: $e");

              if (!completer.isCompleted) {
                completer.complete(null);
              }
            }

            break;
          }
        }
      });

      return completer.future;
    } catch (e) {
      print("AUTO CONNECT ERROR: $e");

      return null;
    }
  }

  /// =========================
  /// DISCONNECT DEVICE
  /// =========================
  Future<void> disconnect() async {
    try {
      await connectedDevice?.disconnect();
      connectedDevice = null;
    } catch (_) {}
  }

  Future<void> startListeningSensor() async {
    if (connectedDevice == null) return;

    print("DISCOVER SERVICES");

    List<BluetoothService> services = await connectedDevice!.discoverServices();

    for (BluetoothService service in services) {
      print("SERVICE: ${service.uuid}");

      if (service.uuid == BleConstants.serviceUuid) {
        print("TARGET SERVICE FOUND");

        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          print("CHARACTERISTIC: ${characteristic.uuid}");

          if (characteristic.uuid == BleConstants.sensorCharacteristicUuid) {
            print("SENSOR CHARACTERISTIC FOUND");

            /// enable notify
            await characteristic.setNotifyValue(true);

            print("NOTIFY ENABLED");

            /// realtime notify listener
            sensorSubscription = characteristic.onValueReceived.listen((value) {
              try {
                final data = String.fromCharCodes(value);

                print("RAW DATA: $data");

                final json = jsonDecode(data) as Map<String, dynamic>;

                sensorDataController.add(json);
              } catch (e) {
                print("PARSE ERROR: $e");
              }
            });

            print("LISTENING SENSOR DATA");
          }
        }
      }
    }
  }
}
