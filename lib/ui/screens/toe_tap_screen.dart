import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../state/toe_tap_controller.dart';
import '../widgets/camera_view.dart';
import '../widgets/control_bar.dart';
import '../widgets/counter_display.dart';
import '../widgets/metrics_badge.dart';

/// Master screen orchestrating the camera viewport, HUD counter,
/// real-time telemetry, and control controls.
class ToeTapScreen extends StatefulWidget {
  const ToeTapScreen({super.key});

  @override
  State<ToeTapScreen> createState() => _ToeTapScreenState();
}

class _ToeTapScreenState extends State<ToeTapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ToeTapController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      body: Consumer<ToeTapController>(
        builder: (context, controller, child) {
          if (!controller.isInitialized) {
            return _buildLoadingState(controller.statusMessage);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final previewSize = Size(constraints.maxWidth, constraints.maxHeight);

              return SafeArea(
                child: Stack(
                  children: [
                    // 1. Camera Viewport & CV Skeleton Layer
                    const Positioned.fill(
                      child: CameraView(),
                    ),

                    // 2. Top Header Bar (Title & Telemetry HUD)
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // App Branding
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryNeon,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sports_soccer_rounded,
                                  color: Colors.black,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'FLICKIT CV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              if (controller.isSimulatedMode) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppConstants.accentOrange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.developer_mode, size: 12, color: Colors.black),
                                      SizedBox(width: 4),
                                      Text(
                                        'SIMULATION',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Live FPS & Latency Badge
                          const MetricsBadge(),
                        ],
                      ),
                    ),

                    // 3. Counter Card HUD (Overlay)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: const CounterDisplay(),
                        ),
                      ),
                    ),

                    // 4. Bottom Controls (Start, Pause, Reset, Switch Camera)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: ControlBar(previewSize: previewSize),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(String status) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.primaryNeon.withOpacity(0.15),
            ),
            child: const CircularProgressIndicator(
              color: AppConstants.primaryNeon,
              strokeWidth: 3.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Flickit Toe Tap Counter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
