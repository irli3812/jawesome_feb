import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Calibration {
  static BluetoothCharacteristic? writeCharacteristic;

  static Future<void> calibrate() async {
    if (writeCharacteristic == null) {
      print("No calibration characteristic");
      return;
    }

    print("Sending calibration command");

    await writeCharacteristic!.write("C".codeUnits, withoutResponse: true);
  }
}
