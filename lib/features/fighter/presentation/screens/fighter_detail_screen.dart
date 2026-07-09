import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/favorites_controller.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../widgets/fighter_bio_card.dart';
import '../widgets/fighter_stats_section.dart';
import '../widgets/finish_breakdown.dart';
import '../widgets/tale_of_the_tape.dart';

/// One completed bout from this fighter's point of view.
class _HistoryEntry {
  const _HistoryEntry({
    required this.event,
    required this.bout,
    required this.won,
    required this.opponentId,
    required this.opponentName,
  });

  final Event event;
  final Bout bout;
  final bool won;
  final String opponentId;
  final String opponentName;
}

/// Aura fighter profile: glowing hero with follow, overview / fight history /
/// stats tabs, stat tiles, last-5 rail, win-method donut and derived
/// career highlights.
class FighterDetailScreen extends ConsumerStatefulWidget {
  const FighterDetailScreen({super.key, required this.fighterId});

  final String fighterId;

  @override
  ConsumerState<FighterDetailScreen> createState() =>
      _FighterDetailScreenState();
}

class _FighterDetailScreenState extends ConsumerState<FighterDetailScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final fighterAsync = ref.watch(fighterProvider(widget.fighterId));

    return Scaffold(
      backgroundColor: context.colors.background,
      body: fighterAsync.when(
        data: _buildBody,
        loading: () => const AppLoading(label: 'Loading fighter…'),
        error: (error, _) => AppEmptyState.error(
          message: "We couldn't load this fighter.",
          onRetry: () => ref.invalidate(fighterProvider(widget.fighterId)),
        ),
      ),
    );
  }

  Widget _buildBody(Fighter fighter) {
    final byId = <String, Fighter>{
      for (final f
          in ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[])
        f.id: f,
    };
    final past =
        ref.watch(pastEventsProvider).valueOrNull ?? const <Event>[];

    final history = <_HistoryEntry>[];
    final sorted = [...past]..sort((a, b) => b.date.compareTo(a.date));
    for (final e in sorted) {
      for (final b in [...e.mainCard, ...e.prelims]) {
        if (b.winnerId == null) continue;
        final isRed = b.redCornerId == fighter.id;
        final isBlue = b.blueCornerId == fighter.id;
        if (!isRed && !isBlue) continue;
        final oppId = isRed ? b.blueCornerId : b.redCornerId;
        history.add(_HistoryEntry(
          event: e,
          bout: b,
          won: b.winnerId == fighter.id,
          opponentId: oppId,
          opponentName:
              byId[oppId]?.name ?? (isRed ? b.blueName : b.redName),
        ));
      }
    }

    var streak = 0;
    for (final h in history) {
      if (!h.won) break;
      streak++;
    }

    final bottomInset = context.viewPadding.bottom + AppSpacing.xl;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _FighterHero(fighter: fighter, streak: streak),
        ),
        SliverToBoxAdapter(
          child: _ProfileTabs(
            selected: _tab,
            onSelected: (i) => setState(() => _tab = i),
          ),
        ),
        SliverToBoxAdapter(
          child: ResponsiveCenter(
            maxWidth: 640,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...switch (_tab) {
                  1 => _historyTab(history, byId),
                  2 => _statsTab(fighter),
                  _ => _overviewTab(fighter, history, streak, byId),
                },
                SizedBox(height: bottomInset),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _overviewTab(Fighter fighter, List<_HistoryEntry> history,
      int streak, Map<String, Fighter> byId) {
    final opponents = <String>[];
    for (final h in history) {
      if (h.opponentId.isNotEmpty &&
          byId.containsKey(h.opponentId) &&
          !opponents.contains(h.opponentId)) {
        opponents.add(h.opponentId);
      }
    }

    return [
      _StatTiles(fighter: fighter),
      AppSpacing.vGapLg,
      _PhysicalRow(fighter: fighter),
      if (history.isNotEmpty) ...[
        AppSpacing.vGapXl,
        SectionHeader(
          title: 'Last ${math.min(5, history.length)} Fights',
          actionLabel: history.length > 5 ? 'View all' : null,
          onAction:
              history.length > 5 ? () => setState(() => _tab = 1) : null,
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: math.min(5, history.length),
            separatorBuilder: (_, __) => AppSpacing.hGapMd,
            itemBuilder: (context, i) =>
                _FightCard(entry: history[i], byId: byId),
          ),
        ),
      ],
      if (fighter.record.wins > 0) ...[
        AppSpacing.vGapXl,
        _WinByMethodCard(fighter: fighter),
      ],
      ..._highlights(fighter, streak),
      if (opponents.isNotEmpty) ...[
        AppSpacing.vGapXl,
        const SectionHeader(title: 'Notable Opponents'),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: opponents.length,
            separatorBuilder: (_, __) => AppSpacing.hGapMd,
            itemBuilder: (context, i) {
              final opp = byId[opponents[i]]!;
              return Pressable(
                onTap: () =>
                    context.push(AppRoutes.fighterPath(opp.id)),
                semanticLabel: opp.name,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      AppAvatar(
                          name: opp.name,
                          imageUrl: opp.imageUrl,
                          size: 56),
                      AppSpacing.vGapXs,
                      Text(
                        _lastName(opp.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelSmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
      if (fighter.bio.isNotEmpty) ...[
        AppSpacing.vGapXl,
        FighterBioCard(bio: fighter.bio),
      ],
    ];
  }

  List<Widget> _highlights(Fighter fighter, int streak) {
    final c = context.colors;
    final items = <(IconData, Color, String)>[
      if (fighter.isChampion)
        (
          Icons.workspace_premium_rounded,
          c.accent,
          'UFC ${fighter.weightClass.label} Champion',
        )
      else if (fighter.rankingPosition != null)
        (
          AppIcons.ranking,
          c.brand,
          '#${fighter.rankingPosition} ${fighter.weightClass.label}',
        ),
      if (streak >= 2)
        (Icons.bolt_rounded, c.accent, '$streak Fight Win Streak'),
      if (fighter.winsByKo > 0)
        (
          Icons.sports_mma_rounded,
          c.brand,
          '${fighter.winsByKo} Wins by KO/TKO',
        ),
      if (fighter.winsBySub > 0)
        (
          Icons.front_hand_rounded,
          c.accent,
          '${fighter.winsBySub} Wins by Submission',
        ),
    ];
    if (items.isEmpty) return const [];
    return [
      AppSpacing.vGapXl,
      const SectionHeader(title: 'Career Highlights'),
      Container(
        padding: AppSpacing.allMd,
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          border: Border.all(color: const Color(0xFF262628)),
          color: const Color(0xFF121214),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) AppSpacing.vGapMd,
              Row(
                children: [
                  Icon(items[i].$1, size: 18, color: items[i].$2),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(
                      items[i].$3,
                      style: context.text.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _historyTab(
      List<_HistoryEntry> history, Map<String, Fighter> byId) {
    if (history.isEmpty) {
      return const [
        AppEmptyState(
          title: 'No fights on record',
          message: 'Completed fights will appear here.',
        ),
      ];
    }
    return [
      for (var i = 0; i < history.length; i++) ...[
        if (i > 0) AppSpacing.vGapMd,
        _HistoryRow(entry: history[i], byId: byId),
      ],
    ];
  }

  List<Widget> _statsTab(Fighter fighter) => [
        TaleOfTheTape(fighter: fighter),
        AppSpacing.vGapLg,
        FinishBreakdown(fighter: fighter),
        AppSpacing.vGapLg,
        FighterStatsSection(stats: fighter.stats),
      ];
}

/// Hero: portrait rising out of a gold (champion) or red aura, crown line,
/// stacked name, flag, record + streak and the follow button.
class _FighterHero extends ConsumerWidget {
  const _FighterHero({required this.fighter, required this.streak});

  final Fighter fighter;
  final int streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final aura = fighter.isChampion ? c.accent : c.brand;
    final following = ref.watch(favoritesProvider).contains(fighter.id);

    final names = fighter.name.trim().split(RegExp(r'\s+'));

    return SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Aura glow behind the portrait.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -0.1),
                  radius: 0.9,
                  colors: [
                    aura.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          if (fighter.imageUrl.isNotEmpty)
            Align(
              alignment: Alignment.topRight,
              child: FractionallySizedBox(
                widthFactor: 0.62,
                heightFactor: 0.98,
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.transparent
                    ],
                    stops: [0.0, 0.75, 1.0],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [Colors.white, Colors.transparent],
                      stops: [0.6, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      fighter.imageUrl,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.8),
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIconButton(
                        icon: AppIcons.back,
                        tooltip: 'Back',
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      AppIconButton(
                        icon: following
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        tooltip:
                            following ? 'Unfollow' : 'Follow',
                        onPressed: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(fighter.id),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RankLine(fighter: fighter),
                        AppSpacing.vGapSm,
                        for (final part in names)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              part.toUpperCase(),
                              maxLines: 1,
                              style: t.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.02,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        if (fighter.country.isNotEmpty) ...[
                          AppSpacing.vGapSm,
                          Text(
                            [
                              if (fighter.flag.isNotEmpty) fighter.flag,
                              fighter.country.toUpperCase(),
                            ].join(' '),
                            style: t.labelMedium?.copyWith(
                              color: c.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                        AppSpacing.vGapSm,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fighter.record.display,
                              style: t.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (streak >= 2) ...[
                              AppSpacing.hGapMd,
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  '$streak FIGHT\nWIN STREAK',
                                  style: t.labelSmall?.copyWith(
                                    color: c.brand,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        AppSpacing.vGapMd,
                        AppButton(
                          label: following ? 'Following' : '+ Follow',
                          variant: following
                              ? AppButtonVariant.secondary
                              : AppButtonVariant.primary,
                          onPressed: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(fighter.id),
                        ),
                        AppSpacing.vGapMd,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold crown champion line, red rank line, or plain division label.
class _RankLine extends StatelessWidget {
  const _RankLine({required this.fighter});

  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    if (fighter.isChampion) {
      return Row(
        children: [
          Icon(Icons.workspace_premium_rounded, size: 18, color: c.accent),
          AppSpacing.hGapXs,
          Text(
            '${fighter.weightClass.label} Champion'.toUpperCase(),
            style: t.labelMedium?.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      );
    }
    final label = fighter.rankingPosition != null
        ? '#${fighter.rankingPosition} ${fighter.weightClass.label}'
        : fighter.weightClass.label;
    return Text(
      label.toUpperCase(),
      style: t.labelMedium?.copyWith(
        color: fighter.rankingPosition != null ? c.brand : c.textSecondary,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// OVERVIEW / FIGHT HISTORY / STATS with a red underline.
class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const _labels = ['OVERVIEW', 'FIGHT HISTORY', 'STATS'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF232325))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: Pressable(
                onTap: () => onSelected(i),
                semanticLabel: _labels[i],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected == i
                            ? c.brand
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _labels[i],
                        maxLines: 1,
                        style: t.labelMedium?.copyWith(
                          color: selected == i
                              ? c.brand
                              : c.textSecondary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// KO rate / accuracy / takedown defense / finish rate tiles with bars.
class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.fighter});

  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wins = fighter.record.wins;
    final koRate = wins == 0 ? 0.0 : fighter.winsByKo / wins * 100;
    final finishRate = wins == 0
        ? 0.0
        : (fighter.winsByKo + fighter.winsBySub) / wins * 100;

    final tiles = <(IconData, String, double, Color)>[
      (Icons.sports_mma_rounded, 'KO RATE', koRate, c.brand),
      (
        Icons.gps_fixed_rounded,
        'SIG. STRIKE ACC.',
        fighter.stats.strikingAccuracy,
        c.secondary,
      ),
      (
        Icons.shield_rounded,
        'TAKEDOWN DEF.',
        fighter.stats.takedownDefense,
        c.success,
      ),
      (Icons.bolt_rounded, 'FINISH RATE', finishRate, c.accent),
    ];

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: tiles.length,
        separatorBuilder: (_, __) => AppSpacing.hGapMd,
        itemBuilder: (context, i) {
          final (icon, label, value, color) = tiles[i];
          return Container(
            width: 150,
            padding: AppSpacing.allMd,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              border: Border.all(color: const Color(0xFF262628)),
              color: const Color(0xFF121214),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: color),
                    AppSpacing.hGapXs,
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelSmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${value.round()}%',
                  style: context.text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                AppSpacing.vGapSm,
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (value / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: const Color(0xFF2A2A2C),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Height / reach / stance / age strip.
class _PhysicalRow extends StatelessWidget {
  const _PhysicalRow({required this.fighter});

  final Fighter fighter;

  String get _height {
    if (fighter.heightCm == 0) return '—';
    final inches = fighter.heightCm / 2.54;
    final ft = inches ~/ 12;
    final inch = (inches % 12).round();
    return "$ft'$inch\"";
  }

  String get _reach {
    if (fighter.reachCm == 0) return '—';
    return '${(fighter.reachCm / 2.54).round()}"';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    final cells = <(IconData, String, String, String)>[
      (
        Icons.straighten_rounded,
        'HEIGHT',
        _height,
        fighter.heightCm == 0 ? '' : '${fighter.heightCm} cm',
      ),
      (
        Icons.open_in_full_rounded,
        'REACH',
        _reach,
        fighter.reachCm == 0 ? '' : '${fighter.reachCm} cm',
      ),
      (Icons.sports_martial_arts_rounded, 'STANCE', fighter.stance, ''),
      (
        Icons.event_rounded,
        'AGE',
        fighter.age == 0 ? '—' : '${fighter.age}',
        '',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        border: Border.all(color: const Color(0xFF262628)),
        color: const Color(0xFF121214),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) Container(width: 1, height: 40, color: c.divider),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cells[i].$1,
                          size: 13, color: c.textTertiary),
                      AppSpacing.hGapXs,
                      Text(
                        cells[i].$2,
                        style: t.labelSmall?.copyWith(
                          color: c.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapXs,
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cells[i].$3,
                      maxLines: 1,
                      style: t.titleLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (cells[i].$4.isNotEmpty)
                    Text(
                      cells[i].$4,
                      style: t.labelSmall
                          ?.copyWith(color: c.textTertiary),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Last-fights rail card: result badge, opponent portrait, method and date.
class _FightCard extends StatelessWidget {
  const _FightCard({required this.entry, required this.byId});

  final _HistoryEntry entry;
  final Map<String, Fighter> byId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final opp = byId[entry.opponentId];
    final result = entry.won ? 'WIN' : 'LOSS';
    final resultColor = entry.won ? c.success : c.danger;

    return Pressable(
      onTap: () => context.push(AppRoutes.eventPath(entry.event.id)),
      semanticLabel: 'vs ${entry.opponentName}',
      child: Container(
        width: 132,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          border: Border.all(color: const Color(0xFF262628)),
          color: const Color(0xFF121214),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if ((opp?.imageUrl ?? '').isNotEmpty)
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent
                        ],
                        stops: [0.0, 0.65, 1.0],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        opp!.imageUrl,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.9),
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: resultColor,
                        borderRadius: AppRadius.brSm,
                      ),
                      child: Text(
                        result,
                        style: t.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'vs ',
                          style: t.labelSmall
                              ?.copyWith(color: resultColor),
                        ),
                        TextSpan(
                            text: _lastName(entry.opponentName)),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    [
                      if (entry.bout.method.isNotEmpty)
                        entry.bout.method,
                      if (entry.bout.finishRound.isNotEmpty)
                        entry.bout.finishRound,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall
                        ?.copyWith(color: c.textSecondary),
                  ),
                  Text(
                    entry.event.date.mediumDate,
                    maxLines: 1,
                    style: t.labelSmall
                        ?.copyWith(color: c.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Win-method donut with legend.
class _WinByMethodCard extends StatelessWidget {
  const _WinByMethodCard({required this.fighter});

  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final ko = fighter.winsByKo;
    final dec = fighter.winsByDec;
    final sub = fighter.winsBySub;
    final total = math.max(1, ko + dec + sub);
    final wins = fighter.record.wins;

    Widget legend(Color color, String label, int count) => Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Text(
                label,
                style:
                    t.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ),
            Text(
              '$count (${(count / total * 100).round()}%)',
              style: t.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

    return Container(
      padding: AppSpacing.allMd,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        border: Border.all(color: const Color(0xFF262628)),
        color: const Color(0xFF121214),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WIN BY METHOD',
            style: t.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _DonutPainter(
                        segments: [
                          (ko / total, c.brand),
                          (sub / total, c.accent),
                          (dec / total, c.textSecondary),
                        ],
                        track: const Color(0xFF2A2A2C),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$wins',
                            style: t.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          Text(
                            'WINS',
                            style: t.labelSmall?.copyWith(
                              color: c.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hGapLg,
              Expanded(
                child: Column(
                  children: [
                    legend(c.brand, 'KO/TKO', ko),
                    AppSpacing.vGapSm,
                    legend(c.accent, 'SUBMISSION', sub),
                    AppSpacing.vGapSm,
                    legend(c.textSecondary, 'DECISION', dec),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.track});

  final List<(double, Color)> segments;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const stroke = 12.0;
    final arcRect = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    paint.color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, paint);

    var start = -math.pi / 2;
    for (final (fraction, color) in segments) {
      if (fraction <= 0) continue;
      final sweep = fraction * math.pi * 2;
      paint.color = color;
      canvas.drawArc(arcRect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

/// Full fight-history row.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.byId});

  final _HistoryEntry entry;
  final Map<String, Fighter> byId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final opp = byId[entry.opponentId];
    final resultColor = entry.won ? c.success : c.danger;

    return AppCard(
      onTap: () => context.push(AppRoutes.eventPath(entry.event.id)),
      padding: AppSpacing.allMd,
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.16),
              borderRadius: AppRadius.brSm,
            ),
            child: Center(
              child: Text(
                entry.won ? 'WIN' : 'LOSS',
                style: t.labelSmall?.copyWith(
                  color: resultColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          AppSpacing.hGapMd,
          AppAvatar(
            name: entry.opponentName,
            imageUrl: opp?.imageUrl ?? '',
            size: 40,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${entry.opponentName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  [
                    if (entry.bout.method.isNotEmpty) entry.bout.method,
                    if (entry.bout.finishRound.isNotEmpty)
                      entry.bout.finishRound,
                  ].join(' • '),
                  maxLines: 1,
                  style: t.bodySmall
                      ?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.event.date.shortDate,
                style:
                    t.labelSmall?.copyWith(color: c.textTertiary),
              ),
              AppSpacing.vGapXs,
              Icon(AppIcons.forward, size: 16, color: c.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}

String _lastName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? name : parts.last;
}
