part of 'ble_cubit.dart';

abstract class BleState {}

class BleInitial extends BleState {}

class BleSearching extends BleState {}

class BleNotFound extends BleState {}

class BleConnected extends BleState {
  final String deviceName;

  BleConnected(this.deviceName);
}
