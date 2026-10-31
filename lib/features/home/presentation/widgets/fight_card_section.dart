import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/features/events/presentation/widgets/aura_card.dart';
import 'package:walkout/features/events/presentation/widgets/card_label.dart';
import 'package:walkout/features/events/presentation/widgets/glow_vs.dart';
import 'package:walkout/shared/models/bout.dart';
import 'package:walkout/shared/models/fighter.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';
import '../../../../shared/widgets/app_image.dart';

const double _kRailWidth = 28;
const double _kPortrait = 72;

/// A premium vertical-timeline preview of the next event's marquee bouts.
/// Each bout lives on its own card; a rail of dots links the segments.
class FightCardSection extends ConsumerWidget {
  const FightCardSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(featuredEventProvider);
    if (eventAsync.isLoading) return const _SectionSkeleton();
    final event = eventAsync.valueOrNull;
    if (event == null || event.mainCard.isEmpty) return const SizedBox.shrink();
    final byId = <String, Fighter>{
      for (final f
          in ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[])
        f.id: f,
    };
    final card = event.mainCard;
    final featured = card.length > 2 ? card.sublist(2) : const <Bout>[];
    final shown = featured.take(2).length;
    final total = card.length + event.prelims.length;
    final moreCount = (total - 2 - shown).clamp(0, total);
    void openEvent() => context.push(AppRoutes.eventPath(event.id));
    final segments = <Widget>[
      _MarqueeBoutCard(card[0], byId, 'MAIN EVENT', onTap: openEvent),
      if (card.length > 1)
        _MarqueeBoutCard(card[1], byId, 'CO-MAIN EVENT', onTap: openEvent),
      if (featured.isNotEmpty)
        _FeaturedBoutsCard(featured, byId, moreCount, onTap: openEvent),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Fight Card',
          actionLabel: 'Full Card',
          onAction: openEvent,
        ),
        for (var i = 0; i < segments.length; i++)
          _TimelineSegment(
            first: i == 0,
            last: i == segments.length - 1,
            dot: _DotKind.values[i.clamp(0, _DotKind.values.length - 1)],
            child: segments[i],
          ),
      ],
    );
  }
}

/// Placeholder approximating the section while the featured event loads:
/// a header bar plus two marquee-card blocks offset by the timeline rail.
class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AppSkeleton(width: 150, height: 20),
        AppSpacing.vGapMd,
        Padding(
          padding: EdgeInsets.only(left: _kRailWidth),
          child: AppSkeleton(height: 128, borderRadius: AppRadius.brLg),
        ),
        AppSpacing.vGapSm,
        Padding(
          padding: EdgeInsets.only(left: _kRailWidth),
          child: AppSkeleton(height: 128, borderRadius: AppRadius.brLg),
        ),
      ],
    );
  }
}

enum _DotKind { main, coMain, featured }

class _TimelineSegment extends StatelessWidget {
  const _TimelineSegment({
    required this.first,
    required this.last,
    required this.dot,
    required this.child,
  });
  final bool first;
  final bool last;
  final _DotKind dot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget line(bool visible) => Expanded(
          child: visible
              ? Center(child: Container(width: 2, color: c.divider))
              : const SizedBox.shrink(),
        );
    final size = switch (dot) {
      _DotKind.main => 14.0,
      _DotKind.coMain => 12.0,
      _DotKind.featured => 10.0,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _kRailWidth,
            child: Column(
              children: [
                line(!first),
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dot == _DotKind.main ? c.brand : null,
                    border: dot == _DotKind.main
                        ? null
                        : Border.all(
                            color: dot == _DotKind.coMain
                                ? c.brand
                                : c.brand.withValues(alpha: 0.6),
                            width: dot == _DotKind.coMain ? 2 : 1.5,
                          ),
                    boxShadow: dot == _DotKind.main
                        ? [
                            BoxShadow(
                              color: c.brand.withValues(alpha: 0.45),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                line(!last),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.sm),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeBoutCard extends StatelessWidget {
  const _MarqueeBoutCard(this.bout, this.byId, this.label,
      {required this.onTap});
  final Bout bout;
  final Map<String, Fighter> byId;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final red = byId[bout.redCornerId];
    final blue = byId[bout.blueCornerId];
    final redName = red?.name ?? bout.redName;
    final blueName = blue?.name ?? bout.blueName;
    final wl = bout.weightLabel.isNotEmpty
        ? bout.weightLabel
        : bout.weightClass.label;
    final sub = bout.isTitleFight ? '$wl Championship' : '$wl Bout';
    final nameStyle = t.titleLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      height: 1.6,
    );
    Widget name(String n) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            n.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            style: nameStyle,
          ),
        );
    return AuraCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FadedPortrait(imageUrl: red?.imageUrl ?? ''),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.xs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: cardLabelStyle(context)),
                  AppSpacing.vGapSm,
                  name(redName),
                  const GlowVs(size: 11),
                  name(blueName),
                  AppSpacing.vGapSm,
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      sub,
                      maxLines: 1,
                      style: t.bodySmall
                          ?.copyWith(color: c.textSecondary, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _FadedPortrait(imageUrl: blue?.imageUrl ?? ''),
        ],
      ),
    );
  }
}

/// Rectangular headshot that melts into the card: fades out toward the
/// bottom so the portrait reads as part of the surface, not a sticker.
class _FadedPortrait extends StatelessWidget {
  const _FadedPortrait({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const SizedBox(width: _kPortrait);
    return SizedBox(
      width: _kPortrait,
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.45, 0.92],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: Image(image: appImageProvider(imageUrl),
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.9),
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _FeaturedBoutsCard extends StatelessWidget {
  const _FeaturedBoutsCard(this.bouts, this.byId, this.moreCount,
      {required this.onTap});
  final List<Bout> bouts;
  final Map<String, Fighter> byId;
  final int moreCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final nameStyle = t.titleLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
      height: 1.5,
    );
    String corner(String id, String fallback) =>
        _lastName(byId[id]?.name ?? fallback).toUpperCase();
    return AuraCard(
      onTap: onTap,
      glowAlpha: 0.12,
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          children: [
            Text('FEATURED BOUTS', style: cardLabelStyle(context)),
            AppSpacing.vGapSm,
            for (final b in bouts.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: corner(b.redCornerId, b.redName)),
                      GlowVs.span(context, size: 10),
                      TextSpan(text: corner(b.blueCornerId, b.blueName)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: nameStyle,
                ),
              ),
            if (moreCount > 0) ...[
              AppSpacing.vGapXs,
              Text(
                'And $moreCount more bouts',
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _lastName(String name) {
  final parts = name.trim().split(' ');
  return parts.isEmpty || parts.last.isEmpty ? name.trim() : parts.last;
}
