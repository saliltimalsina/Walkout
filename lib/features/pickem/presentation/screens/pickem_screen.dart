import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/pickem_controller.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../widgets/friends_league_card.dart';
import '../widgets/octagon_card.dart';
import '../../../../shared/widgets/app_image.dart';

/// Pick'Em hub: the next card to play, your streaks, the friends league and
/// your scored past cards.
class PickemScreen extends ConsumerWidget {
  const PickemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingEventsProvider);
    final pastAsync = ref.watch(pastEventsProvider);
    final upcoming = upcomingAsync.valueOrNull ?? const <Event>[];
    final past = pastAsync.valueOrNull ?? const <Event>[];
    // First load only — refreshes keep showing the previous data.
    final loading = (upcomingAsync.isLoading && !upcomingAsync.hasValue) ||
        (pastAsync.isLoading && !pastAsync.hasValue);
    final cards = ref.watch(pickemProvider);

    final pastById = {for (final e in past) e.id: e};
    final playedCards = cards.values
        .where((c) => c.submitted && pastById.containsKey(c.eventId))
        .toList();
    final scores = [
      for (final c in playedCards) scoreCard(c, pastById[c.eventId]!),
    ];
    final perfect = scores.where((s) => s.perfect).length;
    final totalPoints = scores.fold<int>(0, (a, s) => a + s.points);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              "PICK'EM",
              style: context.text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              'Predict. Compete. Share.',
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.textSecondary),
            ),
            AppSpacing.vGapLg,
            if (loading)
              const _HubSkeleton()
            else ...[
              if (upcoming.isNotEmpty) ...[
                _NextCardHero(event: upcoming.first),
                if (upcoming.length > 1) ...[
                  AppSpacing.vGapXl,
                  const SectionHeader(title: 'More Events'),
                  for (final e in upcoming.skip(1).take(3)) ...[
                    _MiniEventRow(event: e),
                    AppSpacing.vGapSm,
                  ],
                ],
              ] else
                const AppEmptyState(
                  title: 'No upcoming events',
                  message: 'Check back when the next card is announced.',
                ),
              AppSpacing.vGapXl,
              _StreaksRow(
                cardsPlayed: playedCards.length,
                perfectCards: perfect,
                totalPoints: totalPoints,
              ),
            ],
            AppSpacing.vGapXl,
            const SectionHeader(title: 'Friends League'),
            FriendsLeagueCard(userPoints: totalPoints),
            if (playedCards.isNotEmpty) ...[
              AppSpacing.vGapXl,
              const SectionHeader(title: 'Past Cards'),
              for (var i = 0; i < playedCards.length; i++) ...[
                if (i > 0) AppSpacing.vGapSm,
                _PastCardRow(
                  event: pastById[playedCards[i].eventId]!,
                  score: scores[i],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Hero card for the next event: matchup, lock countdown, pick progress CTA.
class _NextCardHero extends ConsumerWidget {
  const _NextCardHero({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final card = ref.watch(pickemProvider)[event.id];
    final byId = <String, Fighter>{
      for (final f
          in ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[])
        f.id: f,
    };
    final main = event.mainEvent;
    final redImg = main == null ? '' : (byId[main.redCornerId]?.imageUrl ?? '');
    final blueImg =
        main == null ? '' : (byId[main.blueCornerId]?.imageUrl ?? '');

    final total = event.mainCard.length;
    final made = card?.picks.keys.where((i) => i < total).length ?? 0;
    final submitted = card?.submitted ?? false;

    final closed = event.date.isBefore(DateTime.now());

    final ctaLabel = submitted
        ? 'View Your Card'
        : closed
            ? 'View Card'
            : made == 0
                ? 'Make Picks'
                : 'Continue Picks  ·  $made/$total';

    Widget edgePortrait(String img, bool left) => img.isEmpty
        ? const SizedBox.shrink()
        : Positioned(
            top: 0,
            bottom: 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            width: 120,
            child: Opacity(
              opacity: 0.9,
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: left ? Alignment.centerLeft : Alignment.centerRight,
                  end: left ? Alignment.centerRight : Alignment.centerLeft,
                  colors: const [Colors.white, Colors.transparent],
                  stops: const [0.3, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, 0.72, 1.0],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image(image: appImageProvider(img),
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.9),
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );

    return Pressable(
      onTap: () => context.push(
        submitted
            ? AppRoutes.pickemResultsPath(event.id)
            : AppRoutes.pickemFlowPath(event.id),
      ),
      semanticLabel: event.name,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const ShapeDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1C), Color(0xFF0F0F11)],
          ),
          shape: OctagonBorderShape(
            cut: 18,
            side: BorderSide(color: Color(0xFF262628)),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1.1,
                    colors: [
                      c.brand.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 168,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      edgePortrait(redImg, true),
                      edgePortrait(blueImg, false),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 110,
                          vertical: AppSpacing.md,
                        ),
                        // Scale-to-fit: long matchup names (or a large system
                        // font) shrink the whole block instead of overflowing
                        // the fixed-height poster zone.
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (event.eventType.isEmpty
                                          ? event.name
                                          : event.eventType)
                                      .toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: t.labelMedium?.copyWith(
                                    color: c.brand,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                AppSpacing.vGapSm,
                                _MatchupLine(
                                  subtitle: event.subtitle.isEmpty
                                      ? event.name
                                      : event.subtitle,
                                  stacked: true,
                                ),
                                AppSpacing.vGapSm,
                                _ClosesInChip(closesAt: event.date),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hairline seam between the poster zone and the CTA
                      // zone — fades out toward both edges.
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF2E2E30),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Text(
                        '$total MAIN CARD FIGHTS  •  '
                        '${event.date.mediumDate.toUpperCase()}',
                        textAlign: TextAlign.center,
                        style: t.labelSmall?.copyWith(
                          color: c.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      if (made > 0 && !submitted) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: made / total,
                            minHeight: 5,
                            backgroundColor: const Color(0xFF2A2A2C),
                            valueColor: AlwaysStoppedAnimation(c.brand),
                          ),
                        ),
                        AppSpacing.vGapMd,
                      ],
                      AppButton(
                        label: ctaLabel,
                        isFullWidth: true,
                        onPressed: () => context.push(
                          submitted
                              ? AppRoutes.pickemResultsPath(event.id)
                              : AppRoutes.pickemFlowPath(event.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholders mirroring the hero card and the three streak cells.
class _HubSkeleton extends StatelessWidget {
  const _HubSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSkeleton(height: 284, borderRadius: AppRadius.brLg),
        AppSpacing.vGapXl,
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) AppSpacing.hGapMd,
              const Expanded(
                child: AppSkeleton(height: 96, borderRadius: AppRadius.brLg),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// "Closes in 2h 14m" pill that re-renders every minute so the countdown
/// actually ticks; reads "Locked" once the card closes.
class _ClosesInChip extends StatefulWidget {
  const _ClosesInChip({required this.closesAt});

  final DateTime closesAt;

  @override
  State<_ClosesInChip> createState() => _ClosesInChipState();
}

class _ClosesInChipState extends State<_ClosesInChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final closesIn = widget.closesAt.difference(DateTime.now());
    final locked = closesIn.isNegative;
    final urgent = !locked && closesIn.inHours < 24;
    final label = locked
        ? 'Locked'
        : closesIn.inDays >= 1
            ? 'Closes in ${closesIn.inDays}d ${closesIn.inHours % 24}h'
            : 'Closes in ${closesIn.inHours}h ${closesIn.inMinutes % 60}m';
    final fg = urgent ? c.brand : c.textSecondary;

    // FittedBox: the chip sits in the narrow gap between the hero
    // portraits — the label flexes/ellipsizes so it never overflows the
    // narrow gap on small widths.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: urgent
            ? c.brand.withValues(alpha: 0.14)
            : const Color(0xE6262628),
        borderRadius: AppRadius.brPill,
        border: urgent
            ? Border.all(color: c.brand.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            locked ? Icons.lock_rounded : Icons.timer_outlined,
            size: 11,
            color: fg,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "JONES VS ASPINALL" with the house red glowing VS. In [stacked] mode the
/// names sit on two lines with the VS between them — fits between portraits.
class _MatchupLine extends StatelessWidget {
  const _MatchupLine({required this.subtitle, this.stacked = false});

  final String subtitle;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final parts = subtitle.split(RegExp(r'\s+vs\.?\s+', caseSensitive: false));
    final style = t.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.05,
    );
    // House glowing VS: red w800 with the double halo (tight + wide).
    final vsStyle = TextStyle(
      color: c.brand,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
      shadows: [
        Shadow(
          color: c.brand.withValues(alpha: 0.9),
          blurRadius: 16,
        ),
        Shadow(
          color: c.brand.withValues(alpha: 0.45),
          blurRadius: 32,
        ),
      ],
    );

    if (parts.length != 2) {
      return Text(
        subtitle.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: stacked ? TextAlign.center : TextAlign.start,
        style: style,
      );
    }

    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(parts[0].toUpperCase(), maxLines: 1, style: style),
          ),
          Text('VS', style: vsStyle),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(parts[1].toUpperCase(), maxLines: 1, style: style),
          ),
        ],
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: parts[0].toUpperCase()),
            TextSpan(text: '  VS  ', style: vsStyle),
            TextSpan(text: parts[1].toUpperCase()),
          ],
        ),
        maxLines: 1,
        style: style,
      ),
    );
  }
}

