import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/app_card.dart';
import 'package:walkout/shared/widgets/app_skeleton.dart';
import 'package:walkout/shared/widgets/section_header.dart';

class _PulseItem {
  const _PulseItem(
    this.leadingIcon,
    this.iconColor,
    this.time,
    this.title,
    this.thumbImage,
    this.showPlay,
  );
  final IconData leadingIcon;
  final Color iconColor;
  final String time;
  final String title;
  final String thumbImage;
  final bool showPlay;
}

/// "The Pulse" — a live activity feed over the roster and featured event.
class ThePulseSection extends ConsumerWidget {
  const ThePulseSection({super.key});

  static String _lastName(String name) => name.split(' ').last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final champsAsync = ref.watch(championsProvider);
    if (champsAsync.isLoading) return const _SectionSkeleton();
    final champs = champsAsync.valueOrNull ?? const [];
    final event = ref.watch(featuredEventProvider).valueOrNull;
    if (champs.length < 2) return const SizedBox.shrink();

    final items = <_PulseItem>[
      _PulseItem(
        Icons.videocam_rounded,
        c.brand,
        '10m ago',
        '${_lastName(champs[0].name)} posts training footage',
        champs[0].imageUrl,
        true,
      ),
      _PulseItem(
        Icons.event_rounded,
        c.brand,
        '35m ago',
        'Press conference announced',
        event?.heroImage ?? '',
        false,
      ),
      _PulseItem(
        Icons.trending_up_rounded,
        c.brand,
        '2h ago',
        'Fight odds updated',
        champs[1].imageUrl,
        true,
      ),
      _PulseItem(
        Icons.article_rounded,
        c.textSecondary,
        'Yesterday',
        'New fight booked',
        event?.heroImage ?? '',
        false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'The Pulse',
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _PulseRow(item: item),
          ),
      ],
    );
  }
}

/// Placeholder approximating the feed while the roster loads: a header bar
/// plus rows shaped like [_PulseRow] (icon, two text lines, thumb).
class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeleton(width: 120, height: 20),
        AppSpacing.vGapMd,
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                AppSkeleton(width: 44, height: 44, borderRadius: AppRadius.brMd),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 60, height: 10),
                      AppSpacing.vGapXs,
                      AppSkeleton(height: 14),
                    ],
                  ),
                ),
                AppSpacing.hGapMd,
                AppSkeleton(width: 92, height: 60, borderRadius: AppRadius.brMd),
              ],
            ),
          ),
      ],
    );
  }
}

class _PulseRow extends StatelessWidget {
  const _PulseRow({required this.item});
  final _PulseItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: AppSpacing.allSm,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(item.leadingIcon, color: item.iconColor, size: 20),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.time,
                  style: context.text.labelSmall
                      ?.copyWith(color: c.textTertiary),
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          AppSpacing.hGapMd,
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: AppRadius.brMd,
                child: SizedBox(
                  width: 92,
                  height: 60,
                  child: item.thumbImage.isEmpty
                      ? ColoredBox(color: c.surfaceElevated)
                      : Image.asset(
                          item.thumbImage,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.3),
                          errorBuilder: (_, __, ___) =>
                              ColoredBox(color: c.surfaceElevated),
                        ),
                ),
              ),
              if (item.showPlay)
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
