import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Placeholder that mirrors [EventCard]'s layout while events load.
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.allMd,
      child: Row(
        children: [
          const AppSkeleton(
            width: 56,
            height: 56,
            borderRadius: AppRadius.brMd,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                AppSkeleton(width: 160, height: 16),
                AppSpacing.vGapSm,
                AppSkeleton(width: 110, height: 12),
                AppSpacing.vGapSm,
                AppSkeleton(width: 140, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
