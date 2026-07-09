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
import 'package:walkout/shared/widgets/widgets.dart';

import '../widgets/event_countdown.dart';

/// Full card for a single event: hero, quick nav, countdown, main card and
/// a collapsible preliminary card.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final fightersAsync = ref.watch(fightersProvider);

    return Scaffold(
      body: eventAsync.when(
        loading: () => const AppLoading(label: 'Loading event…'),
        error: (_, __) => AppEmptyState.error(
          message: 'We could not load this event.',
          onRetry: () => ref.invalidate(eventProvider(eventId)),
        ),
        data: (event) => fightersAsync.when(
          loading: () => const AppLoading(),
          error: (_, __) => AppEmptyState.error(
            message: 'We could not load the fighters for this card.',
            onRetry: () => ref.invalidate(fightersProvider),
          ),
          data: (fighters) {
            final byId = {for (final f in fighters) f.id: f};
            return _EventDetailBody(event: event, fightersById: byId);
          },
        ),
      ),
    );
  }
}

class _EventDetailBody extends StatefulWidget {
  const _EventDetailBody({required this.event, required this.fightersById});

  final Event event;
  final Map<String, Fighter> fightersById;

  @override
  State<_EventDetailBody> createState() => _EventDetailBodyState();
}

class _EventDetailBodyState extends State<_EventDetailBody> {
  final GlobalKey _fightCardKey = GlobalKey();
  final GlobalKey _prelimsKey = GlobalKey();
  bool _prelimsOpen = false;

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _openPrelims() {
    setState(() => _prelimsOpen = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollTo(_prelimsKey));
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final mainCard = event.mainCard;
    final prelims = event.prelims;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          centerTitle: true,
          title: Text(
            (event.eventType.isEmpty ? event.name : event.eventType)
                .toUpperCase(),
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailHero(event: event),
                _QuickNav(
                  onFightCard: () => _scrollTo(_fightCardKey),
                  onPrelims: prelims.isEmpty ? null : _openPrelims,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.status != EventStatus.past) ...[
                        EventCountdown(event: event),
                        AppSpacing.vGapXl,
                      ],
                      if (mainCard.isNotEmpty) ...[
                        KeyedSubtree(
                          key: _fightCardKey,
                          child: SectionHeader(
                            title: 'Main Card',
                            actionLabel:
                                prelims.isNotEmpty ? 'View full card' : null,
                            onAction:
                                prelims.isNotEmpty ? _openPrelims : null,
                          ),
                        ),
                        _MainEventCard(
                          bout: mainCard.first,
                          fightersById: widget.fightersById,
                        ),
                        for (var i = 1; i < mainCard.length; i++) ...[
                          AppSpacing.vGapMd,
                          _CompactBoutCard(
                            bout: mainCard[i],
                            fightersById: widget.fightersById,
                            label: i == 1 ? 'CO-MAIN EVENT' : null,
                          ),
                        ],
                      ],
                      if (prelims.isNotEmpty) ...[
                        AppSpacing.vGapXl,
                        KeyedSubtree(
                          key: _prelimsKey,
                          child: _PrelimsHeader(
                            count: prelims.length,
                            open: _prelimsOpen,
                            onToggle: () => setState(
                                () => _prelimsOpen = !_prelimsOpen),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _prelimsOpen
                              ? Column(
                                  children: [
                                    for (var i = 0;
                                        i < prelims.length;
                                        i++) ...[
                                      if (i > 0) AppSpacing.vGapMd,
                                      _CompactBoutCard(
                                        bout: prelims[i],
                                        fightersById: widget.fightersById,
                                      ),
                                    ],
                                  ],
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "PRELIMINARY CARD · 6 BOUTS" header with an expand/collapse chevron.
class _PrelimsHeader extends StatelessWidget {
  const _PrelimsHeader({
    required this.count,
    required this.open,
    required this.onToggle,
  });

  final int count;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onTap: onToggle,
      semanticLabel: 'Preliminary card',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'PRELIMINARY CARD'),
                    TextSpan(
                      text: '  $count BOUTS',
                      style: t.labelMedium?.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.titleLarge?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: open ? c.brand : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero: red event type, stacked last names with a red VS, venue line; the
/// event art bleeds in from the right under a red-tinted scrim.
class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final parts =
        event.subtitle.split(RegExp(r'\s+vs\.?\s+', caseSensitive: false));

    // Venue + date so past-event pages (no countdown card) stay dated.
    final venue = [
      [
        if (event.venue.isNotEmpty) event.venue,
        if (event.location.isNotEmpty) event.location,
      ].join(', '),
      event.date.mediumDate,
    ].where((s) => s.isNotEmpty).join(' • ');

    final nameStyle = t.displaySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      height: 1.02,
      letterSpacing: 0.5,
    );

    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (event.heroImage.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.7,
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.white],
                    stops: [0.0, 0.5],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    event.heroImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            // Red arena glow over the art.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.5),
                    radius: 1.1,
                    colors: [
                      c.brand.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom vignette keeps the venue line readable.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.55, 1.0],
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (event.eventType.isEmpty ? event.name : event.eventType)
                      .toUpperCase(),
                  style: t.labelLarge?.copyWith(
                    color: c.brand,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                AppSpacing.vGapXs,
                if (parts.length == 2) ...[
                  // Subtitle parts are already surnames ("Holloway 2"),
                  // so render them whole — don't re-strip to last token.
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: parts[0].trim().toUpperCase()),
                        TextSpan(
                          text: ' VS',
                          style: TextStyle(
                            color: c.brand,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    style: nameStyle,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(parts[1].trim().toUpperCase(),
                        maxLines: 1, style: nameStyle),
                  ),
                ] else
                  Text(
                    (event.subtitle.isEmpty ? event.name : event.subtitle)
                        .toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: nameStyle?.copyWith(fontSize: 28),
                  ),
                if (venue.isNotEmpty) ...[
                  AppSpacing.vGapSm,
                  Text(
                    venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round icon shortcuts under the hero, reference-style. Overview is the
/// active screen; the rest jump to their section.
class _QuickNav extends StatelessWidget {
  const _QuickNav({required this.onFightCard, required this.onPrelims});

  final VoidCallback onFightCard;
  final VoidCallback? onPrelims;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppIcons.events, 'Overview', true, null),
      (Icons.style_rounded, 'Fight Card', false, onFightCard),
      if (onPrelims != null)
        (Icons.format_list_bulleted_rounded, 'Prelims', false, onPrelims),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final (icon, label, selected, onTap) in items)
            _QuickNavItem(
              icon: icon,
              label: label,
              selected: selected,
              onTap: onTap,
            ),
        ],
      ),
    );
  }
}

class _QuickNavItem extends StatelessWidget {
  const _QuickNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.brand : c.textSecondary;

    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: c.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? c.brand : Colors.transparent,
              width: 1.4,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: c.brand.withValues(alpha: 0.35),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 22, color: fg),
        ),
        AppSpacing.vGapXs,
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: fg,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap == null) return child;
    return Pressable(onTap: onTap, semanticLabel: label, child: child);
  }
}

