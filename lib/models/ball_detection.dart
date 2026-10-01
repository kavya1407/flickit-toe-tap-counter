import 'package:flutter/material.dart';

/// Represents a detected or tracked football in normalized and screen coordinates.
class BallDetection {
  final Rect boundingBox;
  final Offset center;
  final double radius;
  final double confidence;
  final bool isDetected;
  final bool isCoasted;
  final int lostFrames;

  const BallDetection({
    required this.boundingBox,
    required this.center,
    required this.radius,
    required this.confidence,
    required this.isDetected,
    this.isCoasted = false,
    this.lostFrames = 0,
  });

  factory BallDetection.empty() {
    return const BallDetection(
      boundingBox: Rect.zero,
      center: Offset.zero,
      radius: 0.0,
      confidence: 0.0,
      isDetected: false,
      isCoasted: false,
      lostFrames: 999,
    );
  }

  /// Contact zone: upper hemisphere region of the ball where a toe tap occurs.
  Rect get topContactZone {
    return Rect.fromLTWH(
      center.dx - radius * 0.9,
      center.dy - radius * 1.1,
      radius * 1.8,
      radius * 1.2,
    );
  }

  BallDetection copyWith({
    Rect? boundingBox,
    Offset? center,
    double? radius,
    double? confidence,
    bool? isDetected,
    bool? isCoasted,
    int? lostFrames,
  }) {
    return BallDetection(
      boundingBox: boundingBox ?? this.boundingBox,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      confidence: confidence ?? this.confidence,
      isDetected: isDetected ?? this.isDetected,
      isCoasted: isCoasted ?? this.isCoasted,
      lostFrames: lostFrames ?? this.lostFrames,
    );
  }
}
