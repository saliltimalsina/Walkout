import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_colors.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/pickem_controller.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../widgets/confetti.dart';
import '../widgets/octagon_card.dart';

/// Your card after locking in: live progress, the confidence heatmap,
/// community splits, Pick DNA and a shareable poster.
class PickemResultsScreen extends ConsumerWidget {
  const PickemResultsScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final fightersAsync = ref.watch(fightersProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('YOUR CARD'),
      ),
      body: eventAsync.when(
        loading: () => const AppLoading(),
        error: (_, __) => AppEmptyState.error(
          message: 'We could not load this card.',
          onRetry: () => ref.invalidate(eventProvider(eventId)),
        ),
        data: (event) {
          final card = ref.watch(pickemProvider)[eventId];
          if (card == null || card.picks.isEmpty) {
            return AppEmptyState(
              title: 'No picks yet',
              message: 'Build your card for this event first.',
            );
          }
          final byId = {
            for (final f in fightersAsync.valueOrNull ?? const <Fighter>[])
              f.id: f,
          };
          return _ResultsBody(event: event, card: card, byId: byId);
        },
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.event,
    required this.card,
    required this.byId,
  });

  final Event event;
  final PickCard card;
  final Map<String, Fighter> byId;

  @override
  Widget build(BuildContext context) {
    final bouts = pickableBouts(event);
    final score = scoreCard(card, event);
    final dna = analyzeCard(card, event, byId);
    final locked = score.graded == 0;
    final ordered = card.picks.keys.toList()..sort();

    // Per-pick outcome in pick order: true correct, false wrong, null pending.
    final outcomes = <bool?>[
      for (final i in ordered)
        if (i < bouts.length)
          bouts[i].winnerId == null
              ? null
              : bouts[i].winnerId == card.picks[i]!.fighterId,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        if (locked)
          _LockedHero(event: event, picks: card.picks.length)
        else ...[
          // Score and per-fight progress read as one unit; the share CTA
          // closes the block.
          _ScoreHero(event: event, score: score),
          AppSpacing.vGapMd,
          _FightProgress(outcomes: outcomes),
          AppSpacing.vGapLg,
          AppButton(
            label: 'Share Results',
            icon: Icons.ios_share_rounded,
            isFullWidth: true,
            onPressed: () =>
                context.push(AppRoutes.pickemSharePath(event.id)),
          ),
        ],
        AppSpacing.vGapXl,
        _DnaCard(dna: dna),
        AppSpacing.vGapXl,
        const SectionHeader(title: 'Your Picks'),
        for (final i in ordered)
          if (i < bouts.length)
            _PickRow(
              event: event,
              bout: bouts[i],
              boutIndex: i,
              pick: card.picks[i]!,
              byId: byId,
            ),
        AppSpacing.vGapXl,
        AppButton(
          label: 'Share Card',
          icon: Icons.ios_share_rounded,
          isFullWidth: true,
          onPressed: () =>
              context.push(AppRoutes.pickemSharePath(event.id)),
        ),
        AppSpacing.vGapSm,
        AppButton(
          label: 'Edit Picks',
          variant: AppButtonVariant.secondary,
          isFullWidth: true,
          onPressed: () =>
              context.pushReplacement(AppRoutes.pickemFlowPath(event.id)),
        ),
      ],
    );
  }
}

/// Reading-progress style: one segment per pick, colored by outcome —
/// green when the pick hit, red when it missed, dark gray while pending.
class _FightProgress extends StatelessWidget {
  const _FightProgress({required this.outcomes});

