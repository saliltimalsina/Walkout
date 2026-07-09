import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';

/// Labeled horizontal progress/stat bar (e.g. striking accuracy 60%).
/// Animates its fill on build for a lively stats screen.
class AppStatBar extends StatelessWidget {
  const AppStatBar({
    super.key,
    required this.label,
    required this.value,
    this.max = 100,
    this.valueLabel,
    this.color,
  });

  final String label;
  final double value;
  final double max;
  final String? valueLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fraction = (max <= 0 ? 0.0 : (value / max)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: context.text.bodySmall?.copyWith(
              color: c.textSecondary,
            )),
            Text(
              valueLabel ?? value.toStringAsFixed(0),
              style: context.text.labelMedium?.copyWith(color: c.textPrimary),
            ),
          ],
        ),
        AppSpacing.vGapXs,
        ClipRRect(
          borderRadius: AppRadius.brPill,
          child: Stack(
            children: [
              Container(height: 8, color: c.surfaceElevated),
              LayoutBuilder(
                builder: (context, constraints) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: AppDuration.slow,
                  curve: AppCurves.emphasized,
                  builder: (context, t, _) => Container(
                    height: 8,
                    width: constraints.maxWidth * t,
                    decoration: BoxDecoration(
                      color: color ?? c.brand,
                      borderRadius: AppRadius.brPill,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
