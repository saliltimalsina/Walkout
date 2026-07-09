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
import 'package:walkout/shared/widgets/widgets.dart';

/// Rankings as a living page: champions rail, division chips, a premium
/// division hero, the top-15 table with form and movement, division movers
/// and the upcoming fights that could shake the list up.
class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  int _selectedIndex = 0;
  bool _fullList = false;

  @override
  Widget build(BuildContext context) {
    final rankingsAsync = ref.watch(rankingsProvider);
    final fightersAsync = ref.watch(fightersProvider);

    return Scaffold(
      body: rankingsAsync.when(
        loading: () => const AppLoading(label: 'Loading rankings…'),
        error: (_, __) => AppEmptyState.error(
          message: 'We couldn\'t load the rankings. Please try again.',
          onRetry: () => ref.invalidate(rankingsProvider),
        ),
        data: (rankings) => fightersAsync.when(
          loading: () => const AppLoading(),
          error: (_, __) => AppEmptyState.error(
            message: 'We couldn\'t load the fighters. Please try again.',
            onRetry: () => ref
              ..invalidate(rankingsProvider)
              ..invalidate(fightersProvider),
          ),
          data: (fighters) => _buildBody(rankings, fighters),
        ),
      ),
    );
  }

  void _selectDivision(int i) => setState(() {
        _selectedIndex = i;
        _fullList = false;
      });

  Widget _buildBody(List<DivisionRanking> rankings, List<Fighter> fighters) {
    if (rankings.isEmpty) {
      return const AppEmptyState(
        title: 'No rankings yet',
        message: 'Divisional rankings will appear here once published.',
      );
    }

    final index = _selectedIndex.clamp(0, rankings.length - 1);
    final division = rankings[index];
    final byId = {for (final f in fighters) f.id: f};

    final moversThisWeek = rankings
        .expand((r) => r.contenders)
        .where((e) => e.change != 0)
        .length;

    // W/L form per fighter, newest first, derived from completed bouts.
    final past =
        ref.watch(pastEventsProvider).valueOrNull ?? const <Event>[];
    final form = <String, List<bool>>{};
    final sortedPast = [...past]..sort((a, b) => b.date.compareTo(a.date));
    for (final e in sortedPast) {
      for (final b in [...e.mainCard, ...e.prelims]) {
        final w = b.winnerId;
        if (w == null) continue;
        for (final id in [b.redCornerId, b.blueCornerId]) {
          if (id.isEmpty) continue;
          (form[id] ??= []).add(id == w);
        }
      }
    }

    final upcoming =
        ref.watch(upcomingEventsProvider).valueOrNull ?? const <Event>[];

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _RankingsHeader(moversThisWeek: moversThisWeek),
          ),
          SliverToBoxAdapter(
            child: _ChampionsRail(
              rankings: rankings,
              byId: byId,
              selectedIndex: index,
              onSelected: _selectDivision,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _DivisionChipsDelegate(
              rankings: rankings,
              selectedIndex: index,
              onSelected: _selectDivision,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: SliverList.list(
              children: [
                _DivisionHero(
                  division: division,
                  champion: byId[division.championId],
                  form: form[division.championId] ?? const [],
                ),
                AppSpacing.vGapLg,
                _RankingTable(
                  division: division,
                  byId: byId,
                  form: form,
                  full: _fullList,
                  onToggleFull: () =>
                      setState(() => _fullList = !_fullList),
                ),
                ..._moversSection(division, byId),
                ..._upcomingSection(division, byId, upcoming),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _moversSection(
      DivisionRanking division, Map<String, Fighter> byId) {
    final movers = division.contenders
        .where((e) => e.change != 0 && byId.containsKey(e.fighterId))
        .toList()
      ..sort((a, b) => b.change.abs().compareTo(a.change.abs()));
    if (movers.isEmpty) return const [];
    return [
      AppSpacing.vGapXl,
      const SectionHeader(title: 'Division Movers'),
      SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: movers.length,
          separatorBuilder: (_, __) => AppSpacing.hGapMd,
          itemBuilder: (context, i) =>
              _MoverCard(entry: movers[i], fighter: byId[movers[i].fighterId]!),
        ),
      ),
    ];
  }

  List<Widget> _upcomingSection(DivisionRanking division,
      Map<String, Fighter> byId, List<Event> upcoming) {
    final rankOf = <String, int>{
      division.championId: 0,
      for (final e in division.contenders) e.fighterId: e.position,
    };

    final fights = <(Event, Bout)>[];
    for (final e in upcoming) {
      for (final b in [...e.mainCard, ...e.prelims]) {
        if (rankOf.containsKey(b.redCornerId) ||
            rankOf.containsKey(b.blueCornerId)) {
          fights.add((e, b));
        }
      }
    }
    if (fights.isEmpty) return const [];
    fights.sort((a, b) => a.$1.date.compareTo(b.$1.date));

    return [
      AppSpacing.vGapXl,
      const SectionHeader(title: 'Upcoming Ranked Fights'),
      SizedBox(
        height: 148,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: fights.length,
          separatorBuilder: (_, __) => AppSpacing.hGapMd,
          itemBuilder: (context, i) => _RankedFightCard(
            event: fights[i].$1,
            bout: fights[i].$2,
            rankOf: rankOf,
            byId: byId,
          ),
        ),
      ),
    ];
  }
}

/// "RANKINGS" headline with the week's movement pulse.
class _RankingsHeader extends StatelessWidget {
  const _RankingsHeader({required this.moversThisWeek});

  final int moversThisWeek;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RANKINGS',
            style: t.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          if (moversThisWeek > 0) ...[
            AppSpacing.vGapXs,
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 16, color: c.success),
                AppSpacing.hGapXs,
                Text(
                  '$moversThisWeek fighters moved this week',
                  style: t.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Horizontal rail of champion portraits — tap to jump to a division.
class _ChampionsRail extends StatelessWidget {
  const _ChampionsRail({
    required this.rankings,
    required this.byId,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DivisionRanking> rankings;
  final Map<String, Fighter> byId;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: rankings.length,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (context, i) {
          final champ = byId[rankings[i].championId];
          if (champ == null) return const SizedBox.shrink();
          final selected = i == selectedIndex;
          return Pressable(
            onTap: () => onSelected(i),
            semanticLabel: champ.name,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 104,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF17171A),
                borderRadius: AppRadius.brLg,
                border: Border.all(
                  color: selected ? c.brand : const Color(0xFF262628),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    rankings[i].weightClass.abbr,
                    style: t.labelSmall?.copyWith(
                      color: selected ? c.brand : c.textSecondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      height: 2.2,
                    ),
                  ),
                  Expanded(
                    child: champ.imageUrl.isEmpty
                        ? const SizedBox.shrink()
                        : ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white,
                                Colors.white,
                                Colors.transparent
                              ],
                              stops: [0.0, 0.7, 1.0],
                            ).createShader(rect),
                            blendMode: BlendMode.dstIn,
                            child: Image.asset(
                              champ.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              alignment: const Alignment(0, -0.9),
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _lastName(champ.name).toUpperCase(),
                        maxLines: 1,
                        style: t.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pinned horizontal division chips.
class _DivisionChipsDelegate extends SliverPersistentHeaderDelegate {
  _DivisionChipsDelegate({
    required this.rankings,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DivisionRanking> rankings;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _height = 54;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = context.colors;
    final t = context.text;
    return ColoredBox(
      color: c.background,
      child: Center(
        child: SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: rankings.length,
            separatorBuilder: (_, __) => AppSpacing.hGapSm,
            itemBuilder: (context, i) {
              final selected = i == selectedIndex;
              return Center(
                child: Pressable(
                  onTap: () => onSelected(i),
                  semanticLabel: rankings[i].weightClass.label,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? c.brand : const Color(0xFF141414),
                      borderRadius: AppRadius.brPill,
                      border: Border.all(
                        color:
                            selected ? c.brand : const Color(0xFF3A3A3C),
                      ),
                    ),
                    child: Text(
                      rankings[i].weightClass.label.toUpperCase(),
                      style: t.labelMedium?.copyWith(
                        color: selected ? c.onBrand : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DivisionChipsDelegate oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.rankings != rankings;
}

/// Premium division hero: crown, division, big champion name, record and
/// streak, portrait rising out of a red glow.
class _DivisionHero extends StatelessWidget {
  const _DivisionHero({
    required this.division,
    required this.champion,
    required this.form,
  });

  final DivisionRanking division;
  final Fighter? champion;
  final List<bool> form;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final champ = champion;
    if (champ == null) return const SizedBox.shrink();

    var streak = 0;
    for (final won in form) {
      if (!won) break;
      streak++;
    }

    return Pressable(
      onTap: () => context.push(AppRoutes.fighterPath(champ.id)),
      semanticLabel: champ.name,
      child: Container(
        height: 200,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          border: Border.all(color: const Color(0xFF262628)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1C), Color(0xFF0F0F11)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.7, 0.4),
                    radius: 1.0,
                    colors: [
                      c.brand.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (champ.imageUrl.isNotEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: FractionallySizedBox(
                  widthFactor: 0.48,
                  heightFactor: 1,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [Colors.white, Colors.transparent],
                      stops: [0.55, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      champ.imageUrl,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.7),
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: AppSpacing.allLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        division.weightClass.label.toUpperCase(),
                        style: t.labelMedium?.copyWith(
                          color: c.brand,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Icon(Icons.workspace_premium_rounded,
                          size: 16, color: c.accent),
                      AppSpacing.hGapXs,
                      Text(
                        'CHAMPION',
                        style: t.labelSmall?.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapSm,
                  for (final part in champ.name.split(' '))
                    Text(
                      part.toUpperCase(),
                      style: t.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: 0.5,
                      ),
                    ),
                  AppSpacing.vGapSm,
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: champ.record.display),
                        if (streak >= 2) ...[
                          TextSpan(
                            text: ' • ',
                            style: TextStyle(color: c.brand),
                          ),
                          TextSpan(text: '$streak fight win streak'),
                        ] else ...[
                          TextSpan(
                            text: ' • ',
                            style: TextStyle(color: c.brand),
                          ),
                          TextSpan(
                            text:
                                '${division.contenders.length} ranked fighters',
                          ),
                        ],
                      ],
                    ),
                    style:
                        t.bodySmall?.copyWith(color: c.textSecondary),
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

/// Champion + top contenders table with form dots and movement.
class _RankingTable extends StatelessWidget {
  const _RankingTable({
    required this.division,
    required this.byId,
    required this.form,
    required this.full,
    required this.onToggleFull,
  });

  final DivisionRanking division;
  final Map<String, Fighter> byId;
  final Map<String, List<bool>> form;
  final bool full;
  final VoidCallback onToggleFull;

  static const int _collapsedCount = 5;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    final contenders = [...division.contenders]
      ..sort((a, b) => a.position.compareTo(b.position));
    final visible = contenders
        .where((e) => byId.containsKey(e.fighterId))
        .toList();
    final shown = full ? visible : visible.take(_collapsedCount).toList();
    final champ = byId[division.championId];

    Widget legendDot(Color color, IconData icon, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            AppSpacing.hGapXs,
            Text(
              label,
              style: t.labelSmall?.copyWith(color: c.textSecondary),
            ),
          ],
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        border: Border.all(color: const Color(0xFF262628)),
        color: const Color(0xFF121214),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TOP ${visible.length} RANKINGS',
                    style: t.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                legendDot(
                    c.success, Icons.arrow_drop_up_rounded, 'Up'),
                AppSpacing.hGapSm,
                legendDot(
                    c.danger, Icons.arrow_drop_down_rounded, 'Down'),
              ],
            ),
          ),
          if (champ != null)
            _RankRow(
              fighter: champ,
              positionLabel: 'C',
              champion: true,
              change: 0,
              form: form[champ.id] ?? const [],
            ),
          for (final e in shown)
            _RankRow(
              fighter: byId[e.fighterId]!,
              positionLabel: '${e.position}',
              champion: false,
              change: e.change,
              form: form[e.fighterId] ?? const [],
            ),
          if (visible.length > _collapsedCount)
            Pressable(
              onTap: onToggleFull,
              semanticLabel: 'Toggle full rankings',
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF232325)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      full ? 'SHOW TOP 5' : 'VIEW FULL RANKINGS',
                      style: t.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Icon(
                      full
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                      color: c.textSecondary,
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

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.fighter,
    required this.positionLabel,
    required this.champion,
    required this.change,
    required this.form,
  });

  final Fighter fighter;
  final String positionLabel;
  final bool champion;
  final int change;
  final List<bool> form;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    return Pressable(
      onTap: () => context.push(AppRoutes.fighterPath(fighter.id)),
      semanticLabel: fighter.name,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1D1D1F))),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: champion
                  ? BoxDecoration(
                      color: c.accent.withValues(alpha: 0.18),
                      borderRadius: AppRadius.brSm,
                    )
                  : null,
              child: Text(
                positionLabel,
                style: t.titleLarge?.copyWith(
                  fontSize: champion ? 14 : 16,
                  color: champion ? c.accent : c.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AppSpacing.hGapSm,
            AppAvatar(
              name: fighter.name,
              imageUrl: fighter.imageUrl,
              size: 36,
              borderColor: champion ? c.accent : null,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fighter.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    [
                      if (fighter.flag.isNotEmpty) fighter.flag,
                      fighter.record.display,
                    ].join('  '),
                    maxLines: 1,
                    style: t.bodySmall
                        ?.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            _FormDots(form: form),
            AppSpacing.hGapMd,
            SizedBox(width: 34, child: _MoveLabel(change: change)),
          ],
        ),
      ),
    );
  }
}

/// Last-five form as W/L dots, most recent first. Hidden when no history.
class _FormDots extends StatelessWidget {
  const _FormDots({required this.form});

  final List<bool> form;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (form.isEmpty) return const SizedBox(width: 0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final won in form.take(5))
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (won ? c.success : c.danger).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Text(
                won ? 'W' : 'L',
                style: context.text.labelSmall?.copyWith(
                  fontSize: 8,
                  color: won ? c.success : c.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MoveLabel extends StatelessWidget {
  const _MoveLabel({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    if (change == 0) {
      return Text(
        '—',
        textAlign: TextAlign.center,
        style: t.labelMedium?.copyWith(color: c.textTertiary),
      );
    }
    final up = change > 0;
    final color = up ? c.success : c.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
          size: 20,
          color: color,
        ),
        Text(
          '${change.abs()}',
          style: t.labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

/// Stock-ticker style mover card: delta, name, "#10 to #7".
class _MoverCard extends StatelessWidget {
  const _MoverCard({required this.entry, required this.fighter});

  final RankingEntry entry;
  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final up = entry.change > 0;
    final color = up ? c.success : c.danger;
    final prev = entry.position + entry.change;

    return Pressable(
      onTap: () => context.push(AppRoutes.fighterPath(fighter.id)),
      semanticLabel: fighter.name,
      child: Container(
        width: 210,
        padding: AppSpacing.allMd,
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          border: Border.all(color: const Color(0xFF262628)),
          color: const Color(0xFF141416),
        ),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  up
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  size: 26,
                  color: color,
                ),
                Text(
                  '${entry.change.abs()}',
                  style: t.titleLarge?.copyWith(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fighter.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    '#$prev to #${entry.position}',
                    style: t.bodySmall
                        ?.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            AppAvatar(
                name: fighter.name, imageUrl: fighter.imageUrl, size: 40),
          ],
        ),
      ),
    );
  }
}

/// Upcoming fight between ranked fighters in this division.
class _RankedFightCard extends StatelessWidget {
  const _RankedFightCard({
    required this.event,
    required this.bout,
    required this.rankOf,
    required this.byId,
  });

  final Event event;
  final Bout bout;
  final Map<String, int> rankOf;
  final Map<String, Fighter> byId;

  String _rankLabel(String id) {
    final r = rankOf[id];
    if (r == null) return '';
    return r == 0 ? 'C' : '#$r';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final red = byId[bout.redCornerId];
    final blue = byId[bout.blueCornerId];

    Widget corner(Fighter? f, String fallback, String rank) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAvatar(
                name: f?.name ?? fallback,
                imageUrl: f?.imageUrl ?? '',
                size: 44,
              ),
              AppSpacing.vGapXs,
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  [
                    if (rank.isNotEmpty) rank,
                    _lastName(f?.name ?? fallback).toUpperCase(),
                  ].join(' '),
                  maxLines: 1,
                  style: t.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );

    return Pressable(
      onTap: () => context.push(AppRoutes.eventPath(event.id)),
      semanticLabel: event.name,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          border: Border.all(color: const Color(0xFF262628)),
          color: const Color(0xFF141416),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (event.eventType.isEmpty ? event.name : event.eventType)
                  .toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelSmall?.copyWith(
                color: c.brand,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              event.date.mediumDate,
              style: t.labelSmall?.copyWith(color: c.textSecondary),
            ),
            AppSpacing.vGapSm,
            Row(
              children: [
                corner(red, bout.redName, _rankLabel(bout.redCornerId)),
                Padding(
                  padding: AppSpacing.hSm,
                  child: Text(
                    'VS',
                    style: t.labelMedium?.copyWith(
                      color: c.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                corner(blue, bout.blueName, _rankLabel(bout.blueCornerId)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _lastName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? name : parts.last;
}
