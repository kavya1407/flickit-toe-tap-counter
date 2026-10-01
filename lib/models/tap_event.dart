import 'package:flutter/material.dart';

/// Indicates which foot triggered the toe tap.
enum FootSide {
  left,
  right,
  unknown,
}

/// Lifecycle states of a toe tap within the Finite State Machine (FSM).
enum TapPhase {
  idle,         // Foot is far above or away from the ball
  approaching,  // Foot is moving downward toward the ball
  contact,      // Foot has made contact with the top of the ball
  retracting,   // Foot is lifting upward off the ball (hysteresis separation)
  cooldown,     // Temporary debounce lockout before the same foot can re-trigger
}

/// Represents a validated toe tap event.
class TapEvent {
  final int tapId;
  final FootSide footSide;
  final DateTime timestamp;
  final Offset ballCenter;
  final Offset contactPoint;
  final double distance;

  const TapEvent({
    required this.tapId,
    required this.footSide,
    required this.timestamp,
    required this.ballCenter,
    required this.contactPoint,
    required this.distance,
  });

  String get footLabel => footSide == FootSide.left
      ? 'Left Foot'
      : footSide == FootSide.right
          ? 'Right Foot'
          : 'Foot';
}
