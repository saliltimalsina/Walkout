import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/app_card.dart';
import 'package:walkout/shared/widgets/app_skeleton.dart';
import 'package:walkout/shared/widgets/section_header.dart';

class _Story {
  const _Story(this.image, this.title, this.time, this.route);
  final String image;
  final String title;
  final String time;
  final String? route;
}

/// "Latest Stories" — a news list over the live roster and featured event.
class LatestStoriesSection extends ConsumerWidget {
  const LatestStoriesSection({super.key});

  static String _lastName(String name) => name.split(' ').last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final champsAsync = ref.watch(championsProvider);
    if (champsAsync.isLoading) return const _SectionSkeleton();
    final champs = champsAsync.valueOrNull ?? const [];
    final event = ref.watch(featuredEventProvider).valueOrNull;
    if (champs.length < 2) return const SizedBox.shrink();

    final stories = <_Story>[
      if (event != null)
        _Story(
          event.heroImage,
          '${event.subtitle} faceoffs: intensity at its peak',
          '3h ago',
          AppRoutes.eventPath(event.id),
        ),
      _Story(
        champs[0].imageUrl,
        "Behind the scenes of ${_lastName(champs[0].name)}'s camp",
        '5h ago',
        AppRoutes.fighterPath(champs[0].id),
      ),
      _Story(
        champs[1].imageUrl,
        '${_lastName(champs[1].name)} in the spotlight',
        '7h ago',
        AppRoutes.fighterPath(champs[1].id),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Latest Stories',
        ),
        for (final s in stories)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _StoryRow(story: s),
          ),
      ],
    );
  }
}

/// Placeholder approximating the list while the roster loads: a header bar
/// plus rows shaped like [_StoryRow] (thumb and two text lines).
class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeleton(width: 160, height: 20),
        AppSpacing.vGapMd,
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                AppSkeleton(
                  width: 120,
                  height: 84,
                  borderRadius: AppRadius.brMd,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(height: 16),
                      AppSpacing.vGapXs,
                      AppSkeleton(width: 72, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StoryRow extends StatelessWidget {
  const _StoryRow({required this.story});
  final _Story story;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final route = story.route;
    return AppCard(
      onTap: route == null ? null : () => context.push(route),
      padding: AppSpacing.allSm,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.brMd,
            child: SizedBox(
              width: 120,
              height: 84,
              child: story.image.isEmpty
                  ? ColoredBox(color: c.surfaceElevated)
                  : Image.asset(
                      story.image,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.3),
                      errorBuilder: (_, __, ___) =>
                          ColoredBox(color: c.surfaceElevated),
                    ),
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                AppSpacing.vGapXs,
                Text(
                  story.time,
                  style: context.text.labelSmall
                      ?.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
