import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Detailed striking and grappling statistics: percentage bars for bounded
/// metrics, plain value rows for open-ended per-minute figures.
class FighterStatsSection extends StatelessWidget {
  const FighterStatsSection({super.key, required this.stats});

  final FighterStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'STRIKING',
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              AppSpacing.vGapMd,
              AppStatBar(
                label: 'Striking accuracy',
                value: stats.strikingAccuracy,
                valueLabel: '${stats.strikingAccuracy.toStringAsFixed(0)}%',
                color: c.brand,
              ),
              AppSpacing.vGapMd,
              AppStatBar(
                label: 'Striking defense',
                value: stats.strikingDefense,
                valueLabel: '${stats.strikingDefense.toStringAsFixed(0)}%',
                color: c.accent,
              ),
              AppSpacing.vGapLg,
              _ValueRow(
                label: 'Sig. strikes landed /min',
                value: stats.sigStrikesPerMin.toStringAsFixed(1),
              ),
              AppSpacing.vGapSm,
              _ValueRow(
                label: 'Sig. strikes absorbed /min',
                value: stats.sigStrikesAbsorbedPerMin.toStringAsFixed(1),
              ),
            ],
          ),
        ),
        AppSpacing.vGapLg,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'GRAPPLING',
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              AppSpacing.vGapMd,
              AppStatBar(
                label: 'Takedown accuracy',
                value: stats.takedownAccuracy,
                valueLabel: '${stats.takedownAccuracy.toStringAsFixed(0)}%',
                color: c.brand,
              ),
              AppSpacing.vGapMd,
              AppStatBar(
                label: 'Takedown defense',
                value: stats.takedownDefense,
                valueLabel: '${stats.takedownDefense.toStringAsFixed(0)}%',
                color: c.accent,
              ),
              AppSpacing.vGapLg,
              _ValueRow(
                label: 'Takedowns /15min',
                value: stats.takedownAvg.toStringAsFixed(1),
              ),
              AppSpacing.vGapSm,
              _ValueRow(
                label: 'Submission attempts /15min',
                value: stats.submissionAvg.toStringAsFixed(1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single label/value line for open-ended (unbounded) statistics.
class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
        ),
        AppSpacing.hGapMd,
        Text(
          value,
          style: context.text.labelLarge?.copyWith(color: c.textPrimary),
        ),
      ],
    );
  }
}
