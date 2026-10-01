import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/math_utils.dart';
import '../models/ball_detection.dart';
import '../models/pose_detection.dart';
import '../models/tap_event.dart';

/// Single foot state tracker for Finite State Machine (FSM).
class _FootTapState {
  final FootSide side;
  TapPhase phase = TapPhase.idle;
  Offset? previousPosition;
  double previousDistance = double.infinity;
  DateTime lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
  int framesSinceLastTap = 999;
  double minDistanceInPhase = double.infinity;

  _FootTapState(this.side);

  void reset() {
    phase = TapPhase.idle;
    previousPosition = null;
    previousDistance = double.infinity;
    lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
    framesSinceLastTap = 999;
    minDistanceInPhase = double.infinity;
  }
}

/// Advanced Finite State Machine (FSM) for detecting football toe taps.
///
/// Implements:
/// 1. Hysteresis band (Contact distance < Separation distance) to prevent oscillation.
/// 2. Directional kinematic velocity verification (downward descent -> impact -> upward lift).
/// 3. Debounce frames & time cooldown to avoid duplicate counts across consecutive frames.
/// 4. Independent Left and Right foot tracking for alternating football drills.
class ToeTapDetector {
  final _FootTapState _leftFoot = _FootTapState(FootSide.left);
  final _FootTapState _rightFoot = _FootTapState(FootSide.right);

  double contactMultiplier;
  double separationMultiplier;
  int minDebounceFrames;
  int cooldownMs;

  int _totalTaps = 0;
  int _leftTaps = 0;
  int _rightTaps = 0;
  TapEvent? _lastTapEvent;

  ToeTapDetector({
    this.contactMultiplier = AppConstants.defaultContactMultiplier,
    this.separationMultiplier = AppConstants.defaultSeparationMultiplier,
    this.minDebounceFrames = AppConstants.minFramesBetweenTaps,
    this.cooldownMs = AppConstants.tapCooldownMs,
  });

  int get totalTaps => _totalTaps;
  int get leftTaps => _leftTaps;
  int get rightTaps => _rightTaps;
  TapEvent? get lastTapEvent => _lastTapEvent;
  TapPhase get leftPhase => _leftFoot.phase;
  TapPhase get rightPhase => _rightFoot.phase;

  /// Processes a single frame given the detected pose and tracked ball.
  /// Returns a new [TapEvent] if a valid tap occurred in this frame, or null otherwise.
  TapEvent? processFrame({
    required PoseDetection pose,
    required BallDetection ball,
    required DateTime timestamp,
  }) {
    // If either person or ball is missing, advance cooldown timers and return
    if (!pose.personDetected || !ball.isDetected) {
      _leftFoot.framesSinceLastTap++;
      _rightFoot.framesSinceLastTap++;
      return null;
    }

    final double contactThreshold = ball.radius * contactMultiplier;
    final double separationThreshold = ball.radius * separationMultiplier;

    TapEvent? newTap;

    // Process Left Foot
    final Offset? leftToe = pose.estimatedLeftToe ?? pose.leftAnkle?.position;
    if (leftToe != null) {
      final tap = _updateFootFsm(
        footState: _leftFoot,
        footPos: leftToe,
        ball: ball,
        contactThreshold: contactThreshold,
        separationThreshold: separationThreshold,
        timestamp: timestamp,
      );
      if (tap != null) newTap = tap;
    }

    // Process Right Foot
    final Offset? rightToe = pose.estimatedRightToe ?? pose.rightAnkle?.position;
    if (rightToe != null) {
      final tap = _updateFootFsm(
        footState: _rightFoot,
        footPos: rightToe,
        ball: ball,
        contactThreshold: contactThreshold,
        separationThreshold: separationThreshold,
        timestamp: timestamp,
      );
      if (tap != null) newTap = tap;
    }

    return newTap;
  }

