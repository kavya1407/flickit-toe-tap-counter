import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toe_tap_counter/models/ball_detection.dart';
import 'package:toe_tap_counter/models/keypoint.dart';
import 'package:toe_tap_counter/models/pose_detection.dart';
import 'package:toe_tap_counter/models/tap_event.dart';
import 'package:toe_tap_counter/services/toe_tap_detector.dart';

void main() {
  group('ToeTapDetector FSM & Debounce Tests', () {
    late ToeTapDetector detector;

    setUp(() {
      detector = ToeTapDetector(
        contactMultiplier: 1.2,
        separationMultiplier: 1.6,
        minDebounceFrames: 3,
        cooldownMs: 100,
      );
    });

    PoseDetection createPose({
      required Offset leftAnkle,
      required Offset rightAnkle,
      Offset? leftKnee,
      Offset? rightKnee,
    }) {
      final lk = leftKnee ?? Offset(leftAnkle.dx, leftAnkle.dy - 100);
      final rk = rightKnee ?? Offset(rightAnkle.dx, rightAnkle.dy - 100);

      final keypoints = [
        Keypoint(index: 13, name: 'left_knee', x: lk.dx, y: lk.dy, confidence: 0.9),
        Keypoint(index: 14, name: 'right_knee', x: rk.dx, y: rk.dy, confidence: 0.9),
        Keypoint(index: 15, name: 'left_ankle', x: leftAnkle.dx, y: leftAnkle.dy, confidence: 0.9),
        Keypoint(index: 16, name: 'right_ankle', x: rightAnkle.dx, y: rightAnkle.dy, confidence: 0.9),
      ];

      return PoseDetection(
        boundingBox: const Rect.fromLTWH(0, 0, 400, 800),
        confidence: 0.9,
        keypoints: keypoints,
        personDetected: true,
      );
    }

    BallDetection createBall({
      required Offset center,
      double radius = 40.0,
    }) {
      return BallDetection(
        boundingBox: Rect.fromCircle(center: center, radius: radius),
        center: center,
        radius: radius,
        confidence: 0.95,
        isDetected: true,
      );
    }

    test('Single clean tap registers exactly 1 tap and avoids duplicate counts across consecutive frames', () {
      final ball = createBall(center: const Offset(200, 500), radius: 50.0);
      var time = DateTime.now();

      // Frame 1: Foot is high above ball (Idle)
      var pose = createPose(
        leftAnkle: const Offset(200, 350),
        rightAnkle: const Offset(350, 480),
      );
      var event = detector.processFrame(pose: pose, ball: ball, timestamp: time);
      expect(event, isNull);
      expect(detector.totalTaps, equals(0));

      // Frame 2: Foot descends toward ball (Approaching)
      time = time.add(const Duration(milliseconds: 33));
      pose = createPose(
        leftAnkle: const Offset(200, 390),
        rightAnkle: const Offset(350, 480),
      );
      event = detector.processFrame(pose: pose, ball: ball, timestamp: time);
      expect(event, isNull);
      expect(detector.totalTaps, equals(0));

      // Frame 3: Foot touches top of ball (Contact -> Tap Registered!)
      time = time.add(const Duration(milliseconds: 33));
      pose = createPose(
        leftAnkle: const Offset(200, 460), // within radius 50 of center (200, 500)
        rightAnkle: const Offset(350, 480),
      );
      event = detector.processFrame(pose: pose, ball: ball, timestamp: time);
      expect(event, isNotNull);
      expect(detector.totalTaps, equals(1));
      expect(detector.leftTaps, equals(1));
      expect(detector.rightTaps, equals(0));

      // Frames 4, 5, 6: Foot stays in contact across consecutive frames
      // CRITICAL: MUST NOT COUNT AGAIN!
      for (int i = 0; i < 3; i++) {
        time = time.add(const Duration(milliseconds: 33));
        event = detector.processFrame(pose: pose, ball: ball, timestamp: time);
        expect(event, isNull, reason: 'Duplicate tap registered on frame $i!');
        expect(detector.totalTaps, equals(1));
      }

      // Frame 7: Foot lifts off beyond separation threshold (Retracting -> Hysteresis Reset)
      time = time.add(const Duration(milliseconds: 150));
      pose = createPose(
        leftAnkle: const Offset(200, 380), // > 1.6 * 50 = 80 distance
        rightAnkle: const Offset(350, 480),
      );
      detector.processFrame(pose: pose, ball: ball, timestamp: time);

      // Now foot descends again -> Tap 2!
      time = time.add(const Duration(milliseconds: 150));
      pose = createPose(
        leftAnkle: const Offset(200, 460),
        rightAnkle: const Offset(350, 480),
      );
      event = detector.processFrame(pose: pose, ball: ball, timestamp: time);
      expect(event, isNotNull);
      expect(detector.totalTaps, equals(2));
      expect(detector.leftTaps, equals(2));
    });

    test('Alternating left and right foot taps are tracked independently', () {
      final ball = createBall(center: const Offset(200, 500), radius: 50.0);
      var time = DateTime.now();

      // Left foot taps
      var pose = createPose(
        leftAnkle: const Offset(200, 460),
        rightAnkle: const Offset(350, 480),
      );
      var event = detector.processFrame(pose: pose, ball: ball, timestamp: time);
      expect(event, isNotNull);
      expect(detector.totalTaps, equals(1));
      expect(detector.leftTaps, equals(1));
      expect(detector.rightTaps, equals(0));

      // Left foot retracts, Right foot descends to tap
      time = time.add(const Duration(milliseconds: 150));
      pose = createPose(
        leftAnkle: const Offset(100, 350), // retracted
        rightAnkle: const Offset(200, 460), // right in contact
      );
      event = detector.processFrame(pose: pose, ball: ball, timestamp: time);
      expect(event, isNotNull);
      expect(detector.totalTaps, equals(2));
      expect(detector.leftTaps, equals(1));
      expect(detector.rightTaps, equals(1));
    });

    test('Reset clears counts and states back to 0', () {
      final ball = createBall(center: const Offset(200, 500), radius: 50.0);
      final pose = createPose(
        leftAnkle: const Offset(200, 460),
        rightAnkle: const Offset(350, 480),
      );

      detector.processFrame(pose: pose, ball: ball, timestamp: DateTime.now());
      expect(detector.totalTaps, equals(1));

      detector.reset();
      expect(detector.totalTaps, equals(0));
      expect(detector.leftTaps, equals(0));
      expect(detector.rightTaps, equals(0));
      expect(detector.lastTapEvent, isNull);
    });
  });
}
