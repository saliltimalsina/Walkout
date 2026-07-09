import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';

/// Compact ranking indicator: gold "C" for champions, "#n" for ranked fighters,
/// "NR" when unranked.
class RankBadge extends StatelessWidget {
  const RankBadge({
    super.key,
    this.position,
    this.isChampion = false,
    this.compact = false,
  });

  final int? position;
  final bool isChampion;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = isChampion
        ? 'C'
        : position != null
            ? '#$position'
            : 'NR';

    final bg = isChampion ? c.accent : c.surfaceElevated;
    final fg = isChampion ? c.background : c.textSecondary;
    final border = isChampion ? Colors.transparent : c.border;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: (compact ? context.text.labelSmall : context.text.labelLarge)
            ?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
