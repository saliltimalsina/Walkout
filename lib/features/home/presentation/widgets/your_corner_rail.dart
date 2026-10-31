import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_colors.dart';
import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/fighter.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/favorites_controller.dart';
import 'package:walkout/shared/widgets/widgets.dart';
import '../../../../shared/widgets/app_image.dart';

/// Tiles shown at once — the half tile signals the rail scrolls.
const double _kVisibleTiles = 3.5;
const double _kRail = 150;

double _tileWidth(double railWidth) =>
    (railWidth - (_kVisibleTiles.floor() * AppSpacing.md)) / _kVisibleTiles;

/// "Your Corner" — the fighters the user follows, each with a status pulse.
class YourCornerRail extends ConsumerWidget {
  const YourCornerRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    if (favs.isEmpty) return const SizedBox.shrink();

    final all = ref.watch(fightersProvider).valueOrNull;
    final byId = {for (final f in (all ?? const <Fighter>[])) f.id: f};
    final fighters = favs.map((id) => byId[id]).whereType<Fighter>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Your Corner',
          actionLabel: 'View all',
          onAction: () => context.push(AppRoutes.profile),
        ),
        SizedBox(
          height: _kRail,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tile = _tileWidth(constraints.maxWidth);
              return all == null
                  ? _LoadingRow(tile: tile)
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: fighters.length,
                      separatorBuilder: (_, __) => AppSpacing.hGapMd,
                      itemBuilder: (context, i) =>
                          _CornerCard(fighter: fighters[i], tile: tile),
                    );
            },
          ),
        ),
      ],
    );
  }
}

/// Fighter status chips. Colors are house-palette tokens resolved from
/// [AppColors] at build time (they can't be const — the palette is themed).
enum _Status {
  fightWeek('Fight Week', AppIcons.events),
  interview('Interview', Icons.mic_rounded),
  trainingCamp('Training Camp', AppIcons.record),
  ranked('Ranked', AppIcons.ranking);

  const _Status(this.label, this.icon);

  final String label;
  final IconData icon;

  Color color(AppColors c) => switch (this) {
        _Status.fightWeek => c.brand, // red — fight week urgency
        _Status.interview => c.accent, // gold — spotlight
        _Status.trainingCamp => c.success, // green — active camp
        _Status.ranked => c.secondary, // platinum — rank metal
      };
}

class _CornerCard extends StatelessWidget {
  const _CornerCard({required this.fighter, required this.tile});
  final Fighter fighter;
  final double tile;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ring = tile - 14;
    final st = _Status.values[fighter.id.hashCode.abs() % _Status.values.length];
    final stColor = st.color(c);
    final parts = fighter.name.trim().split(RegExp(r'\s+'));
    final last = parts.last;

    return Pressable(
      onTap: () => context.push(AppRoutes.fighterPath(fighter.id)),
      borderRadius: AppRadius.brLg,
      child: SizedBox(
        width: tile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: ring,
              height: ring,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: ring,
                    height: ring,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: stColor, width: 2),
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: c.surface),
                          if (fighter.imageUrl.isNotEmpty)
                            Image(image: appImageProvider(fighter.imageUrl),
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -0.7),
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: -2,
                    bottom: -2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c.surfaceOverlay,
                        shape: BoxShape.circle,
                        border: Border.all(color: stColor, width: 1.5),
                      ),
                      child: Icon(st.icon, size: 14, color: stColor),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapSm,
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                last.toUpperCase(),
                maxLines: 1,
                style: context.text.bodyMedium?.copyWith(
                  letterSpacing: 0.4,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              st.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall
                  ?.copyWith(color: stColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.tile});
  final double tile;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: 4,
      separatorBuilder: (_, __) => AppSpacing.hGapMd,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: AppSkeleton.circle(size: tile - 14),
      ),
    );
  }
}
