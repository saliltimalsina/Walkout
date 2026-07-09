import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_motion.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/fighter.dart';
import 'package:walkout/shared/widgets/app_avatar.dart';

/// Apple-clean selectable fighter row for the corner picker.
class CornerFighterRow extends StatelessWidget {
  const CornerFighterRow({
    super.key,
    required this.fighter,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final Fighter fighter;
  final bool selected;

  /// Whether a new selection is allowed (corner not full). Ignored when already
  /// selected (you can always remove).
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canTap = selected || enabled;

    final subtitle = fighter.isChampion
        ? '${fighter.weightClass.label} Champion'
        : fighter.weightClass.label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          AppAvatar(
            name: fighter.name,
            imageUrl: fighter.imageUrl,
            size: 48,
            borderColor: fighter.isChampion ? c.accent : null,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fighter.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                AppSpacing.vGapXs,
                Text(
                  '${fighter.record.display}  ·  $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall
                      ?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          AppSpacing.hGapMd,
          _AddButton(selected: selected, enabled: canTap, onTap: onToggle),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? c.brand : Colors.transparent,
          border: Border.all(
            color: selected
                ? c.brand
                : (enabled ? c.border : c.border.withValues(alpha: 0.4)),
          ),
        ),
        child: Icon(
          selected ? Icons.check_rounded : Icons.add_rounded,
          size: 20,
          color: selected
              ? c.onBrand
              : (enabled ? c.textPrimary : c.textDisabled),
        ),
      ),
    );
  }
}
