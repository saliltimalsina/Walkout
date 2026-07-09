import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';
import 'champion_rail_card.dart';

/// "Champions" section: a horizontally scrolling rail of champion mini-cards.
class ChampionsRail extends ConsumerWidget {
  const ChampionsRail({super.key});

  static const double _railHeight = 150;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final champions = ref.watch(championsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Champions',
          actionLabel: 'Rankings',
          onAction: () => context.push(AppRoutes.rankings),
        ),
        SizedBox(
          height: _railHeight,
          child: champions.when(
            data: (fighters) {
              if (fighters.isEmpty) return const SizedBox.shrink();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fighters.length,
                itemBuilder: (context, index) {
                  final fighter = fighters[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == fighters.length - 1 ? 0 : AppSpacing.md,
                    ),
                    child: ChampionRailCard(
                      fighter: fighter,
                      onTap: () =>
                          context.push(AppRoutes.fighterPath(fighter.id)),
                    ),
                  );
                },
              );
            },
            loading: () => const _ChampionsRailSkeleton(),
            error: (_, __) => AppEmptyState.error(
              title: 'Could not load champions',
              onRetry: () => ref.invalidate(championsProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChampionsRailSkeleton extends StatelessWidget {
  const _ChampionsRailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : AppSpacing.md),
          child: const SizedBox(
            width: ChampionRailCard.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSkeleton.circle(size: 64),
                AppSpacing.vGapSm,
                AppSkeleton(width: 72, height: 12),
                AppSpacing.vGapXs,
                AppSkeleton(width: 52, height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