class _MiniEventRow extends ConsumerWidget {
  const _MiniEventRow({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final card = ref.watch(pickemProvider)[event.id];
    final made = card?.picks.length ?? 0;
    final total = pickableBouts(event).length;
    final byId = <String, Fighter>{
      for (final f
          in ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[])
        f.id: f,
    };
    final main = event.mainEvent;
    final red = main == null ? null : byId[main.redCornerId];
    final blue = main == null ? null : byId[main.blueCornerId];

    return Pressable(
      onTap: () => context.push(AppRoutes.pickemFlowPath(event.id)),
      semanticLabel: event.name,
      child: OctagonCard(
        cut: 12,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 36,
              child: Stack(
                children: [
                  AppAvatar(
                    name: red?.name ?? '?',
                    imageUrl: red?.imageUrl ?? '',
                    size: 36,
                  ),
                  Positioned(
                    left: 22,
                    child: AppAvatar(
                      name: blue?.name ?? '?',
                      imageUrl: blue?.imageUrl ?? '',
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.subtitle.isEmpty ? event.name : event.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    made > 0
                        ? '$made/$total picked'
                        : (event.eventType.isEmpty
                            ? event.name
                            : event.eventType),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(
                      color: made > 0 ? c.brand : c.textSecondary,
                      fontWeight: made > 0 ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            // Right-aligned date block: month overline over the day numeral.
            Container(
              width: 1,
              height: 28,
              color: const Color(0xFF232325),
            ),
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Text(
                    event.date.monthShort.toUpperCase(),
                    style: t.labelSmall?.copyWith(
                      fontSize: 9,
                      color: c.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${event.date.day}',
                    style: t.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Cards played / perfect cards / season points.
class _StreaksRow extends StatelessWidget {
  const _StreaksRow({
    required this.cardsPlayed,
    required this.perfectCards,
    required this.totalPoints,
  });

  final int cardsPlayed;
  final int perfectCards;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    Widget cell(String emoji, String value, String label, {Color? tint}) =>
        Expanded(
          child: OctagonCard(
            cut: 12,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF17171A), Color(0xFF101012)],
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.xs,
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 15)),
                AppSpacing.vGapSm,
                Text(
                  value,
                  style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: tint,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelSmall?.copyWith(
                    fontSize: 10,
                    color: c.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );

    // IntrinsicHeight bounds the Row's height so `stretch` can equalize the
    // three cards. Without it, stretch inside the unbounded ListView gives
    // children infinite height — which silently breaks the whole hub's
    // layout and hit-testing (taps stop registering).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cell('🔥', '$cardsPlayed', 'CARDS PLAYED'),
          AppSpacing.hGapSm,
          cell(
            '🏆',
            '$perfectCards',
            'PERFECT CARDS',
            tint: perfectCards > 0 ? c.accent : null,
          ),
          AppSpacing.hGapSm,
          cell('⚡', '$totalPoints', 'SEASON PTS'),
        ],
      ),
    );
  }
}

class _PastCardRow extends StatelessWidget {
  const _PastCardRow({required this.event, required this.score});

  final Event event;
  final CardScore score;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onTap: () => context.push(AppRoutes.pickemResultsPath(event.id)),
      semanticLabel: event.name,
      child: OctagonCard(
        cut: 12,
        borderColor: score.perfect
            ? c.accent.withValues(alpha: 0.45)
            : const Color(0xFF262628),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (score.perfect) ...[
                        Icon(Icons.workspace_premium_rounded,
                            size: 14, color: c.accent),
                        AppSpacing.hGapXs,
                      ],
                      Flexible(
                        child: Text(
                          event.eventType.isEmpty
                              ? event.name
                              : event.eventType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    score.perfect
                        ? 'Perfect card • ${score.correct} / ${score.graded}'
                        : '${score.correct} / ${score.graded} correct',
                    style: t.bodySmall?.copyWith(
                      color: score.perfect ? c.accent : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${score.points} PTS',
              style: t.labelMedium?.copyWith(
                color: score.perfect ? c.accent : c.brand,
                fontWeight: FontWeight.w800,
              ),
            ),
            AppSpacing.hGapSm,
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
