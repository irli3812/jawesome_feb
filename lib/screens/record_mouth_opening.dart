// ignore_for_file: unnecessary_underscores

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import '../widgets/ts_mouth_opening.dart';

enum ViewMode { meter, timeseries }

class RecordMouthOpening extends StatefulWidget {
  final bool isBluetoothConnected;

  const RecordMouthOpening({
    super.key,
    required this.isBluetoothConnected,
  });

  @override
  State<RecordMouthOpening> createState() => _RecordMouthOpeningState();
}

class _RecordMouthOpeningState extends State<RecordMouthOpening> {

  /*int? _lastResetSignal;
  int? _lastStartSignal;*/
  ViewMode _viewMode = ViewMode.meter;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('appBox');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Title + buttons =====
          Row(
            children: [
              const Text(
                'Record Mouth Opening',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.speed),
                color: _viewMode == ViewMode.meter
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                onPressed: () => setState(() {
                  _viewMode = ViewMode.meter;
                }),
              ),
              IconButton(
                icon: const Icon(Icons.show_chart),
                color: _viewMode == ViewMode.timeseries
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                onPressed: () => setState(() {
                  _viewMode = ViewMode.timeseries;
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===== METER (fills middle space) =====
          Expanded(
            flex: 3,
            child: _viewMode == ViewMode.meter
                ? ValueListenableBuilder(
                    valueListenable: box.listenable(
                        keys: ['mouth_opening_current_series', 'mouth_opening_max_series', 'mouth_opening_avg_series', 'resetSignal', 'startSignal']),
                    builder: (context, _, __) {
                      /*final int? resetSignal =
                          box.get('resetSignal');
                      final int? startSignal =
                          box.get('startSignal');

                      if (resetSignal != null &&
                          resetSignal != _lastResetSignal) {
                        _lastResetSignal = resetSignal;
                        maxValue = 0;
                      }

                      if (startSignal != null &&
                          startSignal != _lastStartSignal) {
                        _lastStartSignal = startSignal;
                        maxValue = 0;
                      }*/

                      final List currentSeries =
                          List.from(box.get('mouth_opening_current_series', defaultValue: []));

                      final double value =
                          currentSeries.isEmpty ? 0 : (currentSeries.last as num).toDouble();

                      return SizedBox.expand(
                        child: CustomPaint(
                          painter: _SemiGaugePainter(value: value),
                        ),
                      );
                    },
                  )
                : const TsMouthOpening(),
          ),

          const SizedBox(height: 16),

          // ===== METRICS =====
          ValueListenableBuilder(
            valueListenable:
                box.listenable(keys: ['mouth_opening_current_series', 'mouth_opening_avg_series', 'mouth_opening_max_series', 'mouth_opening_max_series', 'resetSignal', 'startSignal']),
            builder: (context, _, __) {
              /*final int? resetSignal =
                  box.get('resetSignal');
              final int? startSignal =
                  box.get('startSignal');

              if (resetSignal != null &&
                  resetSignal != _lastResetSignal) {
                _lastResetSignal = resetSignal;
                maxValue = 0;
              }

              if (startSignal != null &&
                  startSignal != _lastStartSignal) {
                _lastStartSignal = startSignal;
                maxValue = 0;
              }*/
              final List currentSeries =
                  List.from(box.get('mouth_opening_current_series', defaultValue: []));
              final List avgSeries =
                  List.from(box.get('mouth_opening_avg_series', defaultValue: []));
              final List maxSeries =
                  List.from(box.get('mouth_opening_max_series', defaultValue: []));

              final double value =
                  currentSeries.isEmpty ? 0 : (currentSeries.last as num).toDouble();

              final double avg =
                  avgSeries.isEmpty ? 0 : (avgSeries.last as num).toDouble();

              final double maxValue =
                  maxSeries.isEmpty ? 0 : (maxSeries.last as num).toDouble();

              return Column(
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Latest',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Max',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Average',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$value',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$maxValue',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          avg.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'millimeters',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ===== Semi-circle gauge painter =====
class _SemiGaugePainter extends CustomPainter {
  final double value;

  _SemiGaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    final radius = size.width * 0.45;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // ===== Colored arcs =====
    arcPaint.color = Colors.red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi / 3,
      false,
      arcPaint,
    );

    arcPaint.color = Colors.yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + pi / 3,
      pi / 3,
      false,
      arcPaint,
    );

    arcPaint.color = Colors.green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + 2 * pi / 3,
      pi / 3,
      false,
      arcPaint,
    );

    // ===== Tick marks & labels (every 5 mm) =====
    final tickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    for (int step = 0; step <= minorDivisions; step++) {
      final double val =
          gaugeMin + (step / minorDivisions) * (gaugeMax - gaugeMin);

      final double t = (val - gaugeMin) / (gaugeMax - gaugeMin);
      final double angle = pi + t * pi;

      final bool major = step % majorDivisions == 0;

      final double startR = radius * (major ? 0.75 : 0.82);
      final double endR = radius * 0.9;

      final Offset start = Offset(
        center.dx + cos(angle) * startR,
        center.dy + sin(angle) * startR,
      );

      final Offset end = Offset(
        center.dx + cos(angle) * endR,
        center.dy + sin(angle) * endR,
      );

      canvas.drawLine(start, end, tickPaint);

      if (major) {
        final tp = TextPainter(
          text: TextSpan(
            text: val.round().toString(),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final double labelRadius = radius * 0.95;
        final Offset pos = Offset(
          center.dx + cos(angle) * labelRadius - tp.width / 2,
          center.dy + sin(angle) * labelRadius - tp.height / 2,
        );

        tp.paint(canvas, pos);
      }
    }

    // ===== Needle =====
    final double clamped = value.clamp(gaugeMin, gaugeMax).toDouble();
    final double normalized = (clamped - gaugeMin) / (gaugeMax - gaugeMin);
    final double angle = pi + normalized * pi;

    final needlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3;

    final needleEnd = Offset(
      center.dx + cos(angle) * radius * 0.8,
      center.dy + sin(angle) * radius * 0.8,
    );

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(_SemiGaugePainter oldDelegate) =>
      oldDelegate.value != value;
}