import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Breakdown of how a fighter's wins are earned: knockout, submission, decision.
class FinishBreakdown extends StatelessWidget {
  const FinishBreakdown({super.key, required this.fighter});

  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wins = fighter.record.wins;
    // Guard against division-by-zero when a fighter has no wins yet.
    final max = (wins == 0 ? 1 : wins).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HOW THE WINS COME',
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          AppSpacing.vGapMd,
          AppStatBar(
            label: 'KO / TKO',
            value: fighter.winsByKo.toDouble(),
            max: max,
            valueLabel: '${fighter.winsByKo}',
            color: c.brand,
          ),
          AppSpacing.vGapMd,
          AppStatBar(
            label: 'Submission',
            value: fighter.winsBySub.toDouble(),
            max: max,
            valueLabel: '${fighter.winsBySub}',
            color: c.accent,
          ),
          AppSpacing.vGapMd,
          AppStatBar(
            label: 'Decision',
            value: fighter.winsByDec.toDouble(),
            max: max,
            valueLabel: '${fighter.winsByDec}',
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}
