import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Computational geometry and signal smoothing utilities for computer vision.
class MathUtils {
  MathUtils._();

  /// Calculates the Euclidean distance between two 2D points.
  static double euclideanDistance(Offset p1, Offset p2) {
    final dx = p1.dx - p2.dx;
    final dy = p1.dy - p2.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculates the squared Euclidean distance (faster when comparing thresholds).
  static double distanceSquared(Offset p1, Offset p2) {
    final dx = p1.dx - p2.dx;
    final dy = p1.dy - p2.dy;
    return dx * dx + dy * dy;
  }

  /// Estimates the toe location given knee and ankle coordinates.
  /// Uses anatomical proportions: foot length is approximately 15-20% of shank length.
  static Offset estimateToePosition({
    required Offset knee,
    required Offset ankle,
    double footLengthRatio = 0.22,
  }) {
    final shankVector = ankle - knee;
    final shankLength = shankVector.distance;

    if (shankLength < 1e-4) {
      // Degenerate case: offset slightly downward
      return Offset(ankle.dx, ankle.dy + 15.0);
    }

    final unitShank = Offset(shankVector.dx / shankLength, shankVector.dy / shankLength);
    final footLength = shankLength * footLengthRatio;

    // The foot projects forward/downward along the shank axis with gravity bias
    return Offset(
      ankle.dx + unitShank.dx * (footLength * 0.7),
      ankle.dy + math.max(0.0, unitShank.dy) * footLength + (footLength * 0.3),
    );
  }

  /// Computes Intersection-over-Union (IoU) of two bounding boxes [Rect].
  static double calculateIoU(Rect a, Rect b) {
    final intersection = a.intersect(b);
    if (intersection.width <= 0 || intersection.height <= 0) return 0.0;

    final intersectionArea = intersection.width * intersection.height;
    final unionArea = (a.width * a.height) + (b.width * b.height) - intersectionArea;

    if (unionArea <= 0) return 0.0;
    return intersectionArea / unionArea;
  }

  /// Exponential Moving Average (EMA) smoothing for continuous 2D tracking.
  /// [alpha] ranges from 0.0 (keep history) to 1.0 (raw measurement).
  static Offset applyEma(Offset previous, Offset current, double alpha) {
    final clampedAlpha = alpha.clamp(0.0, 1.0);
    final x = (clampedAlpha * current.dx) + ((1.0 - clampedAlpha) * previous.dx);
    final y = (clampedAlpha * current.dy) + ((1.0 - clampedAlpha) * previous.dy);
    return Offset(x, y);
  }

  /// Linear interpolation (lerp) between two numbers.
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }

  /// Clamp a value within an inclusive range [min, max].
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Sigmoid activation for raw logit conversion.
  static double sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }
}
