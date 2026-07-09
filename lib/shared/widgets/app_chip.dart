import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';
import 'pressable.dart';

enum AppChipVariant { neutral, brand, outline }

/// Small label / selectable tag. Supports a selected state for filters.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.icon,
    this.variant = AppChipVariant.neutral,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;
  final AppChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    late Color bg;
    late Color fg;
    late Color border;

    if (selected) {
      bg = c.brand;
      fg = c.onBrand;
      border = c.brand;
    } else {
      switch (variant) {
        case AppChipVariant.brand:
          bg = c.brandContainer;
          fg = c.brand;
          border = Colors.transparent;
        case AppChipVariant.outline:
          bg = Colors.transparent;
          fg = c.textSecondary;
          border = c.border;
        case AppChipVariant.neutral:
          bg = c.surfaceElevated;
          fg = c.textSecondary;
          border = c.border;
      }
    }

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            AppSpacing.hGapXs,
          ],
          Text(label, style: context.text.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );

    if (onTap == null) return chip;
    return Pressable(onTap: onTap, semanticLabel: label, child: chip);
  }
}
