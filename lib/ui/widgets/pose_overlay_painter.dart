import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/ball_detection.dart';
import '../../models/pose_detection.dart';
import '../../models/tap_event.dart';

/// Renders real-time visual skeleton, keypoints, football bounding ring,
/// contact threshold boundaries, and contact impact animations.
class PoseOverlayPainter extends CustomPainter {
  final PoseDetection pose;
  final BallDetection ball;
  final TapEvent? latestTap;
  final TapPhase leftPhase;
  final TapPhase rightPhase;
  final bool showDebug;

  PoseOverlayPainter({
    required this.pose,
    required this.ball,
    required this.latestTap,
    required this.leftPhase,
    required this.rightPhase,
    this.showDebug = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showDebug && ball.isDetected) {
      _drawBall(canvas, size);
    }

    if (pose.personDetected) {
      _drawSkeleton(canvas);
      _drawKeypoints(canvas);
      _drawEstimatedToes(canvas);
    }

    if (latestTap != null) {
      _drawTapImpact(canvas);
    }
  }

  void _drawBall(Canvas canvas, Size size) {
    final center = ball.center;
    final radius = ball.radius;

    // Outer Glow / Contact Boundary
    final contactPaint = Paint()
      ..color = ball.isCoasted
          ? AppConstants.accentOrange.withOpacity(0.4)
          : AppConstants.secondaryNeon.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius * AppConstants.defaultContactMultiplier, contactPaint);

    // Ball Perimeter Circle
    final ballBorderPaint = Paint()
      ..color = ball.isCoasted ? AppConstants.accentOrange : AppConstants.secondaryNeon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    canvas.drawCircle(center, radius, ballBorderPaint);

    // Ball Center Reticle
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.0, centerDotPaint);

    // Top Contact Zone Arc (where toe tap must happen)
    final arcPaint = Paint()
      ..color = AppConstants.primaryNeon
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      arcPaint,
    );

    // Ball Label / Status Badge
    final textSpan = TextSpan(
      text: ball.isCoasted ? '⚽ BALL (COASTED)' : '⚽ FOOTBALL',
      style: TextStyle(
        color: ball.isCoasted ? AppConstants.accentOrange : AppConstants.secondaryNeon,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black87,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - radius, center.dy - radius - 18));
  }

  void _drawSkeleton(Canvas canvas) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final legHighlightPaint = Paint()
      ..color = AppConstants.primaryNeon.withOpacity(0.85)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    for (final pair in AppConstants.skeletonPairs) {
      final p1 = pose.getKeypoint(pair[0]);
      final p2 = pose.getKeypoint(pair[1]);

      if (p1 != null && p2 != null &&
          p1.confidence >= AppConstants.minKeypointConfidence &&
          p2.confidence >= AppConstants.minKeypointConfidence) {
        // Highlight lower leg bones leading to foot
        final isLowerLeg = (pair[0] == AppConstants.kpLeftKnee && pair[1] == AppConstants.kpLeftAnkle) ||
            (pair[0] == AppConstants.kpRightKnee && pair[1] == AppConstants.kpRightAnkle);

        canvas.drawLine(
          p1.position,
          p2.position,
          isLowerLeg ? legHighlightPaint : linePaint,
        );
      }
    }
  }

  void _drawKeypoints(Canvas canvas) {
    final pointPaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0;

    for (final kp in pose.keypoints) {
      if (kp.confidence < AppConstants.minKeypointConfidence) continue;

      final isAnkle = kp.index == AppConstants.kpLeftAnkle || kp.index == AppConstants.kpRightAnkle;
      final isKnee = kp.index == AppConstants.kpLeftKnee || kp.index == AppConstants.kpRightKnee;

      if (isAnkle) {
        pointPaint.color = AppConstants.primaryNeon;
        glowPaint.color = Colors.white;
        canvas.drawCircle(kp.position, 6.0, pointPaint);
        canvas.drawCircle(kp.position, 8.0, glowPaint);
      } else if (isKnee) {
        pointPaint.color = AppConstants.secondaryNeon;
        canvas.drawCircle(kp.position, 5.0, pointPaint);
      } else {
        pointPaint.color = Colors.white70;
        canvas.drawCircle(kp.position, 3.5, pointPaint);
      }
    }
  }

  void _drawEstimatedToes(Canvas canvas) {
    final leftToe = pose.estimatedLeftToe;
    final rightToe = pose.estimatedRightToe;

    final toePaint = Paint()..style = PaintingStyle.fill;

    if (leftToe != null) {
      toePaint.color = leftPhase == TapPhase.contact
          ? AppConstants.primaryNeon
          : leftPhase == TapPhase.approaching
              ? AppConstants.accentOrange
              : AppConstants.secondaryNeon;
      canvas.drawCircle(leftToe, 7.5, toePaint);
      _drawFootLabel(canvas, leftToe, 'L-TOE', toePaint.color);
    }

    if (rightToe != null) {
      toePaint.color = rightPhase == TapPhase.contact
          ? AppConstants.primaryNeon
          : rightPhase == TapPhase.approaching
              ? AppConstants.accentOrange
              : AppConstants.secondaryNeon;
      canvas.drawCircle(rightToe, 7.5, toePaint);
      _drawFootLabel(canvas, rightToe, 'R-TOE', toePaint.color);
    }
  }

  void _drawFootLabel(Canvas canvas, Offset pos, String text, Color color) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(pos.dx - 12, pos.dy + 8));
  }

  void _drawTapImpact(Canvas canvas) {
    final impactTime = DateTime.now().difference(latestTap!.timestamp).inMilliseconds;
    if (impactTime > 400) return; // Impact effect lasts 400ms

    final double progress = impactTime / 400.0;
    final double radius = 10.0 + (progress * 45.0);
    final double opacity = (1.0 - progress).clamp(0.0, 1.0);

    final impactRingPaint = Paint()
      ..color = AppConstants.primaryNeon.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * (1.0 - progress);

    canvas.drawCircle(latestTap!.contactPoint, radius, impactRingPaint);
  }

  @override
  bool shouldRepaint(covariant PoseOverlayPainter oldDelegate) => true;
}
