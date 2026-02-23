import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive/hive.dart';

/// ─────────────────────────────────────────────
/// Data row (3 columns only)
/// ─────────────────────────────────────────────
class SessionRow {
  final int elapsedMs;
  final int biteForce;
  final int mouthOpening;

  SessionRow({
    required this.elapsedMs,
    required this.biteForce,
    required this.mouthOpening,
  });
}

/// ─────────────────────────────────────────────
/// Session data service (singleton)
/// ─────────────────────────────────────────────
class SessionDataService extends ChangeNotifier {
  // Singleton
  static final SessionDataService _instance =
      SessionDataService._internal();
  factory SessionDataService() => _instance;
  SessionDataService._internal();

  // Hive storage
  final Box _box = Hive.box('appBox');

  // BLE
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _bleSub;

  // In-memory reference ONLY (never persisted)
  int? _firstDeviceMillis;

  /// ─────────────────────────────────────────────
  /// Session state
  /// ─────────────────────────────────────────────
  bool get isRunning =>
      _box.get('is_recording', defaultValue: false) as bool;

  int get elapsedMs =>
      rows.isEmpty ? 0 : rows.last.elapsedMs;

  List<SessionRow> get rows {
    final List raw =
        List.from(_box.get('session', defaultValue: []));

    return raw.map<SessionRow>((e) {
      return SessionRow(
        elapsedMs: (e['time_ms'] as num).toInt(),
        biteForce: (e['bite_force'] as num).toInt(),
        mouthOpening: (e['mouth_opening'] as num).toInt(),
      );
    }).toList(growable: false);
  }

  /// ─────────────────────────────────────────────
  /// BLE hookup
  /// ─────────────────────────────────────────────
  void attachBleCharacteristic(BluetoothCharacteristic characteristic) {
    debugPrint('🔵 BLE attached');
    _characteristic = characteristic;

    _bleSub?.cancel();
    _bleSub =
        characteristic.lastValueStream.listen(_onBleData);

    characteristic.setNotifyValue(true);
  }

  /// ─────────────────────────────────────────────
  /// BLE data handler
  /// Payload format: "millis,angle"
  /// ─────────────────────────────────────────────
  void _onBleData(List<int> value) {
    if (!isRunning) return;
    if (value.isEmpty) return;

    final raw = utf8.decode(value).trim();
    debugPrint('📥 decoded: $raw');

    final parts = raw.split(',');
    if (parts.length != 2) return;

    final int? deviceMillis = int.tryParse(parts[0]);
    final double? angle = double.tryParse(parts[1]);
    if (deviceMillis == null || angle == null) return;

    // Capture first device millis ONCE per session
    _firstDeviceMillis ??= deviceMillis;

    final int elapsed = deviceMillis - _firstDeviceMillis!;
    if (elapsed < 0) return;

    final List session =
        List.from(_box.get('session', defaultValue: []));

    session.add({
      'time_ms': elapsed,
      'bite_force': angle.toInt(),
      'mouth_opening': angle.toInt(),
    });

    _box.put('session', session);

    // Update real-time display values in Hive
    _box.put('bite_force_data', angle);
    _box.put('interincisal_opening_data', angle);

    notifyListeners();
  }

  /// ─────────────────────────────────────────────
  /// Controls
  /// ─────────────────────────────────────────────
  void start() {
    debugPrint('🟢 start() called');
    debugPrint('BLE characteristic = $_characteristic');

    if (_characteristic == null) {
      debugPrint('❌ Cannot start — BLE not attached');
      return;
    }

    _firstDeviceMillis = null;
    _box.put('session', []);
    _box.put('is_recording', true);

    notifyListeners();
  }

  void stop() {
    _box.put('is_recording', false);
    notifyListeners();
  }

  void clear() {
    _firstDeviceMillis = null;
    _box.delete('session');
    _box.put('is_recording', false);
    notifyListeners();
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }
}