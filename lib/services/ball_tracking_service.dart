import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/math_utils.dart';
import '../models/ball_detection.dart';

/// Robust ball tracking service with temporal smoothing, dropout coasting,
/// and occlusion tolerance.
class BallTrackingService {
  BallDetection _currentBall = BallDetection.empty();
  Offset? _smoothedCenter;
  double _smoothedRadius = 0.0;
  int _consecutiveLostFrames = 0;
  final int maxCoastFrames;

  BallTrackingService({
    this.maxCoastFrames = AppConstants.maxBallCoastFrames,
  });

  BallDetection get currentBall => _currentBall;
  bool get hasValidBall => _currentBall.isDetected;

  /// Updates the tracking filter with a new raw detection candidate (or null if missed).
  BallDetection update({
    required BallDetection? rawDetection,
    required Size previewSize,
    double smoothingAlpha = 0.65,
  }) {
    if (rawDetection != null && rawDetection.isDetected) {
      _consecutiveLostFrames = 0;

      if (_smoothedCenter == null) {
        _smoothedCenter = rawDetection.center;
        _smoothedRadius = rawDetection.radius;
      } else {
        // Apply exponential moving average to filter jitter
        _smoothedCenter = MathUtils.applyEma(
          _smoothedCenter!,
          rawDetection.center,
          smoothingAlpha,
        );
        _smoothedRadius = MathUtils.lerp(
          _smoothedRadius,
          rawDetection.radius,
          smoothingAlpha,
        );
      }

      _currentBall = BallDetection(
        boundingBox: Rect.fromCenter(
          center: _smoothedCenter!,
          width: _smoothedRadius * 2,
          height: _smoothedRadius * 2,
        ),
        center: _smoothedCenter!,
        radius: _smoothedRadius,
        confidence: rawDetection.confidence,
        isDetected: true,
        isCoasted: false,
        lostFrames: 0,
      );

      return _currentBall;
    }

    // Raw detection is null or dropped: Check if we can coast across occlusions
    if (_smoothedCenter != null && _consecutiveLostFrames < maxCoastFrames) {
      _consecutiveLostFrames++;

      // Extrapolate position with slight confidence decay
      final double decayedConfidence = math.max(
        0.1,
        _currentBall.confidence * (1.0 - (_consecutiveLostFrames / maxCoastFrames) * 0.5),
      );

      _currentBall = BallDetection(
        boundingBox: Rect.fromCenter(
          center: _smoothedCenter!,
          width: _smoothedRadius * 2,
          height: _smoothedRadius * 2,
        ),
        center: _smoothedCenter!,
        radius: _smoothedRadius,
        confidence: decayedConfidence,
        isDetected: true,
        isCoasted: true, // Marked as coasted
        lostFrames: _consecutiveLostFrames,
      );

      return _currentBall;
    }

    // Lost tracking entirely
    _consecutiveLostFrames++;
    _smoothedCenter = null;
    _smoothedRadius = 0.0;
    _currentBall = BallDetection.empty();
    return _currentBall;
  }

  /// Manually anchors the ball position (e.g. user taps on the ball in camera preview).
  void anchorBall(Offset screenPosition, double radius) {
    _smoothedCenter = screenPosition;
    _smoothedRadius = radius;
    _consecutiveLostFrames = 0;
    _currentBall = BallDetection(
      boundingBox: Rect.fromCenter(
        center: screenPosition,
        width: radius * 2,
        height: radius * 2,
      ),
      center: screenPosition,
      radius: radius,
      confidence: 1.0,
      isDetected: true,
      isCoasted: false,
      lostFrames: 0,
    );
  }

  /// Resets tracking state.
  void reset() {
    _smoothedCenter = null;
    _smoothedRadius = 0.0;
    _consecutiveLostFrames = 0;
    _currentBall = BallDetection.empty();
  }
}
