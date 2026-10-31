
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_motion.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../widgets/card_label.dart';
import '../widgets/event_card_skeleton.dart';
import '../widgets/featured_event_card.dart';
import '../widgets/fight_night_card.dart';
import '../widgets/glow_vs.dart';
import '../widgets/ppv_card.dart';
import '../../../../shared/widgets/app_image.dart';

/// Category filters computed from event data.
enum _EventFilter {
  all('All'),
  ppv('PPV'),
  fightNight('Fight Night'),
  womens("Women's"),
  championship('Championship');

  const _EventFilter(this.label);
  final String label;

  bool matches(Event e) => switch (this) {
        all => true,
        ppv => _isPpv(e),
        fightNight => !_isPpv(e),
        womens => [...e.mainCard, ...e.prelims]
            .any((b) => b.weightLabel.toLowerCase().contains('women')),
        championship =>
          [...e.mainCard, ...e.prelims].any((b) => b.isTitleFight),
      };

  /// Numbered cards ("UFC 332") are PPVs; everything else is a Fight Night.
  static bool _isPpv(Event e) =>
      !e.eventType.toLowerCase().contains('fight night');
}

/// Browse upcoming and past events: featured hero with live countdown,
/// PPV rail and Fight Night list, with category filter chips.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  int _index = 0; // 0 = upcoming, 1 = past
  _EventFilter _filter = _EventFilter.all;

  bool get _isUpcoming => _index == 0;

  FutureProvider<List<Event>> get _activeProvider =>
      _isUpcoming ? upcomingEventsProvider : pastEventsProvider;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(_activeProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SegmentedToggle(
              index: _index,
              onChanged: (value) => setState(() => _index = value),
            ),
            _FilterChips(
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppDuration.medium,
                switchInCurve: AppCurves.emphasized,
                child: KeyedSubtree(
                  key: ValueKey('$_index-${_filter.name}'),
                  child: eventsAsync.when(
                    data: _buildBody,
                    loading: () => const _EventsSkeletonList(),
                    error: (_, __) => AppEmptyState.error(
                      message: 'We could not load events. Please try again.',
                      onRetry: () => ref.invalidate(_activeProvider),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(Event event) => context.push(AppRoutes.eventPath(event.id));

  Widget _buildBody(List<Event> events) {
    final filtered = events.where(_filter.matches).toList();
    if (filtered.isEmpty) {
      return AppEmptyState(
        title: 'No events',
        message: _isUpcoming
            ? 'There are no upcoming events for this filter. Check back soon.'
            : 'No past events to show for this filter.',
      );
    }

    // Past tab (and any filtered view) stays a simple list; the curated
    // hero + rails layout is the unfiltered upcoming view.
    if (!_isUpcoming || _filter != _EventFilter.all) {
      return _buildList(filtered);
    }

    final featured = filtered.first;
    final rest = filtered.skip(1).toList();
    final ppvs = rest.where(_EventFilter._isPpv).toList();
    final fightNights =
        rest.where((e) => !_EventFilter._isPpv(e)).toList();
    final past = (ref.watch(pastEventsProvider).valueOrNull ?? const <Event>[])
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final fightersById = {
      for (final f
          in ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[])
        f.id: f,
    };

    return ResponsiveCenter(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          FeaturedEventCard(event: featured, onTap: () => _open(featured)),
          AppSpacing.vGapMd,
          _QuickActions(onOpen: () => _open(featured)),
          if (ppvs.isNotEmpty) ...[
            AppSpacing.vGapXl,
            SectionHeader(
              title: 'Upcoming PPVs',
              actionLabel: 'View all',
              onAction: () =>
                  setState(() => _filter = _EventFilter.ppv),
            ),
            SizedBox(
              height: PpvCard.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: ppvs.length,
                separatorBuilder: (_, __) => AppSpacing.hGapMd,
                itemBuilder: (context, i) => PpvCard(
                  event: ppvs[i],
                  highlight: i == 0,
                  onTap: () => _open(ppvs[i]),
                ),
              ),
            ),
          ],
          if (fightNights.isNotEmpty) ...[
            AppSpacing.vGapXl,
            SectionHeader(
              title: 'Upcoming Fight Nights',
              actionLabel: 'View all',
              onAction: () =>
                  setState(() => _filter = _EventFilter.fightNight),
            ),
            for (var i = 0; i < fightNights.length; i++) ...[
              if (i > 0) AppSpacing.vGapMd,
              FightNightCard(
                event: fightNights[i],
                fightersById: fightersById,
                highlight: i == 0,
                onTap: () => _open(fightNights[i]),
              ),
            ],
          ],
          if (past.isNotEmpty) ...[
            AppSpacing.vGapXl,
            SectionHeader(
              title: 'Past Events',
              actionLabel: 'View all',
              onAction: () => setState(() => _index = 1),
            ),
            SizedBox(
              height: _PastEventCard.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: past.length,
                separatorBuilder: (_, __) => AppSpacing.hGapMd,
                itemBuilder: (context, i) => _PastEventCard(
                  event: past[i],
                  fightersById: fightersById,
                  onTap: () => _open(past[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(List<Event> events) {
    return ResponsiveCenter(
      child: ListView.separated(
        padding: AppSpacing.allLg,
        itemCount: events.length,
        separatorBuilder: (_, __) => AppSpacing.vGapMd,
        itemBuilder: (context, i) {
          final event = events[i];
          return EventCard(event: event, onTap: () => _open(event));
        },
      ),
    );
  }
}

/// iOS-style segmented switch: dark track, the selected segment is a solid
/// white pill with black text.
class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    Widget segment(int i, String label) {
      final selected = index == i;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: AppDuration.fast,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: AppRadius.brPill,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: t.labelLarge?.copyWith(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: AppRadius.brPill,
        ),
        child: Row(
          children: [
            segment(0, 'Upcoming'),
            segment(1, 'Past'),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final _EventFilter selected;
  final ValueChanged<_EventFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _EventFilter.values.length,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (context, i) {
          final f = _EventFilter.values[i];
          return Center(
            child: _FilterPill(
              label: f.label,
              selected: f == selected,
              onTap: () => onChanged(f),
            ),
          );
        },
      ),
    );
  }
}

/// Dark rounded pill; the selected one gets a brand-red outline.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brPill,
          border: Border.all(
            color: selected ? c.brand : c.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Circular shortcuts under the hero, matching the detail screen's quick
/// nav; both lead into the event detail page.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickActionItem(
          icon: Icons.style_rounded,
          label: 'Fight Card',
          onTap: onOpen,
        ),
        _QuickActionItem(
          icon: Icons.format_list_bulleted_rounded,
          label: 'Prelims',
          onTap: onOpen,
        ),
      ],
    );
  }
}

/// 52px icon circle with a label underneath — the unselected style of the
/// detail screen's quick nav (no red ring, since nothing is selected here).
class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.transparent, width: 1.4),
            ),
            child: Icon(icon, size: 22, color: c.textSecondary),
          ),
          AppSpacing.vGapXs,
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Past-event card, UFC.com style: head-to-head portraits on top, then the
/// matchup, date, venue and how the main event ended.
class _PastEventCard extends StatelessWidget {
  const _PastEventCard({
    required this.event,
    required this.fightersById,
    required this.onTap,
  });

  static const double height = 250;
  static const double _width = 230;
  static const double _portraits = 110;

  final Event event;
  final Map<String, Fighter> fightersById;
  final VoidCallback onTap;

  String _last(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final main = event.mainEvent;

    final redName = main == null
        ? ''
        : (fightersById[main.redCornerId]?.name ?? main.redName);
    final blueName = main == null
        ? ''
        : (fightersById[main.blueCornerId]?.name ?? main.blueName);
    final redImg = main == null
        ? ''
        : (fightersById[main.redCornerId]?.imageUrl ?? '');
    final blueImg = main == null
        ? ''
        : (fightersById[main.blueCornerId]?.imageUrl ?? '');

    final method = main?.method ?? '';
    final isDecision = method.toLowerCase().contains('dec');
    final abbr = method.toLowerCase().contains('ko')
        ? 'KO'
        : method.toLowerCase().contains('sub')
            ? 'SUB'
            : isDecision
                ? 'DEC'
                : '';
    final finish = main?.finishRound ?? '';
    final winnerId = main?.winnerId;
    final winner =
        winnerId == null ? null : (fightersById[winnerId]?.name);
    final winnerLast = winner == null
        ? (winnerId == null || main == null
            ? ''
            : _last(winnerId == main.redCornerId
                ? main.redName
                : main.blueName))
        : _last(winner);
    final resultLabel = [
      if (winnerLast.isNotEmpty) winnerLast.toUpperCase(),
      abbr,
      finish,
    ].where((s) => s.isNotEmpty).join(' \u2022 ');
    final badgeColor = isDecision ? c.warning : c.success;

    Widget portrait(String img) => img.isEmpty
        ? ColoredBox(color: c.surfaceElevated)
        : Image(image: appImageProvider(img),
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.9),
            errorBuilder: (_, __, ___) =>
                ColoredBox(color: c.surfaceElevated),
          );

    return SizedBox(
      width: _width,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: AppRadius.brLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: _portraits,
                // House portrait fade: top-aligned art melting into the
                // card surface through a dstIn linear fade.
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, 0.55, 1.0],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Row(
                        children: [
                          Expanded(child: portrait(redImg)),
                          Expanded(child: portrait(blueImg)),
                        ],
                      ),
                      // Seam between the two corners.
                      Center(
                        child: Container(width: 1, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (event.eventType.isEmpty
                                ? event.name
                                : event.eventType)
                            .toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cardLabelStyle(context),
                      ),
                      AppSpacing.vGapXs,
                      if (redName.isNotEmpty && blueName.isNotEmpty)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: _last(redName).toUpperCase()),
                              GlowVs.span(context, size: 11, text: ' VS '),
                              TextSpan(
                                  text: _last(blueName).toUpperCase()),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        )
                      else
                        Text(
                          event.subtitle.isEmpty
                              ? event.name
                              : event.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      AppSpacing.vGapXs,
                      Text(
                        [
                          event.date.mediumDate,
                          if (event.location.isNotEmpty) event.location,
                        ].join(' \u2022 '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall
                            ?.copyWith(color: c.textSecondary),
                      ),
                      const Spacer(),
                      if (resultLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.14),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Text(
                            resultLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                cardLabelStyle(context, color: badgeColor),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsSkeletonList extends StatelessWidget {
  const _EventsSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ResponsiveCenter(
      child: ListView.separated(
        padding: AppSpacing.allLg,
        itemCount: 6,
        separatorBuilder: (_, __) => AppSpacing.vGapMd,
        itemBuilder: (_, __) => const EventCardSkeleton(),
      ),
    );
  }
}
