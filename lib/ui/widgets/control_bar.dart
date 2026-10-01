import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../state/toe_tap_controller.dart';
import 'settings_sheet.dart';

/// Bottom athletic control bar for session execution, reset, camera toggle, and settings.
class ControlBar extends StatelessWidget {
  final Size previewSize;

  const ControlBar({
    super.key,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ToeTapController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppConstants.hudOverlayBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Reset Counter Button
              IconButton(
                onPressed: controller.resetSession,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 28),
                tooltip: 'Reset Counter',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.06),
                  padding: const EdgeInsets.all(12),
                ),
              ),

              // Camera Flip
              IconButton(
                onPressed: () => controller.toggleCamera(previewSize),
                icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70, size: 26),
                tooltip: 'Switch Camera',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.06),
                  padding: const EdgeInsets.all(12),
                ),
              ),

              // Primary Action: START / PAUSE
              ElevatedButton(
                onPressed: () {
                  if (controller.isRunning) {
                    controller.pauseSession();
                  } else {
                    controller.startSession(previewSize);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isRunning
                      ? AppConstants.dangerRed
                      : AppConstants.primaryNeon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: controller.isRunning ? Colors.white : Colors.black,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.isRunning ? 'PAUSE' : 'START',
                      style: TextStyle(
                        color: controller.isRunning ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Debug Overlay Toggle
              IconButton(
                onPressed: controller.toggleDebugOverlay,
                icon: Icon(
                  controller.debugOverlay ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: controller.debugOverlay ? AppConstants.primaryNeon : Colors.white38,
                  size: 26,
                ),
                tooltip: 'Toggle CV Skeleton',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.06),
                  padding: const EdgeInsets.all(12),
                ),
              ),

              // Settings Sheet Button
              IconButton(
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 26),
                tooltip: 'CV Threshold Settings',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.06),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SettingsSheet(previewSize: previewSize),
    );
  }
}
