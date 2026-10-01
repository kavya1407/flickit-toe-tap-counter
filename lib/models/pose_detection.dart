import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/math_utils.dart';
import 'keypoint.dart';

/// Encapsulates the detected person, bounding box, and 17 pose keypoints.
class PoseDetection {
  final Rect boundingBox;
  final double confidence;
  final List<Keypoint> keypoints;
  final bool personDetected;

  const PoseDetection({
    required this.boundingBox,
    required this.confidence,
    required this.keypoints,
    required this.personDetected,
  });

  /// Factory for empty / no detection state.
  factory PoseDetection.empty() {
    return const PoseDetection(
      boundingBox: Rect.zero,
      confidence: 0.0,
      keypoints: [],
      personDetected: false,
    );
  }

  /// Safe lookup for a specific keypoint index.
  Keypoint? getKeypoint(int index) {
    if (index >= 0 && index < keypoints.length) {
      return keypoints[index];
    }
    return null;
  }

  // Keypoint Getters
  Keypoint? get leftHip => getKeypoint(AppConstants.kpLeftHip);
  Keypoint? get rightHip => getKeypoint(AppConstants.kpRightHip);
  Keypoint? get leftKnee => getKeypoint(AppConstants.kpLeftKnee);
  Keypoint? get rightKnee => getKeypoint(AppConstants.kpRightKnee);
  Keypoint? get leftAnkle => getKeypoint(AppConstants.kpLeftAnkle);
  Keypoint? get rightAnkle => getKeypoint(AppConstants.kpRightAnkle);

  /// Estimates the left toe position using left knee and left ankle coordinates.
  Offset? get estimatedLeftToe {
    final knee = leftKnee;
    final ankle = leftAnkle;
    if (knee == null || ankle == null) return null;
    if (ankle.confidence < AppConstants.minKeypointConfidence) return null;

    return MathUtils.estimateToePosition(
      knee: knee.position,
      ankle: ankle.position,
      footLengthRatio: AppConstants.toeAnkleOffsetRatio,
    );
  }

  /// Estimates the right toe position using right knee and right ankle coordinates.
  Offset? get estimatedRightToe {
    final knee = rightKnee;
    final ankle = rightAnkle;
    if (knee == null || ankle == null) return null;
    if (ankle.confidence < AppConstants.minKeypointConfidence) return null;

    return MathUtils.estimateToePosition(
      knee: knee.position,
      ankle: ankle.position,
      footLengthRatio: AppConstants.toeAnkleOffsetRatio,
    );
  }
}
