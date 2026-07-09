import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/widgets.dart';
import '../providers/home_feed.dart';

/// Rankings movers — a clean vertical list of who's climbing (or new).
class RankingsMoversSection extends ConsumerWidget {
  const RankingsMoversSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movers = ref.watch(rankingsMoversProvider);
    if (movers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Rankings Movers',
          actionLabel: 'See all',
          onAction: () => context.go(AppRoutes.rankings),
        ),
        for (var i = 0; i < movers.length; i++) ...[
          if (i > 0) AppSpacing.vGapSm,
          _MoverRow(mover: movers[i]),
        ],
      ],
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({required this.mover});

  final Mover mover;

  @override
  Widget build(BuildContext context) {
    final f = mover.fighter;
    return AppCard(
      onTap: () => context.push(AppRoutes.fighterPath(f.id)),
      padding: AppSpacing.allMd,
      child: Row(
        children: [
          AppAvatar(name: f.name, imageUrl: f.imageUrl, size: 40),
          AppSpacing.hGapMd,
          SizedBox(width: 34, child: Center(child: _Delta(change: mover.change))),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  f.weightClass.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall
                      ?.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          Text(
            '#${f.rankingPosition ?? '-'}',
            style:
                context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (change == 0) {
      return Text(
        'NEW',
        style: context.text.labelSmall
            ?.copyWith(color: c.accent, fontWeight: FontWeight.w800),
      );
    }
    final up = change > 0;
    final color = up ? c.success : c.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 14,
          color: color,
        ),
        Text(
          '${change.abs()}',
          style: context.text.labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
