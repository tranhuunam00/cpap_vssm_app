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

      /// delay cho Android BLE stack
      await Future.delayed(
        const Duration(seconds: 1),
      );

      print("START SCAN");

      final completer = Completer<BluetoothDevice?>();

      /// stop old scan
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}

      await _scanSubscription?.cancel();

      /// start scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 8),
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult result in results) {
          final device = result.device;

          print("----------------");
          print("NAME: ${device.platformName}");
          print("RSSI: ${result.rssi}");

          /// match name
          final correctName = device.platformName == BleConstants.deviceName;

          /// match service UUID
          final hasService = result.advertisementData.serviceUuids
              .contains(BleConstants.serviceUuid);

          if (correctName || hasService) {
            try {
              await FlutterBluePlus.stopScan();

              await _scanSubscription?.cancel();

              /// small delay
              await Future.delayed(
                const Duration(milliseconds: 500),
              );

              print("CONNECTING...");

              await device.connect();

              await Future.delayed(
                Duration(seconds: 1),
              );

              await device.discoverServices();

              await Future.delayed(
                Duration(seconds: 1),
              );

              print("CONNECTED SUCCESS");

              connectedDevice = device;

              if (!completer.isCompleted) {
                completer.complete(device);
              }

              // /// start listener AFTER complete
              // Future.microtask(() async {
              //   try {
              //     await startListeningSensor();
              //   } catch (e) {
              //     print("LISTENER ERROR: $e");
              //   }
              // });
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

      /// timeout fallback
      Timer(
        const Duration(seconds: 12),
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
