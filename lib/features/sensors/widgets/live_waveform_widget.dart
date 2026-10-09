import 'package:flutter/material.dart';

class LiveWaveformPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool showFill;
  final double? minY;
  final double? maxY;

  LiveWaveformPainter({
    required this.values,
    required this.color,
    this.strokeWidth = 2.0,
    this.showFill = true,
    this.minY,
    this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final isAllZero = values.every((v) => v.abs() < 0.0001);

    if (isAllZero) {
      // Draw a perfect straight horizontal line across the center/baseline
      final y = size.height / 2;
      final strokePaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), strokePaint);

      // Draw subtle straight baseline fill if enabled
      if (showFill) {
        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, y, size.width, size.height - y))
          ..style = PaintingStyle.fill;

        final fillPath = Path()
          ..moveTo(0, y)
          ..lineTo(size.width, y)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(fillPath, fillPaint);
      }

      // Draw terminal lead dot on the straight line
      final leadPaint = Paint()..color = color;
      canvas.drawCircle(Offset(size.width, y), strokeWidth * 1.5, leadPaint);
      return;
    }

    double calculatedMin = minY ?? values.reduce((a, b) => a < b ? a : b);
    double calculatedMax = maxY ?? values.reduce((a, b) => a > b ? a : b);
    if ((calculatedMax - calculatedMin).abs() < 0.001) {
      calculatedMax += 1.0;
      calculatedMin -= 1.0;
    }

    final path = Path();
    final fillPath = Path();

    final dx = size.width / (values.length - 1 > 0 ? values.length - 1 : 1);

    for (int i = 0; i < values.length; i++) {
      final normalizedY = (values[i] - calculatedMin) / (calculatedMax - calculatedMin);
      final y = size.height - (normalizedY.clamp(0.0, 1.0) * size.height);
      final x = i * dx;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    if (showFill) {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Draw lead point at head of stream
    if (values.isNotEmpty) {
      final lastVal = values.last;
      final normalizedY = (lastVal - calculatedMin) / (calculatedMax - calculatedMin);
      final y = size.height - (normalizedY.clamp(0.0, 1.0) * size.height);
      final leadOffset = Offset(size.width, y);

      final leadPaint = Paint()..color = color;
      canvas.drawCircle(leadOffset, strokeWidth * 1.5, leadPaint);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(leadOffset, strokeWidth * 2.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LiveWaveformPainter oldDelegate) {
    return true; // Continuously update with high-speed sensor stream
  }
}

class LiveWaveformWidget extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;
  final double strokeWidth;
  final double? minY;
  final double? maxY;
  final bool showFill;

  const LiveWaveformWidget({
    super.key,
    required this.values,
    required this.color,
    this.height = 65,
    this.strokeWidth = 2.0,
    this.minY,
    this.maxY,
    this.showFill = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: LiveWaveformPainter(
          values: values,
          color: color,
          strokeWidth: strokeWidth,
          minY: minY,
          maxY: maxY,
          showFill: showFill,
        ),
      ),
    );
  }
}
