import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';
import '../models/fighter.dart';
import 'app_avatar.dart';
import 'app_card.dart';
import 'rank_badge.dart';

/// Reusable fighter summary row used across home, rankings, search and profile.
/// Pure presentation — the parent supplies [onTap] for navigation.
class FighterListCard extends StatelessWidget {
  const FighterListCard({
    super.key,
    required this.fighter,
    this.onTap,
    this.trailing,
    this.showRank = true,
    this.positionOverride,
  });

  final Fighter fighter;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showRank;

  /// Overrides the fighter's own ranking position (e.g. divisional list index).
  final int? positionOverride;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppCard(
      onTap: onTap,
      padding: AppSpacing.allMd,
      child: Row(
        children: [
          AppAvatar(
            name: fighter.name,
            imageUrl: fighter.imageUrl,
            size: 52,
            borderColor: fighter.isChampion ? c.accent : null,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (fighter.flag.isNotEmpty) ...[
                      Text(fighter.flag,
                          style: const TextStyle(fontSize: 14)),
                      AppSpacing.hGapXs,
                    ],
                    Flexible(
                      child: Text(
                        fighter.name,
                        style: context.text.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Text(
                  '${fighter.record.display} · ${fighter.weightClass.label}',
                  style: context.text.bodySmall
                      ?.copyWith(color: c.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.hGapMd,
          if (trailing != null)
            trailing!
          else if (showRank)
            RankBadge(
              position: positionOverride ?? fighter.rankingPosition,
              isChampion: positionOverride == null && fighter.isChampion,
            ),
        ],
      ),
    );
  }
}
