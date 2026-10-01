import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../state/toe_tap_controller.dart';

/// Floating chip displaying live FPS, inference latency, and hardware profile.
class MetricsBadge extends StatelessWidget {
  const MetricsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ToeTapController>(
      builder: (context, controller, child) {
        final metrics = controller.metrics;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMetricItem(
                label: 'FPS',
                value: metrics.cameraFps > 0
                    ? metrics.cameraFps.toStringAsFixed(0)
                    : '--',
                color: AppConstants.primaryNeon,
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 14, color: Colors.white24),
              const SizedBox(width: 8),
              _buildMetricItem(
                label: 'INFER',
                value: metrics.inferenceFps > 0
                    ? '${metrics.inferenceFps.toStringAsFixed(0)} FPS'
                    : '--',
                color: AppConstants.secondaryNeon,
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 14, color: Colors.white24),
              const SizedBox(width: 8),
              _buildMetricItem(
                label: 'LATENCY',
                value: '${metrics.inferenceLatencyMs}ms',
                color: metrics.inferenceLatencyMs < 45
                    ? AppConstants.primaryNeon
                    : AppConstants.accentOrange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