/// Shared aura shell for bout cards: dark gradient surface, faint border and
/// a red radial glow rising from the center.
class _AuraCard extends StatelessWidget {
  const _AuraCard({
    required this.child,
    this.glowAlpha = 0.22,
    this.height,
  });

  final Widget child;
  final double glowAlpha;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        border: Border.all(color: c.border),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.surfaceElevated, c.surface],
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 1.0,
                  colors: [
                    c.brand.withValues(alpha: glowAlpha),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.75],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Red VS with a soft glow — the centerpiece of every matchup.
class _GlowVs extends StatelessWidget {
  const _GlowVs({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      'VS',
      style: context.text.titleLarge?.copyWith(
        color: c.brand,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        shadows: [
          Shadow(color: c.brand.withValues(alpha: 0.9), blurRadius: 16),
          Shadow(color: c.brand.withValues(alpha: 0.5), blurRadius: 32),
        ],
      ),
    );
  }
}

/// Big marquee card for the main event: tall portraits bleeding off the card
/// edges, glowing red VS, names and records, bout line at the bottom.
class _MainEventCard extends StatelessWidget {
  const _MainEventCard({required this.bout, required this.fightersById});

  final Bout bout;
  final Map<String, Fighter> fightersById;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final red = fightersById[bout.redCornerId];
    final blue = fightersById[bout.blueCornerId];
    final wl = bout.weightLabel.isNotEmpty
        ? bout.weightLabel
        : bout.weightClass.label;
    final sub = bout.isTitleFight ? '$wl Title Bout' : '$wl Bout';
    final complete = bout.winnerId != null;

