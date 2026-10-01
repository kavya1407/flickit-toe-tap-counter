import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/tap_event.dart';
import '../../state/toe_tap_controller.dart';

/// Athletic HUD counter display showing total taps, left/right foot split,
/// and real-time state machine phase.
class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ToeTapController>(
      builder: (context, controller, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.hudOverlayBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: controller.isRunning
                  ? AppConstants.primaryNeon.withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Counter Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controller.isRunning
                                  ? AppConstants.primaryNeon
                                  : AppConstants.accentOrange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.isRunning ? 'LIVE SESSION' : 'PAUSED',
                            style: TextStyle(
                              color: controller.isRunning
                                  ? AppConstants.primaryNeon
                                  : Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'TOE TAPS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),

                  // Giant Digital Count
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      '${controller.totalTaps}',
                      key: ValueKey<int>(controller.totalTaps),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Left vs Right Foot Split Breakdown (Bonus)
              Row(
                children: [
                  Expanded(
                    child: _buildFootPill(
                      label: 'LEFT FOOT',
                      count: controller.leftTaps,
                      phase: controller.leftPhase,
                      accentColor: AppConstants.secondaryNeon,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFootPill(
                      label: 'RIGHT FOOT',
                      count: controller.rightTaps,
                      phase: controller.rightPhase,
                      accentColor: AppConstants.primaryNeon,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Dynamic Status Chip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: controller.latestTapEvent != null &&
                            DateTime.now().difference(controller.latestTapEvent!.timestamp).inMilliseconds < 400
                        ? AppConstants.primaryNeon
                        : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFootPill({
    required String label,
    required int count,
    required TapPhase phase,
    required Color accentColor,
  }) {
    final bool isContact = phase == TapPhase.contact;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isContact ? accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isContact ? accentColor : Colors.white.withOpacity(0.06),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _phaseLabel(phase),
                style: TextStyle(
                  color: isContact ? accentColor : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              color: isContact ? accentColor : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _phaseLabel(TapPhase phase) {
    switch (phase) {
      case TapPhase.idle:
        return 'IDLE';
      case TapPhase.approaching:
        return 'DESCENDING';
      case TapPhase.contact:
        return 'TAP!';
      case TapPhase.retracting:
        return 'LIFT-OFF';
      case TapPhase.cooldown:
        return 'READY';
    }
  }
}
