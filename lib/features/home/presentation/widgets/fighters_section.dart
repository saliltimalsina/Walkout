import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// "Fighters" section: a short list of notable fighters as summary rows.
class FightersSection extends ConsumerWidget {
  const FightersSection({super.key});

  static const int _maxItems = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fighters = ref.watch(fightersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Fighters',
          actionLabel: 'All',
          onAction: () => context.push(AppRoutes.rankings),
        ),
        fighters.when(
          data: (all) {
            if (all.isEmpty) {
              return const AppEmptyState(title: 'No fighters yet');
            }
            final items = all.take(_maxItems).toList();
            return Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) AppSpacing.vGapSm,
                  FighterListCard(
                    fighter: items[i],
                    onTap: () =>
                        context.push(AppRoutes.fighterPath(items[i].id)),
                  ),
                ],
              ],
            );
          },
          loading: () => const _FightersSkeleton(),
          error: (_, __) => AppEmptyState.error(
            title: 'Could not load fighters',
            onRetry: () => ref.invalidate(fightersProvider),
          ),
        ),
      ],
    );
  }
}

class _FightersSkeleton extends StatelessWidget {
  const _FightersSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeleton(height: 76, borderRadius: AppRadius.brLg),
        AppSpacing.vGapSm,
        AppSkeleton(height: 76, borderRadius: AppRadius.brLg),
        AppSpacing.vGapSm,
        AppSkeleton(height: 76, borderRadius: AppRadius.brLg),
        AppSpacing.vGapSm,
        AppSkeleton(height: 76, borderRadius: AppRadius.brLg),
        AppSpacing.vGapSm,
        AppSkeleton(height: 76, borderRadius: AppRadius.brLg),
      ],
    );
  }
}