    return _AuraCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Text(
              'MAIN EVENT',
              style: t.labelSmall?.copyWith(
                color: c.brand,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            AppSpacing.vGapSm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _MainEventCorner(
                    fighter: red,
                    fallbackName: bout.redName,
                    cornerId: bout.redCornerId,
                    dim: complete && bout.winnerId != bout.redCornerId,
                    alignLeft: true,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 52),
                  child: _GlowVs(size: 24),
                ),
                Expanded(
                  child: _MainEventCorner(
                    fighter: blue,
                    fallbackName: bout.blueName,
                    cornerId: bout.blueCornerId,
                    dim: complete && bout.winnerId != bout.blueCornerId,
                    alignLeft: false,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              sub,
              style: t.bodySmall?.copyWith(color: c.textSecondary),
            ),
            if (complete && bout.method.isNotEmpty) ...[
              AppSpacing.vGapXs,
              Text(
                _resultLine(bout, fightersById),
                style: t.labelSmall?.copyWith(
                  color: c.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "ASPINALL wins by KO • R2" — who won, not just how it ended.
String _resultLine(Bout bout, Map<String, Fighter> byId) {
  final winnerName = byId[bout.winnerId]?.name ??
      (bout.winnerId == bout.redCornerId ? bout.redName : bout.blueName);
  final last = winnerName.trim().split(RegExp(r'\s+')).last.toUpperCase();
  final round = bout.finishRound.isEmpty ? '' : ' • ${bout.finishRound}';
  return '$last wins by ${bout.method}$round';
}

class _MainEventCorner extends StatelessWidget {
  const _MainEventCorner({
    required this.fighter,
    required this.fallbackName,
    required this.cornerId,
    required this.dim,
    required this.alignLeft,
  });

  final Fighter? fighter;
  final String fallbackName;
  final String cornerId;
  final bool dim;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final name =
        fighter?.name ?? (fallbackName.isEmpty ? 'TBD' : fallbackName);
    final record = fighter?.record.display ?? '';
    final img = fighter?.imageUrl ?? '';

    final content = Opacity(
      opacity: dim ? 0.55 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 140,
            child: img.isEmpty
                ? const SizedBox.shrink()
                : ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: alignLeft
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      end: alignLeft
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      colors: const [
                        Colors.white,
                        Colors.white,
                        Colors.transparent
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent
                        ],
                        stops: [0.0, 0.78, 1.0],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        img,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        alignment: const Alignment(0, -0.9),
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
          ),
          AppSpacing.vGapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name.toUpperCase(),
              maxLines: 1,
              style: t.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          if (record.isNotEmpty) ...[
            AppSpacing.vGapXs,
            Text(
              record,
              style: t.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );

    if (fighter == null) return content;
    return Pressable(
      onTap: () => context.push(AppRoutes.fighterPath(cornerId)),
      semanticLabel: name,
      child: content,
    );
  }
}

/// Compact bout row: portraits bleeding in from the card edges, red label,
/// inline "NAME VS NAME" with a glowing VS, bout line underneath.
class _CompactBoutCard extends StatelessWidget {
  const _CompactBoutCard({
    required this.bout,
    required this.fightersById,
    this.label,
  });

  final Bout bout;
  final Map<String, Fighter> fightersById;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final red = fightersById[bout.redCornerId];
    final blue = fightersById[bout.blueCornerId];
    final redName = red?.name ?? bout.redName;
    final blueName = blue?.name ?? bout.blueName;
    final wl = bout.weightLabel.isNotEmpty
        ? bout.weightLabel
        : bout.weightClass.label;
    final tag = label ?? '${wl.toUpperCase()} BOUT';
    final sub = bout.isTitleFight ? '$wl Title Bout' : '$wl Bout';
    final complete = bout.winnerId != null;

    // Half-card tap zone opening the corner's fighter profile; only wired
    // when that fighter exists in the roster.
    Widget tapZone(Fighter? fighter, String name, String cornerId) =>
        Expanded(
          child: fighter == null
              ? const SizedBox.shrink()
              : Semantics(
                  button: true,
                  label: 'View $name profile',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        context.push(AppRoutes.fighterPath(cornerId)),
                    child: const SizedBox.expand(),
                  ),
                ),
        );

    Widget edgePortrait(String img, bool left, bool dim) => img.isEmpty
        ? const SizedBox.shrink()
        : Positioned(
            top: 0,
            bottom: 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            width: 92,
            child: Opacity(
              opacity: dim ? 0.45 : 0.9,
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin:
                      left ? Alignment.centerLeft : Alignment.centerRight,
                  end: left ? Alignment.centerRight : Alignment.centerLeft,
                  colors: const [Colors.white, Colors.transparent],
                  stops: const [0.25, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  img,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.9),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          );

    return _AuraCard(
      glowAlpha: 0.12,
      height: 104,
      child: Stack(
        fit: StackFit.expand,
        children: [
          edgePortrait(red?.imageUrl ?? '', true,
              complete && bout.winnerId != bout.redCornerId),
          edgePortrait(blue?.imageUrl ?? '', false,
              complete && bout.winnerId != bout.blueCornerId),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 84),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(
                          color: c.brand,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    if (bout.isTitleFight) ...[
                      AppSpacing.hGapXs,
                      const _TitleTag(),
                    ],
                  ],
                ),
                AppSpacing.vGapSm,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: redName.toUpperCase()),
                        TextSpan(
                          text: '   VS   ',
                          style: TextStyle(
                            color: c.brand,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: c.brand.withValues(alpha: 0.8),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                        TextSpan(text: blueName.toUpperCase()),
                      ],
                    ),
                    maxLines: 1,
                    style: t.titleLarge?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                AppSpacing.vGapSm,
                Text(
                  complete && bout.method.isNotEmpty
                      ? _resultLine(bout, fightersById)
                      : sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: complete && bout.method.isNotEmpty
                        ? c.success
                        : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                tapZone(red, redName, bout.redCornerId),
                tapZone(blue, blueName, bout.blueCornerId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold "TITLE" mini-tag shown next to the bout label on championship bouts.
class _TitleTag extends StatelessWidget {
  const _TitleTag();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.12),
        borderRadius: AppRadius.brSm,
        border: Border.all(
          color: c.accent.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 10, color: c.accent),
          const SizedBox(width: 3),
          Text(
            'TITLE',
            style: context.text.labelSmall?.copyWith(
              color: c.accent,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
