// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';

class SpatialBiteForce extends StatelessWidget {
  const SpatialBiteForce({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('appBox');

    return Column(
      children: [
        const SizedBox(height: 12),

        // ===== Title =====
        const Text(
          'Colored Force-Map',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 20),

        // ===== FORCE MAP =====
        ValueListenableBuilder(
          valueListenable: box.listenable(keys: ['session']),
          builder: (context, Box box, _) {
            final List session =
                List.from(box.get('session', defaultValue: []));

            final List<double> sensorValues = List.generate(10, (i) {
              if (session.isEmpty) return 0.0;

              final row = session.last;
              List bites = [];

              if (row['bites'] != null) {
                bites = List.from(row['bites']);
              }

              final int s = i + 1;

              double v1 = 0;
              double v2 = 0;

              if (bites.length > (s - 1)) {
                v1 = (bites[s - 1] as num).toDouble();
              }

              if (bites.length > (s + 9)) {
                v2 = (bites[s + 9] as num).toDouble();
              }

              return (v1 + v2) / 2.0;
            });

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: List.generate(10, (i) {
                  final value = sensorValues[i];
                  final color = _valueToColor(value);

                  /*final textColor =
                      ThemeData.estimateBrightnessForColor(color) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black;*/
                  final textColor = Colors.white;

                  return Expanded(
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                        begin: Colors.grey.shade300,
                        end: color,
                      ),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, animatedColor, _) {
                        return Container(
                          height: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: animatedColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ===== SENSOR LABEL =====
                              Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // ===== VALUE =====
                              Text(
                                value.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),

                              const SizedBox(height: 2),

                              // ===== UNIT =====
                              Text(
                                'lbf',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            );
          },
        ),

        const SizedBox(height: 18),

        // ===== COLOR LEGEND =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.blue,
                      Colors.orange,
                      Colors.green,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    '${bfGaugeMax.toStringAsFixed(0)} lbf',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ===== TEETH IMAGE =====
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Image.asset(
              'lib/images/b&w_teeth_anatomy.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  /// ===== Color scale =====
  Color _valueToColor(double value) {
    final normalized =
        ((value - bfGaugeMin) / (bfGaugeMax - bfGaugeMin))
            .clamp(0.0, 1.0);

    if (normalized < 0.5) {
      final t = normalized / 0.5;
      return Color.lerp(Colors.blue, Colors.orange, t)!;
    } else {
      final t = (normalized - 0.5) / 0.5;
      return Color.lerp(Colors.orange, Colors.green, t)!;
    }
  }
}