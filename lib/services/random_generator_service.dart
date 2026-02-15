import 'dart:async';
import 'dart:math';
import 'package:hive/hive.dart';

class RandomGeneratorService {

  double generateRandomAngle() {
    return _rng.nextDouble() * 360.0 - 180.0;
  }

  static final RandomGeneratorService _instance =
      RandomGeneratorService._internal();

  factory RandomGeneratorService() => _instance;
  RandomGeneratorService._internal();

  final Box _box = Hive.box('appBox');
  final Random _rng = Random();
  Timer? _timer;

  bool get isRunning => _timer != null;

  static const String keyMouth = 'interincisal_opening_data';
  static const String keyBite = 'bite_force_data';
  static const String keySamples = 'session_samples';

  /// Call this once when the screen/app starts (or before reading keys)
  void initializeDefaults() {
    // live values
    /*_box.put(keyMouth, 0);
    _box.put(keyBite, 90);*/

    // history list (table rows)
    final existing = _box.get(keySamples);
    if (existing == null) {
      _box.put(keySamples, <Map<String, dynamic>>[]);
    }
  }

  /// Clears the table history for a new session
  void startNewSession() {
    // make sure keys exist
    initializeDefaults();

    // reset history for this new session
    _box.put(keySamples, <Map<String, dynamic>>[]);

    // optional: reset live readouts at session start
    /*_box.put(keyMouth, 0);
    _box.put(keyBite, 90);*/
  }

  /// Starts generating NEW data and APPENDING it as rows
  void startRandomizing({
    Duration interval = const Duration(milliseconds: 100),
  }) {
    if (_timer != null) return;

    initializeDefaults();

    // Append the initial row with default values (90 for bite, 0 for mouth) - this is the "first row"
    final samplesRaw = _box.get(keySamples, defaultValue: <dynamic>[]);
    final samples = List<Map<String, dynamic>>.from(samplesRaw as List);
    samples.add({
      'timeMs': 0, // Starting time
      /*'biteForce': 90, // Initial/default bite force
      'mouthOpening': 0, // Initial/default mouth opening*/
    });
    _box.put(keySamples, samples);

    // Now start the timer to append random rows
    _timer = Timer.periodic(interval, (_) {
      final mouth = _rng.nextInt(51); // 0–50
      final bite = _rng.nextInt(101); // 0–100

      // 1) update live values
      _box.put(keyMouth, mouth);
      _box.put(keyBite, bite);

      // 2) append snapshot row for the table
      final samplesRaw = _box.get(keySamples, defaultValue: <dynamic>[]);
      final samples = List<Map<String, dynamic>>.from(samplesRaw as List);

      samples.add({
        'timeMs': samples.length * interval.inMilliseconds,
        'biteForce': bite,
        'mouthOpening': mouth,
      });

      _box.put(keySamples, samples);
    });
  }

  /// Alias for startRandomizing() to match calls in footer.dart
  void start() {
    startRandomizing();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Used by "Delete Session"
  void reset() {
    stop();
    /*_box.put(keyMouth, 0);
    _box.put(keyBite, 90);*/
    _box.put(keySamples, <Map<String, dynamic>>[]);
  }
}
