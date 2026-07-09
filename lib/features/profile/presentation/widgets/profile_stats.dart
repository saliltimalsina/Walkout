import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Row of three key stat cells: predictions made, accuracy, favorites count.
class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    required this.user,
    required this.favoritesCount,
  });

  final UserProfile user;
  final int favoritesCount;

  /// "0%" computed from zero picks reads as a (bad) score; an em dash reads
  /// as "no data yet".
  String get _accuracyLabel => user.predictionsMade == 0
      ? '—'
      : '${(user.predictionsCorrect / user.predictionsMade * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                value: '${user.predictionsMade}',
                label: 'Predictions',
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _StatCell(
                value: _accuracyLabel,
                label: 'Accuracy',
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _StatCell(
                value: '$favoritesCount',
                label: 'Favorites',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: AppSpacing.lg,
      thickness: 1,
      color: context.colors.divider,
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: context.text.headlineSmall?.copyWith(
            color: c.brand,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        AppSpacing.vGapXs,
        Text(
          label,
          style: context.text.labelSmall?.copyWith(color: c.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
