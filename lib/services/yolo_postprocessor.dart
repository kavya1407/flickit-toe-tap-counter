import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/keypoint.dart';
import '../models/pose_detection.dart';
import '../models/ball_detection.dart';

/// Post-processor for Ultralytics YOLO Pose raw output tensors.
///
/// Decodes the [1, 56, 8400] output tensor:
/// - Channels 0..3: Bounding box (cx, cy, w, h)
/// - Channel 4: Person class confidence
/// - Channels 5..55: 17 keypoints * 3 (x, y, confidence)
class YoloPostprocessor {
  final List<String> keypointLabels;

  YoloPostprocessor({List<String>? labels})
      : keypointLabels = labels ?? _defaultLabels;

  static const List<String> _defaultLabels = [
    'nose', 'left_eye', 'right_eye', 'left_ear', 'right_ear',
    'left_shoulder', 'right_shoulder', 'left_elbow', 'right_elbow',
    'left_wrist', 'right_wrist', 'left_hip', 'right_hip',
    'left_knee', 'right_knee', 'left_ankle', 'right_ankle'
  ];

  /// Parses raw float array or nested list output from TFLite interpreter.
  ///
  /// [rawOutput]: Expects tensor of shape [1, 56, 8400] or transposed [1, 8400, 56].
  /// [previewSize]: Actual size of the camera preview widget.
  /// [modelInputSize]: Model input resolution (default 640x640).
  PoseDetection decodePose({
    required dynamic rawOutput,
    required Size previewSize,
    Size modelInputSize = const Size(640, 640),
    double minConfidence = AppConstants.minPersonConfidence,
    double minKpConfidence = AppConstants.minKeypointConfidence,
  }) {
    // Determine tensor dimension layout
    // Format A: [1][56][8400] -> [batch][channels][anchors]
    // Format B: [1][8400][56] -> [batch][anchors][channels]
    List<dynamic> batch;
    if (rawOutput is List && rawOutput.isNotEmpty) {
      batch = rawOutput[0] as List<dynamic>;
    } else {
      return PoseDetection.empty();
    }

    final bool isChannelFirst = batch.length == 56 || (batch.length < 100);
    final int numAnchors = isChannelFirst ? (batch[0] as List).length : batch.length;
    final int numFeatures = isChannelFirst ? batch.length : (batch[0] as List).length;

    if (numFeatures < 56) {
      return PoseDetection.empty();
    }

    double bestPersonScore = -1.0;
    int bestAnchorIndex = -1;

    // Fast pass: Find highest confidence person detection
    for (int a = 0; a < numAnchors; a++) {
      final double score = isChannelFirst
          ? (batch[4][a] as num).toDouble()
          : (batch[a][4] as num).toDouble();

      if (score > bestPersonScore && score >= minConfidence) {
        bestPersonScore = score;
        bestAnchorIndex = a;
      }
    }

    if (bestAnchorIndex == -1) {
      return PoseDetection.empty();
    }

    // Extract Bounding Box
    final double cx = isChannelFirst
        ? (batch[0][bestAnchorIndex] as num).toDouble()
        : (batch[bestAnchorIndex][0] as num).toDouble();
    final double cy = isChannelFirst
        ? (batch[1][bestAnchorIndex] as num).toDouble()
        : (batch[bestAnchorIndex][1] as num).toDouble();
    final double w = isChannelFirst
        ? (batch[2][bestAnchorIndex] as num).toDouble()
        : (batch[bestAnchorIndex][2] as num).toDouble();
    final double h = isChannelFirst
        ? (batch[3][bestAnchorIndex] as num).toDouble()
        : (batch[bestAnchorIndex][3] as num).toDouble();

    // Scale factors to map model coordinates (640x640) to screen preview
    final double scaleX = previewSize.width / modelInputSize.width;
    final double scaleY = previewSize.height / modelInputSize.height;

    final double screenLeft = (cx - w / 2) * scaleX;
    final double screenTop = (cy - h / 2) * scaleY;
    final double screenWidth = w * scaleX;
    final double screenHeight = h * scaleY;

    final Rect boundingBox = Rect.fromLTWH(
      screenLeft.clamp(0.0, previewSize.width),
      screenTop.clamp(0.0, previewSize.height),
      screenWidth.clamp(0.0, previewSize.width),
      screenHeight.clamp(0.0, previewSize.height),
    );

    // Extract 17 Keypoints
    final List<Keypoint> keypoints = [];
    for (int k = 0; k < AppConstants.numKeypoints; k++) {
      final int offset = 5 + (k * 3);
      final double kx = isChannelFirst
          ? (batch[offset][bestAnchorIndex] as num).toDouble()
          : (batch[bestAnchorIndex][offset] as num).toDouble();
      final double ky = isChannelFirst
          ? (batch[offset + 1][bestAnchorIndex] as num).toDouble()
          : (batch[bestAnchorIndex][offset + 1] as num).toDouble();
      final double kConf = isChannelFirst
          ? (batch[offset + 2][bestAnchorIndex] as num).toDouble()
          : (batch[bestAnchorIndex][offset + 2] as num).toDouble();

      final double screenX = (kx * scaleX).clamp(0.0, previewSize.width);
      final double screenY = (ky * scaleY).clamp(0.0, previewSize.height);

      keypoints.add(
        Keypoint(
          index: k,
          name: k < keypointLabels.length ? keypointLabels[k] : 'kp_$k',
          x: screenX,
          y: screenY,
          confidence: kConf,
        ),
      );
    }

    return PoseDetection(
      boundingBox: boundingBox,
      confidence: bestPersonScore,
      keypoints: keypoints,
      personDetected: true,
    );
  }

