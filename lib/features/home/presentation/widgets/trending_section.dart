import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';

const double _kCardWidth = 190;
const double _kImageHeight = 120;
const double _kRail = 186;

class _Item {
  const _Item(this.image, this.icon, this.title, this.time, this.route);
  final String image;
  final IconData icon;
  final String title;
  final String time;
  final String route;
}

/// Horizontally scrolling "Trending" cards, built from the live roster/events.
class TrendingSection extends ConsumerWidget {
  const TrendingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final champsAsync = ref.watch(championsProvider);
    if (champsAsync.isLoading) return const _SectionSkeleton();
    final champs = champsAsync.valueOrNull ?? const [];
    final event = ref.watch(featuredEventProvider).valueOrNull;
    if (champs.length < 2) return const SizedBox.shrink();

    String last(String n) => n.trim().split(RegExp(r'\s+')).last;
    final items = <_Item>[
      _Item(champs[0].imageUrl, Icons.videocam_rounded,
          '${last(champs[0].name)} training footage.', '2h ago',
          AppRoutes.fighterPath(champs[0].id)),
      _Item(champs[1].imageUrl, Icons.bolt_rounded,
          '${last(champs[1].name)} in focus.', '4h ago',
          AppRoutes.fighterPath(champs[1].id)),
      if (event != null)
        _Item(event.heroImage, Icons.photo_camera_rounded,
            '${event.name} media day.', '6h ago',
            AppRoutes.eventPath(event.id)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Trending',
          actionLabel: 'See all',
          onAction: () => context.push(AppRoutes.search),
        ),
        SizedBox(
          height: _kRail,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => AppSpacing.hGapMd,
            itemBuilder: (context, i) => _Card(item: items[i]),
          ),
        ),
      ],
    );
  }
}

/// Placeholder approximating the rail while the roster loads: a header bar
/// plus card-shaped blocks (image, title lines) at the rail's dimensions.
class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeleton(width: 130, height: 20),
        AppSpacing.vGapMd,
        SizedBox(
          height: _kRail,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: 3,
            separatorBuilder: (_, __) => AppSpacing.hGapMd,
            itemBuilder: (_, __) => const SizedBox(
              width: _kCardWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(
                    width: _kCardWidth,
                    height: _kImageHeight,
                    borderRadius: AppRadius.brLg,
                  ),
                  AppSpacing.vGapSm,
                  AppSkeleton(height: 14),
                  AppSpacing.vGapXs,
                  AppSkeleton(width: 64, height: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: () => context.push(item.route),
      borderRadius: AppRadius.brLg,
      child: SizedBox(
        width: _kCardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.brLg,
              child: SizedBox(
                height: _kImageHeight,
                width: _kCardWidth,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: c.surface),
                    if (item.image.isNotEmpty)
                      Image.asset(
                        item.image,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x99000000)],
                          stops: [0.55, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c.brand,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, size: 16, color: c.onBrand),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.vGapSm,
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              item.time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
