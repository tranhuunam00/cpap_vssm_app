import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConstants {
  static Guid serviceUuid = Guid("cb24858f-399f-4498-85e8-fea9d383d54f");

  static Guid sensorCharacteristicUuid =
      Guid("5e9e214b-124c-434d-84e5-018dccd35df1");

  static Guid actionCharacteristicUuid =
      Guid("56debc28-acab-4184-8f86-1a9c887b220a");

  static const String deviceName = "CPAP_VSSM";
}
