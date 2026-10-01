import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toe_tap_counter/services/yolo_postprocessor.dart';

void main() {
  group('YoloPostprocessor Tests', () {
    late YoloPostprocessor postprocessor;

    setUp(() {
      postprocessor = YoloPostprocessor();
    });

    test('decodePose parses [1, 56, 8400] channel-first output and applies preview scaling', () {
      // Mock tensor of shape [1, 56, 5] (batch=1, features=56, anchors=5)
      final rawOutput = [
        List.generate(56, (f) => List<double>.filled(5, 0.0)),
      ];

      // Anchor 2 represents detected person
      final batch = rawOutput[0];
      batch[0][2] = 320.0; // cx
      batch[1][2] = 320.0; // cy
      batch[2][2] = 200.0; // w
      batch[3][2] = 400.0; // h
      batch[4][2] = 0.92;  // person confidence

      // Keypoint 15 (left ankle): offset = 5 + 15*3 = 50
      batch[50][2] = 300.0; // kx
      batch[51][2] = 500.0; // ky
      batch[52][2] = 0.88;  // kp confidence

      // Keypoint 16 (right ankle): offset = 5 + 16*3 = 53
      batch[53][2] = 340.0;
      batch[54][2] = 500.0;
      batch[55][2] = 0.85;

      const previewSize = Size(400, 800);
      final pose = postprocessor.decodePose(
        rawOutput: rawOutput,
        previewSize: previewSize,
        modelInputSize: const Size(640, 640),
        minConfidence: 0.5,
      );

      expect(pose.personDetected, isTrue);
      expect(pose.confidence, closeTo(0.92, 0.01));
      expect(pose.leftAnkle, isNotNull);
      expect(pose.rightAnkle, isNotNull);

      // Coordinates should be scaled to preview size: 400/640 = 0.625, 800/640 = 1.25
      expect(pose.leftAnkle!.x, closeTo(300.0 * 0.625, 0.1));
      expect(pose.leftAnkle!.y, closeTo(500.0 * 1.25, 0.1));
    });
  });
}
