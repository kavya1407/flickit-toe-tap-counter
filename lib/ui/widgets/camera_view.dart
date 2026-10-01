import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../state/toe_tap_controller.dart';
import 'pose_overlay_painter.dart';

/// Camera viewport with hardware preview, simulation mode fallback,
/// touch-to-anchor interaction, and CV skeleton overlay.
class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ToeTapController>(
      builder: (context, controller, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final previewSize = Size(constraints.maxWidth, constraints.maxHeight);

            return GestureDetector(
              onTapDown: (details) {
                // Interactive manual ball anchoring when user taps on screen
                controller.manualAnchorBall(
                  details.localPosition,
                  previewSize.width * 0.08,
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera Feed or Simulated Training Pitch
                  if (controller.cameraService.isInitialized && !controller.isSimulatedMode)
                    _buildCameraPreview(controller.cameraService.controller!)
                  else
                    _buildSimulatedBackdrop(previewSize),

                  // Real-time Computer Vision Overlay
                  CustomPaint(
                    size: previewSize,
                    painter: PoseOverlayPainter(
                      pose: controller.latestPose,
                      ball: controller.latestBall,
                      latestTap: controller.latestTapEvent,
                      leftPhase: controller.leftPhase,
                      rightPhase: controller.rightPhase,
                      showDebug: controller.debugOverlay,
                    ),
                  ),

                  // Simulation Watermark indicator if running simulated
                  if (controller.isSimulatedMode)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.accentOrange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.developer_mode, size: 14, color: Colors.black),
                            SizedBox(width: 4),
                            Text(
                              'DEMO SIMULATION ACTIVE',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    return Center(
      child: CameraPreview(controller),
    );
  }

  Widget _buildSimulatedBackdrop(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, 0.4),
          radius: 1.2,
          colors: [
            Color(0xFF1B2A1E), // Turf deep green glow
            Color(0xFF0D120E),
            Color(0xFF080A08),
          ],
        ),
      ),
      child: CustomPaint(
        size: size,
        painter: _PitchLinesPainter(),
      ),
    );
  }
}

/// Draws subtle synthetic football pitch markings for visual grounding in simulation mode.
class _PitchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Pitch center circle
    final center = Offset(size.width * 0.5, size.height * 0.72);
    canvas.drawCircle(center, size.width * 0.25, linePaint);
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.72),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
