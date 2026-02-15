import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive/hive.dart';

class SessionRow {
  final int biteForce;
  final int mouthOpening;
  final int elapsedMs;

  SessionRow({
    required this.biteForce,
    required this.mouthOpening,
    required this.elapsedMs,
  });
}

class SessionDataService {
  static final SessionDataService _instance = 
    SessionDataService._internal();
    
  factory SessionDataService() => _instance;
  
  SessionDataService._internal();
  
  final Box _box = Hive.box('appBox');
  final List<SessionRow> _rows = [];
  
  List<SessionRow> get rows => List.unmodifiable(_rows);
  
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _bleSub;
  
  int? _sessionStartMs;
  bool _isRecording = false;
  Timer? _uiTicker;
  
  bool get isRunning => _isRecording;
  
  int get elapsedMs {
    if (!_isRecording || _sessionStartMs == null) return 0;
    return DateTime.now().millisecondsSinceEpoch - _sessionStartMs!;
  }

  void attachBleCharacteristic(BluetoothCharacteristic characteristic) {
    _characteristic = characteristic;
    _bleSub?.cancel();
    _bleSub = characteristic.lastValueStream.listen(_onBleData);
    characteristic.setNotifyValue(true);
  }
  
  void _onBleData(List<int> value) {
    if (!_isRecording) return;
    if (value.isEmpty) return;

    final raw = utf8.decode(value).trim();
    final double? incoming = double.tryParse(raw);
    if (incoming == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _sessionStartMs ??= now;
    final elapsed = now - _sessionStartMs!;

    final double biteForce = incoming;
    final double mouthOpening = incoming;

    _rows.add(
      SessionRow(
        biteForce: biteForce.toInt(),
        mouthOpening: mouthOpening.toInt(),
        elapsedMs: elapsed,
      ),
    );

    _box.put('bite_force_data', biteForce.toDouble());
    _box.put('interincisal_opening_data', mouthOpening.toDouble());
    _box.put('last_update', now);
  }

  void start() {
    _rows.clear();
    _sessionStartMs = DateTime.now().millisecondsSinceEpoch;
    _isRecording = true;

    _bleSub?.cancel();
    if (_characteristic != null) {
      _bleSub = _characteristic!.lastValueStream.listen(_onBleData);
      _characteristic!.setNotifyValue(true);
    }

    _uiTicker?.cancel();
    _uiTicker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        _box.put('clock_tick', DateTime.now().millisecondsSinceEpoch);
      },
    );

    _box.put('last_update', DateTime.now().millisecondsSinceEpoch);
  }

  void stop() {
    _isRecording = false;

    _bleSub?.cancel();
    _bleSub = null;
    _characteristic?.setNotifyValue(false);

    _uiTicker?.cancel();
    _uiTicker = null;
  }

  void clear() {
    _rows.clear();
    _sessionStartMs = null;
    _box.delete('last_update');
  }

  void dispose() {
    _uiTicker?.cancel();
    _bleSub?.cancel();
  }
}