  /// Updates the 4-phase state machine for a specific foot.
  TapEvent? _updateFootFsm({
    required _FootTapState footState,
    required Offset footPos,
    required BallDetection ball,
    required double contactThreshold,
    required double separationThreshold,
    required DateTime timestamp,
  }) {
    footState.framesSinceLastTap++;
    final double currentDistance = MathUtils.euclideanDistance(footPos, ball.center);

    // Calculate vertical movement (positive = moving downwards on screen)
    final double deltaY = footState.previousPosition != null
        ? footPos.dy - footState.previousPosition!.dy
        : 0.0;

    // Physical constraint: Toe tap MUST occur on or above the top surface of the ball.
    // If foot is deeper than 35% below the ball center, it's behind or kicking the ball, not a top tap.
    final bool isAboveBallCenter = footPos.dy <= (ball.center.dy + ball.radius * 0.35);
    final bool isHorizontallyAligned =
        (footPos.dx - ball.center.dx).abs() <= (ball.radius * 1.35);

    final bool inGeometricalContactZone =
        isAboveBallCenter && isHorizontallyAligned && (currentDistance <= contactThreshold);

    TapEvent? event;

    switch (footState.phase) {
      case TapPhase.idle:
        // Transition: Foot begins approaching ball
        if (currentDistance < separationThreshold && deltaY > -2.0) {
          footState.phase = TapPhase.approaching;
          footState.minDistanceInPhase = currentDistance;
        }
        break;

      case TapPhase.approaching:
        if (currentDistance < footState.minDistanceInPhase) {
          footState.minDistanceInPhase = currentDistance;
        }

        // Transition: Foot enters contact zone
        if (inGeometricalContactZone) {
          final int msSinceLast =
              timestamp.difference(footState.lastTapTime).inMilliseconds;

          // Verify debouncing requirements
          if (footState.framesSinceLastTap >= minDebounceFrames &&
              msSinceLast >= cooldownMs) {
            // TAP REGISTERED!
            _totalTaps++;
            if (footState.side == FootSide.left) {
              _leftTaps++;
            } else {
              _rightTaps++;
            }

            footState.lastTapTime = timestamp;
            footState.framesSinceLastTap = 0;
            footState.phase = TapPhase.contact;

            event = TapEvent(
              tapId: _totalTaps,
              footSide: footState.side,
              timestamp: timestamp,
              ballCenter: ball.center,
              contactPoint: footPos,
              distance: currentDistance,
            );
            _lastTapEvent = event;
          } else {
            // Still in cooldown from previous tap
            footState.phase = TapPhase.contact;
          }
        } else if (currentDistance > separationThreshold * 1.2) {
          // Aborted approach without contact
          footState.phase = TapPhase.idle;
        }
        break;

      case TapPhase.contact:
        // Transition: Foot begins lifting off (retracting)
        if (currentDistance > contactThreshold) {
          footState.phase = TapPhase.retracting;
        }
        break;

      case TapPhase.retracting:
        // Transition: Foot has cleared the hysteresis separation boundary
        if (currentDistance >= separationThreshold) {
          footState.phase = TapPhase.cooldown;
        } else if (inGeometricalContactZone && footState.framesSinceLastTap > minDebounceFrames) {
          // Quick bounce back into contact
          footState.phase = TapPhase.approaching;
        }
        break;

      case TapPhase.cooldown:
        // Release cooldown back to idle once debounce requirements are satisfied
        if (footState.framesSinceLastTap >= minDebounceFrames) {
          footState.phase = TapPhase.idle;
        }
        break;
    }

    footState.previousPosition = footPos;
    footState.previousDistance = currentDistance;
    return event;
  }

  /// Resets tap counts and state machine back to zero.
  void reset() {
    _totalTaps = 0;
    _leftTaps = 0;
    _rightTaps = 0;
    _lastTapEvent = null;
    _leftFoot.reset();
    _rightFoot.reset();
  }
}
