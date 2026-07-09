import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Shown when the search field is empty — a browsable starting point instead
/// of a blank screen: the current champions as portrait tiles that jump
/// straight to their fighter pages, plus division chips that run that
/// division as a search.
class SearchSuggestions extends ConsumerWidget {
  const SearchSuggestions({super.key, required this.onSelect});

  /// Fills the search field with the given text and runs it as a query.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championsAsync = ref.watch(championsProvider);

    return ListView(
      padding: AppSpacing.allMd,
      children: [
        const SectionHeader(title: 'Champions'),
        championsAsync.when(
          loading: () => const _ChampionsSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
          data: (champions) {
            if (champions.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: _ChampionTile.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: champions.length,
                separatorBuilder: (_, __) => AppSpacing.hGapMd,
                itemBuilder: (context, index) {
                  final champion = champions[index];
                  return _ChampionTile(
                    fighter: champion,
                    onTap: () =>
                        context.push(AppRoutes.fighterPath(champion.id)),
                  );
                },
              ),
            );
          },
        ),
        AppSpacing.vGapLg,
        const SectionHeader(title: 'Divisions'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final division in WeightClass.values)
              if (!division.isWomens)
                AppChip(
                  label: division.label,
                  variant: AppChipVariant.outline,
                  onTap: () => onSelect(division.label),
                ),
          ],
        ),
      ],
    );
  }
}

/// Portrait + name tile for one champion; tapping opens their fighter page.
class _ChampionTile extends StatelessWidget {
  const _ChampionTile({required this.fighter, required this.onTap});

  static const double height = 108;
  static const double _width = 84;
  static const double _avatarSize = 64;

  final Fighter fighter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      semanticLabel: fighter.name,
      child: SizedBox(
        width: _width,
        child: Column(
          children: [
            AppAvatar(
              name: fighter.name,
              imageUrl: fighter.imageUrl,
              size: _avatarSize,
              borderColor: c.accent, // champion gold
            ),
            AppSpacing.vGapXs,
            Text(
              fighter.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.labelMedium?.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder row shown while [championsProvider] is loading, echoing the
/// portrait-tile shape so the layout doesn't jump.
class _ChampionsSkeleton extends StatelessWidget {
  const _ChampionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _ChampionTile.height,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            const Column(
              children: [
                AppSkeleton.circle(size: 64),
                AppSpacing.vGapXs,
                AppSkeleton(width: 72, height: 12),
              ],
            ),
            if (i < 3) AppSpacing.hGapMd,
          ],
        ],
      ),
    );
  }
}
