import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ble/ble_service.dart';

part 'ble_state.dart';

class BleCubit extends Cubit<BleState> {
  final BleService bleService;

  BleCubit(this.bleService) : super(BleInitial());

  Future<void> autoConnect() async {
    emit(BleSearching());

    print("CUBIT START CONNECT");

    final device = await bleService.autoConnect();

    print("DEVICE: $device");

    if (device != null) {
      print("EMIT CONNECTED");

      emit(BleConnected(device.platformName));
    } else {
      print("EMIT NOT FOUND");

      emit(BleNotFound());
    }
  }
}
