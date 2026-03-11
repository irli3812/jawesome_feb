// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';

class TsBiteForce extends StatelessWidget {
  const TsBiteForce({super.key});

  static const double windowMs = 5000;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('appBox');

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['session']),
      builder: (context, Box box, _) {
        final List session = List.from(box.get('session', defaultValue: []));

        if (session.isEmpty) {
          return const Center(
            child: Text(
              "Waiting for data...",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final List<Offset> allPoints = [];
        final List<Offset> avgPoints = [];

        for (final row in session) {
          final int time = (row['time_ms'] ?? 0) as int;

          double b1 = 0;
          double avg = 0;

          if (row['bites'] != null) {
            final List bites = List.from(row['bites']);
            if (bites.isNotEmpty) {
              b1 = (bites[0] as num).toDouble();
            }
          }

          if (row['avg_bite_force'] != null) {
            avg = (row['avg_bite_force'] as num).toDouble();
          }

          allPoints.add(Offset(time.toDouble(), b1));
          avgPoints.add(Offset(time.toDouble(), avg));
        }

        final double latestTime = allPoints.isNotEmpty ? allPoints.last.dx : 0;

        final double minTime = (latestTime - windowMs).clamp(
          0,
          double.infinity,
        );

        final List<Offset> points = allPoints
            .where((p) => p.dx >= minTime)
            .toList();
        final List<Offset> avgFiltered = avgPoints
            .where((p) => p.dx >= minTime)
            .toList();

        return CustomPaint(
          painter: _TsBiteForcePainter(
            bitePoints: points,
            avgPoints: avgFiltered,
            minTime: minTime,
            latestTime: latestTime,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _TsBiteForcePainter extends CustomPainter {
  final List<Offset> bitePoints;
  final List<Offset> avgPoints;
  final double minTime;
  final double latestTime;

  const _TsBiteForcePainter({
    required this.bitePoints,
    required this.avgPoints,
    required this.minTime,
    required this.latestTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad = 45;
    const double rightPad = 10;
    const double topPad = 10;
    // leave more room for x-axis tick labels
    const double bottomPad = 45;

    final double width = size.width - leftPad - rightPad;
    final double height = size.height - topPad - bottomPad;

    final Offset origin = Offset(leftPad, size.height - bottomPad);

    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final avgPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    /// AXES

    canvas.drawLine(
      origin,
      Offset(size.width - rightPad, origin.dy),
      axisPaint,
    );

    canvas.drawLine(origin, Offset(origin.dx, topPad), axisPaint);

    /// X GRID + LABELS (every 0.5 seconds)

    const double stepMs = 500;

    double firstXTick = (minTime / stepMs).ceil() * stepMs;

    for (double t = firstXTick; t <= latestTime; t += stepMs) {
      final double norm = (t - minTime) / TsBiteForce.windowMs;

      if (norm < 0 || norm > 1) continue;

      final double x = origin.dx + norm * width;

      canvas.drawLine(Offset(x, origin.dy), Offset(x, topPad), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '${(t / 1000).toStringAsFixed(1)} s',
          style: const TextStyle(fontSize: 10, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(x - tp.width / 2, origin.dy + 4));
    }

    // draw x-axis title
    const String xLabel = 'Time (s)';
    final TextPainter xTp = TextPainter(
      text: const TextSpan(
        text: xLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xTp.paint(
      canvas,
      Offset(origin.dx + width / 2 - xTp.width / 2, origin.dy + 25),
    );

    /// Y GRID + LABELS (every 10 units)

    const double stepForce = 10;

    double firstYTick = (bfGaugeMin / stepForce).ceil() * stepForce;

    for (double v = firstYTick; v <= bfGaugeMax; v += stepForce) {
      final double norm = (v - bfGaugeMin) / (bfGaugeMax - bfGaugeMin);

      final double y = origin.dy - norm * height;

      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${v.toInt()} N',
          style: const TextStyle(fontSize: 10, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // position label just left of axis, inside leftPad
      tp.paint(canvas, Offset(origin.dx - tp.width - 4, y - tp.height / 2));
    }

    // draw y-axis title
    const String yLabel = 'Force (N)';
    final TextPainter yTp = TextPainter(
      text: const TextSpan(
        text: yLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    // position at vertical center left of axis with extra offset
    canvas.translate(leftPad / 2 - 15, origin.dy - height / 2);
    canvas.rotate(-3.14159 / 2);
    yTp.paint(canvas, Offset(-yTp.width / 2, -yTp.height / 2));
    canvas.restore();

    /// LEGEND
    // top-right corner, small swatches
    final double legendX = size.width - rightPad - 100;
    final double legendY = topPad + 5;
    const double sw = 12;
    // packet bite force
    canvas.drawLine(
      Offset(legendX, legendY + sw / 2),
      Offset(legendX + sw, legendY + sw / 2),
      linePaint,
    );
    final TextPainter legend1 = TextPainter(
      text: const TextSpan(
        text: ' packet',
        style: TextStyle(fontSize: 10, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    legend1.paint(canvas, Offset(legendX + sw + 4, legendY));
    // average (dashed)
    final Path legendAvgPath = Path()
      ..moveTo(legendX, legendY + sw + 16)
      ..lineTo(legendX + sw, legendY + sw + 16);
    _drawDashedPath(canvas, legendAvgPath, avgPaint);
    final TextPainter legend2 = TextPainter(
      text: const TextSpan(
        text: ' average',
        style: TextStyle(fontSize: 10, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    legend2.paint(canvas, Offset(legendX + sw + 4, legendY + sw + 12));

    /// SCALE FUNCTION

    Offset scalePoint(Offset p) {
      final double x =
          origin.dx + ((p.dx - minTime) / TsBiteForce.windowMs) * width;

      final double y =
          origin.dy -
          ((p.dy - bfGaugeMin) / (bfGaugeMax - bfGaugeMin)) * height;

      return Offset(x, y);
    }

    /// DATA LINES

    if (bitePoints.isNotEmpty) {
      final path = Path();
      final first = scalePoint(bitePoints.first);
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < bitePoints.length; i++) {
        final scaled = scalePoint(bitePoints[i]);
        path.lineTo(scaled.dx, scaled.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    if (avgPoints.isNotEmpty) {
      final path2 = Path();
      final first = scalePoint(avgPoints.first);
      path2.moveTo(first.dx, first.dy);
      for (int i = 1; i < avgPoints.length; i++) {
        final scaled = scalePoint(avgPoints[i]);
        path2.lineTo(scaled.dx, scaled.dy);
      }
      // draw dashed average line
      _drawDashedPath(canvas, path2, avgPaint);
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path original,
    Paint paint, {
    double dashWidth = 5,
    double gapWidth = 3,
  }) {
    for (final metric in original.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        final Path segment = metric.extractPath(
          distance,
          next.clamp(0.0, metric.length),
        );
        canvas.drawPath(segment, paint);
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(_TsBiteForcePainter oldDelegate) {
    return true;
  }
}
