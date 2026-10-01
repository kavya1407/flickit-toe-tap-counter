import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../state/toe_tap_controller.dart';

/// Modal bottom sheet for fine-tuning computer vision thresholds and toggling simulation.
class SettingsSheet extends StatefulWidget {
  final Size previewSize;

  const SettingsSheet({super.key, required this.previewSize});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ToeTapController>(
      builder: (context, controller, child) {
        final detector = controller.tapDetector;

        return Container(
          decoration: const BoxDecoration(
            color: AppConstants.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CV Tuning & Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Simulation Mode Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Simulation / Demo Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Simulates realistic player & ball taps for emulators & tests',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                activeColor: AppConstants.primaryNeon,
                value: controller.isSimulatedMode,
                onChanged: (val) {
                  controller.toggleSimulationMode(widget.previewSize);
                  setState(() {});
                },
              ),

              const Divider(color: Colors.white12, height: 24),

              // Contact Multiplier Slider
              _buildSliderRow(
                label: 'Contact Radius Threshold',
                value: detector.contactMultiplier,
                min: 0.9,
                max: 1.8,
                divisions: 18,
                displayValue: '${detector.contactMultiplier.toStringAsFixed(2)}x ball radius',
                onChanged: (val) {
                  setState(() => detector.contactMultiplier = val);
                },
              ),

              const SizedBox(height: 14),

              // Separation Hysteresis Slider
              _buildSliderRow(
                label: 'Separation Hysteresis Threshold',
                value: detector.separationMultiplier,
                min: 1.3,
                max: 2.4,
                divisions: 22,
                displayValue: '${detector.separationMultiplier.toStringAsFixed(2)}x ball radius',
                onChanged: (val) {
                  setState(() => detector.separationMultiplier = val);
                },
              ),

              const SizedBox(height: 14),

              // Cooldown Debounce Slider
              _buildSliderRow(
                label: 'Tap Debounce Cooldown',
                value: detector.cooldownMs.toDouble(),
                min: 100,
                max: 400,
                divisions: 15,
                displayValue: '${detector.cooldownMs} ms',
                onChanged: (val) {
                  setState(() => detector.cooldownMs = val.round());
                },
              ),

              const SizedBox(height: 18),

              // Algorithm Note Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppConstants.secondaryNeon, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hysteresis ensures a tap is only triggered once when entering contact, requiring the foot to lift beyond the separation boundary before re-triggering.',
                        style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              displayValue,
              style: const TextStyle(color: AppConstants.primaryNeon, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppConstants.primaryNeon,
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
            trackHeight: 3,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