  /// Extracts football detection if the model outputs multi-class bounding boxes
  /// (e.g., class 1 = ball or COCO class 32 = sports ball).
  BallDetection? decodeBallCandidate({
    required dynamic rawOutput,
    required Size previewSize,
    Size modelInputSize = const Size(640, 640),
    int ballClassIndex = 1,
    double minBallConfidence = AppConstants.minBallConfidence,
  }) {
    if (rawOutput is! List || rawOutput.isEmpty) return null;
    final List<dynamic> batch = rawOutput[0] as List<dynamic>;

    final bool isChannelFirst = batch.length < 100;
    final int numAnchors = isChannelFirst ? (batch[0] as List).length : batch.length;
    final int numFeatures = isChannelFirst ? batch.length : (batch[0] as List).length;

    if (numFeatures <= ballClassIndex + 4) return null;

    double bestBallScore = -1.0;
    int bestAnchor = -1;

    for (int a = 0; a < numAnchors; a++) {
      final double score = isChannelFirst
          ? (batch[4 + ballClassIndex][a] as num).toDouble()
          : (batch[a][4 + ballClassIndex] as num).toDouble();

      if (score > bestBallScore && score >= minBallConfidence) {
        bestBallScore = score;
        bestAnchor = a;
      }
    }

    if (bestAnchor == -1) return null;

    final double cx = isChannelFirst
        ? (batch[0][bestAnchor] as num).toDouble()
        : (batch[bestAnchor][0] as num).toDouble();
    final double cy = isChannelFirst
        ? (batch[1][bestAnchor] as num).toDouble()
        : (batch[bestAnchor][1] as num).toDouble();
    final double w = isChannelFirst
        ? (batch[2][bestAnchor] as num).toDouble()
        : (batch[bestAnchor][2] as num).toDouble();
    final double h = isChannelFirst
        ? (batch[3][bestAnchor] as num).toDouble()
        : (batch[bestAnchor][3] as num).toDouble();

    final double scaleX = previewSize.width / modelInputSize.width;
    final double scaleY = previewSize.height / modelInputSize.height;

    final double screenCx = cx * scaleX;
    final double screenCy = cy * scaleY;
    final double screenW = w * scaleX;
    final double screenH = h * scaleY;
    final double radius = math.max(screenW, screenH) / 2.0;

    return BallDetection(
      boundingBox: Rect.fromCenter(
        center: Offset(screenCx, screenCy),
        width: screenW,
        height: screenH,
      ),
      center: Offset(screenCx, screenCy),
      radius: radius,
      confidence: bestBallScore,
      isDetected: true,
      isCoasted: false,
      lostFrames: 0,
    );
  }
}
