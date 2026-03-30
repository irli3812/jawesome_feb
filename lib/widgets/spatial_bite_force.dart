// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';

class SpatialBiteForce extends StatelessWidget {
  const SpatialBiteForce({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('appBox');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            const Text(
              'Colored Force-Map',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ValueListenableBuilder(
                valueListenable: box.listenable(keys: ['session']),
                builder: (context, Box box, _) {
                  final List session = List.from(
                    box.get('session', defaultValue: []),
                  );

                  final List<double> values = List.generate(20, (i) {
                    if (session.isEmpty) return 0.0;

                    final row = session.last;
                    List bites = [];

                    if (row['bites'] != null) {
                      bites = List.from(row['bites']);
                    }

                    if (bites.length > i) {
                      return (bites[i] as num).toDouble();
                    }

                    return 0.0;
                  });

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildArch(values.sublist(0, 10), isTop: true),
                      const SizedBox(height: 12),
                      _buildLegend(context),
                      const SizedBox(height: 12),
                      _buildArch(values.sublist(10, 20), isTop: false),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.orange, Colors.green],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              bfGaugeMin.toStringAsFixed(0),
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              ((bfGaugeMin + bfGaugeMax) / 2).toStringAsFixed(0),
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              '${bfGaugeMax.toStringAsFixed(0)} N',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }

  // ===== ARCH BUILDER (ELLIPTICAL TOUCHING BOXES - NO OVERLAP) =====
  Widget _buildArch(List<double> vals, {required bool isTop}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing based on available width
        final availableWidth = constraints.maxWidth;
        final boxWidth = (availableWidth / vals.length).clamp(40.0, 65.0);
        final boxHeight = boxWidth * 1.55; // maintain aspect ratio
        final spacing = max(1.0, boxWidth * 0.03); // scale spacing proportionally
        final radiusY = boxHeight * 0.82; // scale curve height proportionally

        return SizedBox(
          height: radiusY + boxHeight,
          child: LayoutBuilder(
            builder: (context, innerConstraints) {
              final totalWidth = vals.length * (boxWidth + spacing);
              final startX = (innerConstraints.maxWidth - totalWidth) / 2;

              return Stack(
                children: List.generate(vals.length, (i) {
                  final x = startX + i * (boxWidth + spacing);

                  final centerX = innerConstraints.maxWidth / 2;
                  final dx = (x + boxWidth / 2 - centerX) / (totalWidth / 2);

                  final ellipseY = sqrt(max(0, 1 - dx * dx)) * radiusY;

                  final y = isTop ? radiusY - ellipseY : ellipseY;

                  return Positioned(
                    left: x,
                    top: y,
                    child: _buildBox(i, vals[i], isTop, boxWidth, boxHeight),
                  );
                }),
              );
            },
          ),);
        },
      );
  }

  // ===== SINGLE SENSOR BOX =====
  Widget _buildBox(int index, double value, bool isTop, double boxWidth, double boxHeight) {
    final sensorNumber = isTop ? index + 1 : index + 11;

    final color = _valueToColor(value);
    const textColor = Colors.white;

    // Scale text sizes based on box dimensions
    final sensorFontSize = (boxWidth * 0.33).clamp(14.0, 24.0);
    final valueFontSize = (boxWidth * 0.44).clamp(18.0, 32.0);
    final unitFontSize = (boxWidth * 0.16).clamp(10.0, 14.0);

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: Colors.grey.shade300, end: color),
      duration: const Duration(milliseconds: 300),
      builder: (context, animatedColor, _) {
        return Container(
          width: boxWidth,
          height: boxHeight,
          decoration: BoxDecoration(
            color: animatedColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$sensorNumber',
                style: TextStyle(
                  fontSize: sensorFontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'N',
                style: TextStyle(
                  fontSize: unitFontSize,
                  color: textColor.withOpacity(0.85),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== COLOR SCALE =====
  Color _valueToColor(double value) {
    final normalized = ((value - bfGaugeMin) / (bfGaugeMax - bfGaugeMin)).clamp(
      0.0,
      1.0,
    );

    if (normalized < 0.5) {
      final t = normalized / 0.5;
      return Color.lerp(Colors.blue, Colors.orange, t)!;
    } else {
      final t = (normalized - 0.5) / 0.5;
      return Color.lerp(Colors.orange, Colors.green, t)!;
    }
  }
}