  /// Per-pick outcome in pick order: true correct, false wrong, null pending.
  final List<bool?> outcomes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final total = outcomes.length;
    final done = outcomes.where((o) => o != null).length;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: switch (outcomes[i]) {
                      true => c.success,
                      false => c.danger,
                      null => const Color(0xFF2A2A2C),
                    },
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
        AppSpacing.vGapXs,
        Text(
          '$done / $total fights completed',
          style: t.labelSmall?.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

/// Big "8 / 11 CORRECT" hero with points and a demo rank from accuracy.
/// A perfect card gets the gold treatment: gold border, gold glow and
/// deterministic confetti behind the score.
class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.event, required this.score});

  final Event event;
  final CardScore score;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final accuracy =
        score.graded == 0 ? 0.0 : score.correct / score.graded;
    final rank = (1 + (1 - accuracy) * 400).round();
    final topPct = (100 - accuracy * 97).clamp(1, 99).round();
    final perfect = score.perfect;

    final hero = OctagonCard(
      cut: 18,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A1A1C), Color(0xFF0F0F11)],
      ),
      borderColor:
          perfect ? c.accent.withValues(alpha: 0.7) : const Color(0xFF262628),
      child: Stack(
        children: [
          if (perfect)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ConfettiPainter(
                    colors: [c.accent, c.brand, Colors.white],
                  ),
                ),
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: _heroContent(c, t, rank, topPct),
          ),
        ],
      ),
    );

    if (!perfect) return hero;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const OctagonBorderShape(cut: 18),
        shadows: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.28),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: hero,
    );
  }

  Widget _heroContent(AppColors c, TextTheme t, int rank, int topPct) {
    return Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (score.perfect ? c.accent : c.success)
                  .withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              score.perfect
                  ? Icons.workspace_premium_rounded
                  : Icons.check_rounded,
              color: score.perfect ? c.accent : c.success,
              size: 28,
            ),
          ),
          AppSpacing.vGapMd,
          // The correct count rolls up from 0 when the hero appears.
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score.correct),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '$value / ${score.graded}',
              style: t.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            score.perfect ? 'PERFECT CARD' : 'CORRECT',
            style: t.labelMedium?.copyWith(
              color: score.perfect ? c.accent : c.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          AppSpacing.vGapLg,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroStat(label: 'POINTS', value: '${score.points}'),
              Container(
                width: 1,
                height: 32,
                margin:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                color: const Color(0xFF2A2A2C),
              ),
              _HeroStat(label: 'RANK', value: '#$rank'),
              Container(
                width: 1,
                height: 32,
                margin:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                color: const Color(0xFF2A2A2C),
              ),
              _HeroStat(label: 'TOP', value: '$topPct%'),
            ],
          ),
        ],
      );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      children: [
        Text(
          value,
          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: t.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _LockedHero extends StatelessWidget {
  const _LockedHero({required this.event, required this.picks});

  final Event event;
  final int picks;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return OctagonCard(
      cut: 18,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A1A1C), Color(0xFF0F0F11)],
      ),
      child: Stack(
        children: [
          // Aura: red radial glow behind the lock.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.7),
                  radius: 1.1,
                  colors: [
                    c.brand.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: c.brand.withValues(alpha: 0.16),
                    shape: const OctagonBorderShape(cut: 10),
                  ),
                  child: Icon(Icons.lock_rounded, size: 28, color: c.brand),
                ),
                AppSpacing.vGapMd,
                Text(
                  '$picks PICKS LOCKED IN',
                  style: t.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                AppSpacing.vGapXs,
                Text(
                  'Results appear live on fight night',
                  style: t.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick DNA — how you predict, not just how well.
class _DnaCard extends StatelessWidget {
  const _DnaCard({required this.dna});

  final CardDna dna;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    Widget stat(String value, String label) => Column(
          children: [
            Text(
              value,
              style:
                  t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: t.labelSmall?.copyWith(
                color: c.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        );

    return OctagonCard(
      cut: 16,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E1206), Color(0xFF0F0F11)],
      ),
      borderColor: c.accent.withValues(alpha: 0.4),
      child: Stack(
        children: [
          // Faint concentric octagons watermarked behind the content.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _OctagonWatermarkPainter(
                  color: c.accent.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.allLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'YOUR PICK DNA',
                  textAlign: TextAlign.center,
                  style: t.labelSmall?.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                AppSpacing.vGapSm,
                Text(
                  dna.emoji,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 34),
                ),
                AppSpacing.vGapXs,
                Text(
                  dna.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: t.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                AppSpacing.vGapXs,
                Text(
                  dna.line,
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: c.textSecondary),
                ),
                AppSpacing.vGapLg,
                Row(
                  children: [
                    Expanded(child: stat('${dna.riskScore}', 'RISK SCORE')),
                    Container(
                      width: 1,
                      height: 30,
                      color: c.accent.withValues(alpha: 0.16),
                    ),
                    Expanded(child: stat('${dna.upsets}', 'UPSET PICKS')),
                    Container(
                      width: 1,
                      height: 30,
                      color: c.accent.withValues(alpha: 0.16),
                    ),
                    Expanded(
                        child:
                            stat('${dna.communityMatch}%', 'CROWD MATCH')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Concentric octagon outlines anchored to the card's top-right corner —
/// a quiet texture nod to the cage. Fully deterministic: fixed sizes, no
/// randomness, no clock.
class _OctagonWatermarkPainter extends CustomPainter {
  const _OctagonWatermarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final center = Offset(size.width * 0.9, size.height * 0.22);
    for (final side in const [150.0, 112.0, 74.0]) {
      final rect =
          Rect.fromCenter(center: center, width: side, height: side);
      canvas.drawPath(
        OctagonBorderShape(cut: side * 0.24).getOuterPath(rect),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OctagonWatermarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// One pick: heat dot, your corner, result mark and the two-sided
/// community split.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.event,
    required this.bout,
    required this.boutIndex,
    required this.pick,
    required this.byId,
  });

  final Event event;
  final Bout bout;
  final int boutIndex;
  final FightPick pick;
  final Map<String, Fighter> byId;

  String _last(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final pickedName = byId[pick.fighterId]?.name ??
        (pick.fighterId == bout.redCornerId ? bout.redName : bout.blueName);
    final oppId = pick.fighterId == bout.redCornerId
        ? bout.blueCornerId
        : bout.redCornerId;
    final oppName = byId[oppId]?.name ??
        (pick.fighterId == bout.redCornerId ? bout.blueName : bout.redName);

    final winner = bout.winnerId;
    final correct = winner != null && winner == pick.fighterId;
    final pct = communityPct(event.id, boutIndex, pick.fighterId);
    final upsetWin = correct && pct < 35;

    final heat = pick.percent >= 75
        ? c.success
        : pick.percent >= 40
            ? c.warning
            : c.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: OctagonCard(
        cut: 12,
        padding: AppSpacing.allMd,
        child: Row(
          children: [
            // Leading portrait: result ring around the fighter, heat dot
            // riding the avatar's corner.
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AppAvatar(
                    name: pickedName,
                    imageUrl: byId[pick.fighterId]?.imageUrl ?? '',
                    size: 40,
                    borderColor: winner == null
                        ? null
                        : correct
                            ? c.success
                            : c.danger,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: heat,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF121214),
                          width: 2,
                        ),
                      ),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${pickedName.toUpperCase()}  ·  ${pick.percent}%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (winner == null)
                        Icon(Icons.hourglass_top_rounded,
                            size: 18, color: c.textTertiary)
                      else
                        Icon(
                          correct
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 20,
                          color: correct ? c.success : c.danger,
                        ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  _SplitBar(
                    leftLabel: _last(pickedName).toUpperCase(),
                    rightLabel: _last(oppName).toUpperCase(),
                    leftPct: pct,
                  ),
                  if (upsetWin) ...[
                    AppSpacing.vGapSm,
                    Text(
                      '🔥 UPSET — only $pct% picked ${_last(pickedName)}',
                      style: t.labelSmall?.copyWith(
                        color: c.brand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-sided community split: your corner vs theirs.
class _SplitBar extends StatelessWidget {
  const _SplitBar({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftPct,
  });

  final String leftLabel;
  final String rightLabel;
  final int leftPct;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: leftPct.clamp(5, 95),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: c.brand,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(3)),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: (100 - leftPct).clamp(5, 95),
              child: Container(
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF3A3A3C),
                  borderRadius:
                      BorderRadius.horizontal(right: Radius.circular(3)),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vGapXs,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$leftLabel $leftPct%',
              style: t.labelSmall?.copyWith(
                color: c.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$rightLabel ${100 - leftPct}%',
              style: t.labelSmall?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
