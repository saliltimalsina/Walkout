import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Compact champion tile used in the home "Champions" horizontal rail.
class ChampionRailCard extends StatelessWidget {
  const ChampionRailCard({super.key, required this.fighter, this.onTap});

  final Fighter fighter;
  final VoidCallback? onTap;

  static const double width = 110;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        padding: AppSpacing.allSm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppAvatar(
              name: fighter.name,
              imageUrl: fighter.imageUrl,
              size: 64,
              borderColor: c.accent,
            ),
            AppSpacing.vGapSm,
            Text(
              fighter.name,
              style: context.text.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            AppSpacing.vGapXs,
            Text(
              fighter.weightClass.label,
              style: context.text.labelSmall?.copyWith(
                color: c.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
