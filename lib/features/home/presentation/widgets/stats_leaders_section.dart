import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/features/events/presentation/widgets/card_label.dart';
import 'package:walkout/shared/widgets/widgets.dart';
import '../providers/home_feed.dart';
import '../../../../shared/widgets/app_image.dart';

const double _kCardWidth = 148;
const double _kRailHeight = 172;

/// Horizontal rail of stat-leader cards: stat label, big value, leader name
/// and a portrait fading up from the bottom-right corner.
class StatsLeadersSection extends ConsumerWidget {
  const StatsLeadersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaders = ref.watch(statsLeadersProvider);
    if (leaders.isEmpty) return const SizedBox.shrink();
    final tiles = leaders.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Stats Leaders',
          actionLabel: 'View all',
          onAction: () => context.go(AppRoutes.rankings),
        ),
        SizedBox(
          height: _kRailHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: tiles.length,
            separatorBuilder: (_, __) => AppSpacing.hGapMd,
            itemBuilder: (context, i) => _LeaderCard(leader: tiles[i]),
          ),
        ),
      ],
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({required this.leader});

  final StatLeader leader;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    return SizedBox(
      width: _kCardWidth,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: AppRadius.brLg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (leader.imageUrl.isNotEmpty)
                Positioned(
                  right: -12,
                  bottom: 0,
                  width: 88,
                  height: 110,
                  child: _FadedPortrait(imageUrl: leader.imageUrl),
                ),
              Padding(
                padding: AppSpacing.allMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leader.label.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelSmall?.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      leader.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.headlineMedium?.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    AppSpacing.vGapSm,
                    Text(
                      leader.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cardLabelStyle(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Portrait pinned to the card's bottom-right, fading out toward its top so
/// it reads as part of the surface behind the stat.
class _FadedPortrait extends StatelessWidget {
  const _FadedPortrait({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: Image(image: appImageProvider(imageUrl),
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.9),
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
