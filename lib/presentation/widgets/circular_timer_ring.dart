import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/monotonic_time.dart';

/// Animated circular monotonic progress ring displaying remaining hours, minutes, and seconds.
class CircularTimerRing extends StatelessWidget {
  final int totalDurationSeconds;
  final int remainingSeconds;
  final double size;
  final Color primaryColor;
  final Color trackColor;
  final String? subtitle;

  const CircularTimerRing({
    super.key,
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    this.size = 260,
    this.primaryColor = AppConstants.primary,
    this.trackColor = AppConstants.darkCard,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final progress = MonotonicTime.calculateProgress(
      totalDurationSeconds: totalDurationSeconds,
      remainingSeconds: remainingSeconds,
    );
    final timeFormatted = MonotonicTime.formatRemainingTime(remainingSeconds);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              primaryColor: primaryColor,
              trackColor: trackColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeFormatted,
                style: TextStyle(
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle ?? '${(progress * 100).toInt()}% completed',
                style: TextStyle(
                  fontSize: size * 0.055,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textSecondaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          primaryColor,
          AppConstants.accent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}
