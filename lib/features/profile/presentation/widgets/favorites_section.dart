import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/favorites_controller.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Lists the fighters the current user has favorited, each removable inline.
class FavoritesSection extends ConsumerWidget {
  const FavoritesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final fightersAsync = ref.watch(fightersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Favorite Fighters'),
        fightersAsync.when(
          loading: () => const _FavoritesLoading(),
          error: (_, __) => const SizedBox.shrink(),
          data: (fighters) {
            final byId = {for (final f in fighters) f.id: f};
            final favorites = [
              for (final id in favoriteIds)
                if (byId.containsKey(id)) byId[id]!,
            ];

            if (favorites.isEmpty) {
              return const AppEmptyState(
                title: 'No favorites yet',
                message: 'Tap the heart on a fighter to follow them.',
                icon: AppIcons.favoriteBorder,
              );
            }

            return Column(
              children: [
                for (final fighter in favorites) ...[
                  FighterListCard(
                    fighter: fighter,
                    onTap: () =>
                        context.push(AppRoutes.fighterPath(fighter.id)),
                    trailing: AppIconButton(
                      icon: AppIcons.favorite,
                      color: context.colors.brand,
                      tooltip: 'Remove',
                      onPressed: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(fighter.id),
                    ),
                  ),
                  AppSpacing.vGapSm,
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FavoritesLoading extends StatelessWidget {
  const _FavoritesLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          Row(
            children: [
              const AppSkeleton.circle(size: 52),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSkeleton(width: 140, height: 16),
                    AppSpacing.vGapSm,
                    const AppSkeleton(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
        ],
      ],
    );
  }
}
