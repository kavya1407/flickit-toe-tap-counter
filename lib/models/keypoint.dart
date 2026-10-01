import 'package:flutter/material.dart';

/// Represents a single anatomical landmark detected by YOLO Pose.
class Keypoint {
  final int index;
  final String name;
  final double x;
  final double y;
  final double confidence;

  const Keypoint({
    required this.index,
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });

  /// Location of keypoint as Flutter [Offset].
  Offset get position => Offset(x, y);

  /// Whether the keypoint meets confidence threshold [minConfidence].
  bool isValid(double minConfidence) => confidence >= minConfidence;

  Keypoint copyWith({
    int? index,
    String? name,
    double? x,
    double? y,
    double? confidence,
  }) {
    return Keypoint(
      index: index ?? this.index,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() => '$name(#$index): ($x, $y) conf=${confidence.toStringAsFixed(2)}';
}
