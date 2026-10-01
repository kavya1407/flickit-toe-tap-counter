import 'package:flutter/material.dart';

/// Application-wide constants for model inference, camera stream,
/// computer vision thresholds, and state machine tuning.
class AppConstants {
  AppConstants._();

  // App Meta
  static const String appTitle = 'Flickit Toe Tap Counter';
  static const String appVersion = '1.0.0';

  // Assets
  static const String modelAssetPath = 'assets/models/yolov8n-pose.tflite';
  static const String labelsAssetPath = 'assets/models/coco_pose_labels.txt';

  // Model Input Dimensions
  static const int modelInputWidth = 640;
  static const int modelInputHeight = 640;
  static const int numKeypoints = 17;

  // Confidence Thresholds
  static const double minPersonConfidence = 0.45;
  static const double minKeypointConfidence = 0.35;
  static const double minBallConfidence = 0.40;
  static const double nmsIouThreshold = 0.45;

  // Toe Tap Detection Physics & FSM Tunings
  /// Contact distance multiplier relative to the ball radius.
  /// If foot-to-ball distance <= radius * contactRadiusMultiplier, contact is declared.
  static const double defaultContactMultiplier = 1.25;

  /// Hysteresis separation multiplier.
  /// Foot must retract beyond radius * separationMultiplier to reset the tap state.
  static const double defaultSeparationMultiplier = 1.65;

  /// Foot height fraction: estimate toe tip below ankle using ankle-knee vector.
  static const double toeAnkleOffsetRatio = 0.20;

  /// Frame debounce: minimum frames between consecutive taps to prevent duplicate triggers.
  static const int minFramesBetweenTaps = 5;

  /// Time debounce (milliseconds).
  static const int tapCooldownMs = 180;

  /// Maximum consecutive frames to coast/interpolate ball position during temporary occlusion.
  static const int maxBallCoastFrames = 6;

  // Keypoint Indices (COCO 17 Keypoints)
  static const int kpNose = 0;
  static const int kpLeftEye = 1;
  static const int kpRightEye = 2;
  static const int kpLeftEar = 3;
  static const int kpRightEar = 4;
  static const int kpLeftShoulder = 5;
  static const int kpRightShoulder = 6;
  static const int kpLeftElbow = 7;
  static const int kpRightElbow = 8;
  static const int kpLeftWrist = 9;
  static const int kpRightWrist = 10;
  static const int kpLeftHip = 11;
  static const int kpRightHip = 12;
  static const int kpLeftKnee = 13;
  static const int kpRightKnee = 14;
  static const int kpLeftAnkle = 15;
  static const int kpRightAnkle = 16;

  // Skeleton connection pairs for drawing
  static const List<List<int>> skeletonPairs = [
    // Head
    [kpNose, kpLeftEye],
    [kpNose, kpRightEye],
    [kpLeftEye, kpLeftEar],
    [kpRightEye, kpRightEar],
    // Torso
    [kpLeftShoulder, kpRightShoulder],
    [kpLeftShoulder, kpLeftHip],
    [kpRightShoulder, kpRightHip],
    [kpLeftHip, kpRightHip],
    // Arms
    [kpLeftShoulder, kpLeftElbow],
    [kpLeftElbow, kpLeftWrist],
    [kpRightShoulder, kpRightElbow],
    [kpRightElbow, kpRightWrist],
    // Legs
    [kpLeftHip, kpLeftKnee],
    [kpLeftKnee, kpLeftAnkle],
    [kpRightHip, kpRightKnee],
    [kpRightKnee, kpRightAnkle],
  ];

  // Theme Colors
  static const Color primaryNeon = Color(0xFF00E676); // Athletic electric green
  static const Color secondaryNeon = Color(0xFF00B0FF); // Electric blue
  static const Color accentOrange = Color(0xFFFF9100); // Football orange
  static const Color dangerRed = Color(0xFFFF5252);
  static const Color darkBackground = Color(0xFF101216);
  static const Color cardBackground = Color(0xFF1E222B);
  static const Color hudOverlayBg = Color(0xCC0D0F14);
}
