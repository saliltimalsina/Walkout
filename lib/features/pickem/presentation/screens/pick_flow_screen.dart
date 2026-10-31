import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/pickem_controller.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../widgets/octagon_card.dart';
import '../../../../shared/widgets/app_image.dart';

/// Build-your-card flow: draft intro, one cinematic fight poster per page —
/// tap a corner, drag the confidence slider — then the prelims gate and a
/// visual card summary.
class PickFlowScreen extends ConsumerStatefulWidget {
  const PickFlowScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<PickFlowScreen> createState() => _PickFlowScreenState();
}

class _PickFlowScreenState extends ConsumerState<PickFlowScreen> {
  final _controller = PageController();
  bool _includePrelims = false;
  bool _started = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );

  void _guessPrelims() {
    setState(() => _includePrelims = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _next());
  }

  void _skipToSummary(int lastIndex) => _controller.animateToPage(
        lastIndex,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final fightersAsync = ref.watch(fightersProvider);

    return Scaffold(
      body: eventAsync.when(
        loading: () => const AppLoading(),
        error: (_, __) => AppEmptyState.error(
          message: 'We could not load this card.',
          onRetry: () => ref.invalidate(eventProvider(widget.eventId)),
        ),
        data: (event) {
          final byId = {
            for (final f in fightersAsync.valueOrNull ?? const <Fighter>[])
              f.id: f,
          };
          final bouts = pickableBouts(event);
          final mainCount = event.mainCard.length;
          final card = ref.watch(pickemProvider)[event.id] ??
              PickCard(eventId: event.id);

          final madeMain =
              card.picks.keys.where((i) => i < mainCount).length;
          final prelimPicks =
              card.picks.keys.where((i) => i >= mainCount).length;
          if (prelimPicks > 0 && !_includePrelims) _includePrelims = true;
          if (card.picks.isNotEmpty && !_started) _started = true;

          if (!_started) {
            return SafeArea(
              child: _DraftIntro(
                event: event,
                fights: mainCount,
                byId: byId,
                onStart: () => setState(() => _started = true),
                onClose: () => context.pop(),
              ),
            );
          }

          final hasPrelims = event.prelims.isNotEmpty;
          final pages = <Widget>[
            for (var i = 0; i < mainCount; i++)
              _FightPosterPage(
                event: event,
                bout: bouts[i],
                boutIndex: i,
                label: i == 0
                    ? 'MAIN EVENT'
                    : i == 1
                        ? 'CO-MAIN EVENT'
                        : null,
                byId: byId,
                pick: card.picks[i],
                onPicked: _next,
              ),
            if (hasPrelims)
              _PrelimsGatePage(
                count: event.prelims.length,
                onGuess: _guessPrelims,
                onSkip: () => _skipToSummary(
                  mainCount +
                      1 +
                      (_includePrelims ? bouts.length - mainCount : 0),
                ),
              ),
            if (hasPrelims && _includePrelims)
              for (var i = mainCount; i < bouts.length; i++)
                _FightPosterPage(
                  event: event,
                  bout: bouts[i],
                  boutIndex: i,
                  label: 'PRELIM',
                  byId: byId,
                  pick: card.picks[i],
                  onPicked: _next,
                ),
            _SummaryPage(
              event: event,
              bouts: bouts,
              byId: byId,
              card: card,
            ),
          ];

          return SafeArea(
            child: Column(
              children: [
                _FlowHeader(
                  event: event,
                  made: madeMain,
                  total: mainCount,
                  prelimPicks: prelimPicks,
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    children: pages,
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

/// "Build your card — 11 fights — ~45 seconds — START."
/// Aura-treated: red radial glow, the main-event corners bleeding in from
/// the edges, and an octagon-framed stat strip.
class _DraftIntro extends StatelessWidget {
  const _DraftIntro({
    required this.event,
    required this.fights,
    required this.byId,
    required this.onStart,
    required this.onClose,
  });

  final Event event;
  final int fights;
  final Map<String, Fighter> byId;
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final main = event.mainEvent;
    final redImg =
        main == null ? '' : (byId[main.redCornerId]?.imageUrl ?? '');
    final blueImg =
        main == null ? '' : (byId[main.blueCornerId]?.imageUrl ?? '');

    // Ghosted main-event corner bleeding in from a screen edge.
    Widget edgePortrait(String img, bool left) => img.isEmpty
        ? const SizedBox.shrink()
        : Positioned(
            top: 40,
            bottom: 120,
            left: left ? -36 : null,
            right: left ? null : -36,
            width: 150,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.32,
                child: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    begin:
                        left ? Alignment.centerLeft : Alignment.centerRight,
                    end: left ? Alignment.centerRight : Alignment.centerLeft,
                    colors: const [Colors.white, Colors.transparent],
                    stops: const [0.25, 1.0],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.65, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image(image: appImageProvider(img),
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.8),
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          );

    return Stack(
      children: [
        // Aura: red radial glow behind the headline.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 0.95,
                  colors: [
                    c.brand.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        edgePortrait(redImg, true),
        edgePortrait(blueImg, false),
        Padding(
          padding: AppSpacing.allLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Spacer(),
              // Octagon-framed emblem.
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: c.brand.withValues(alpha: 0.14),
                    shape: OctagonBorderShape(
                      cut: 12,
                      side: BorderSide(
                        color: c.brand.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  child: Icon(Icons.style_rounded, size: 30, color: c.brand),
                ),
              ),
              AppSpacing.vGapLg,
              Text(
                'BUILD YOUR CARD',
                textAlign: TextAlign.center,
                style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              AppSpacing.vGapSm,
              Text(
                (event.eventType.isEmpty ? event.name : event.eventType)
                    .toUpperCase(),
                textAlign: TextAlign.center,
                style: t.labelLarge?.copyWith(
                  color: c.brand,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              AppSpacing.vGapXl,
              // Octagon-framed stat divider.
              Center(
                child: OctagonCard(
                  cut: 12,
                  color: const Color(0x66121214),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IntroStat(value: '$fights', label: 'FIGHTS'),
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        color: const Color(0xFF2A2A2C),
                      ),
                      _IntroStat(
                          value: '~${(fights * 6)}s', label: 'TO COMPLETE'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // START carries the brand glow — the one action on screen.
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.brMd,
                  boxShadow: [
                    BoxShadow(
                      color: c.brand.withValues(alpha: 0.38),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: AppButton(
                  label: 'START',
                  isFullWidth: true,
                  onPressed: onStart,
                ),
              ),
              AppSpacing.vGapMd,
            ],
          ),
        ),
      ],
    );
  }
}

class _IntroStat extends StatelessWidget {
  const _IntroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      children: [
        Text(value,
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
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

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.event,
    required this.made,
    required this.total,
    this.prelimPicks = 0,
  });

  final Event event;
  final int made;
  final int total;
  final int prelimPicks;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (event.eventType.isEmpty ? event.name : event.eventType)
                      .toUpperCase(),
                  style: t.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                AppSpacing.vGapXs,
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : made / total,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF2A2A2C),
                    valueColor: AlwaysStoppedAnimation(c.brand),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapMd,
          Text(
            prelimPicks > 0 ? '$made/$total +$prelimPicks' : '$made/$total',
            style: t.labelLarge?.copyWith(
              color: c.brand,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cinematic fight poster: two towering corners, glowing VS, bout meta and
/// the confidence slider once a corner is picked.
class _FightPosterPage extends ConsumerWidget {
  const _FightPosterPage({
    required this.event,
    required this.bout,
    required this.boutIndex,
    required this.byId,
    required this.pick,
    required this.onPicked,
    this.label,
  });

  final Event event;
  final Bout bout;
  final int boutIndex;
  final String? label;
  final Map<String, Fighter> byId;
  final FightPick? pick;
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final wl = bout.division;
    final hot = label == 'MAIN EVENT' || label == 'CO-MAIN EVENT';
    final hype = 82 + Object.hash(event.id, boutIndex).abs() % 16;

    void select(String fighterId) {
      HapticFeedback.mediumImpact();
      final already = pick?.fighterId == fighterId;
      ref.read(pickemProvider.notifier).setPick(
            event.id,
            boutIndex,
            FightPick(fighterId: fighterId, percent: pick?.percent ?? 50),
          );
      if (!already && pick == null) {
        // First pick on this fight: pause so the slider is discoverable.
        return;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label ?? '${wl.toUpperCase()} BOUT',
                style: t.labelSmall?.copyWith(
                  color: c.brand,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              if (hot) ...[
                AppSpacing.hGapSm,
                Text(
                  '🔥 $hype',
                  style: t.labelSmall?.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          AppSpacing.vGapXs,
          Text(
            '$wl • ${bout.rounds} rounds',
            style: t.bodySmall?.copyWith(color: c.textSecondary),
          ),
          AppSpacing.vGapMd,
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PosterCorner(
                        fighter: byId[bout.redCornerId],
                        fallbackName: bout.redName,
                        selected: pick?.fighterId == bout.redCornerId,
                        dimmed: pick != null &&
                            pick!.fighterId != bout.redCornerId,
                        onTap: () => select(bout.redCornerId),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: _PosterCorner(
                        fighter: byId[bout.blueCornerId],
                        fallbackName: bout.blueName,
                        selected: pick?.fighterId == bout.blueCornerId,
                        dimmed: pick != null &&
                            pick!.fighterId != bout.blueCornerId,
                        onTap: () => select(bout.blueCornerId),
                      ),
                    ),
                  ],
                ),
                // Glowing VS floating over the seam.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        'VS',
                        style: t.headlineSmall?.copyWith(
                          color: c.brand,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: c.brand.withValues(alpha: 0.95),
                              blurRadius: 18,
                            ),
                            Shadow(
                              color: c.brand.withValues(alpha: 0.5),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapMd,
          SizedBox(
            height: 118,
            child: pick == null
                ? const Center(child: _PulsingHint('TAP A CORNER TO PICK'))
                : _ConfidenceSlider(
                    key: ValueKey('${bout.redCornerId}-${pick!.fighterId}'),
                    pick: pick!,
                    pickedName: byId[pick!.fighterId]?.name ??
                        (pick!.fighterId == bout.redCornerId
                            ? bout.redName
                            : bout.blueName),
                    onChanged: (p) =>
                        ref.read(pickemProvider.notifier).setPick(
                              event.id,
                              boutIndex,
                              pick!.copyWith(percent: p),
                            ),
                    onNext: onPicked,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Slow attention pulse for the empty-state hint. Implicit-animation
/// ping-pong via [AnimatedOpacity.onEnd] — no controller, deterministic.
class _PulsingHint extends StatefulWidget {
  const _PulsingHint(this.text);

  final String text;

  @override
  State<_PulsingHint> createState() => _PulsingHintState();
}

class _PulsingHintState extends State<_PulsingHint> {
  bool _dim = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _dim = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AnimatedOpacity(
      opacity: _dim ? 0.35 : 1.0,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      onEnd: () {
        if (mounted) setState(() => _dim = !_dim);
      },
      child: Text(
        widget.text,
        style: t.labelSmall?.copyWith(
          color: c.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _PosterCorner extends StatelessWidget {
  const _PosterCorner({
    required this.fighter,
    required this.fallbackName,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final Fighter? fighter;
  final String fallbackName;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final name =
        fighter?.name ?? (fallbackName.isEmpty ? 'TBD' : fallbackName);
    final img = fighter?.imageUrl ?? '';
    final record = fighter?.record.display ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: dimmed ? 0.45 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF19191B), Color(0xFF0E0E10)],
            ),
            shape: OctagonBorderShape(
              cut: 16,
              side: BorderSide(
                color: selected ? c.brand : const Color(0xFF262628),
                width: selected ? 2 : 1,
              ),
            ),
            shadows: selected
                ? [
                    BoxShadow(
                      color: c.brand.withValues(alpha: 0.35),
                      blurRadius: 24,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (img.isNotEmpty)
                      ShaderMask(
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
                        child: Image(image: appImageProvider(img),
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.75),
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    if (selected)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: c.brand,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded,
                              size: 18, color: c.onBrand),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        name.toUpperCase(),
                        maxLines: 1,
                        style: t.headlineSmall?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (record.isNotEmpty)
                      Text(
                        record,
                        style: t.bodySmall
                            ?.copyWith(color: c.textSecondary),
                      ),
                    // Thin brand baseline that draws in under the name
                    // when this corner is picked.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(top: 6),
                      height: 2,
                      width: selected ? 44 : 0,
                      decoration: BoxDecoration(
                        color: c.brand,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: c.brand.withValues(alpha: 0.7),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
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

/// Draggable 0–100 confidence with zone label and a NEXT confirm.
class _ConfidenceSlider extends StatefulWidget {
  const _ConfidenceSlider({
    super.key,
    required this.pick,
    required this.pickedName,
    required this.onChanged,
    required this.onNext,
  });

  final FightPick pick;
  final String pickedName;
  final ValueChanged<int> onChanged;
  final VoidCallback onNext;

  @override
  State<_ConfidenceSlider> createState() => _ConfidenceSliderState();
}

class _ConfidenceSliderState extends State<_ConfidenceSlider> {
  late double _value = widget.pick.percent.toDouble();

  String get _zone => _value >= 75
      ? 'LOCK'
      : _value >= 40
          ? 'CONFIDENT'
          : 'COIN FLIP';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${_value.round()}%',
              // Gold once the pick enters the LOCK zone.
              style: t.headlineSmall?.copyWith(
                color: _value >= 75 ? c.accent : c.brand,
                fontWeight: FontWeight.w800,
              ),
            ),
            AppSpacing.hGapSm,
            Text(
              _zone,
              style: t.labelSmall?.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            // Track matches the % readout: gold once inside the LOCK zone.
            activeTrackColor: _value >= 75 ? c.accent : c.brand,
            inactiveTrackColor: const Color(0xFF2A2A2C),
            thumbColor: Colors.white,
            overlayColor: c.brand.withValues(alpha: 0.15),
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Slider(
                value: _value,
                min: 0,
                max: 100,
                onChanged: (v) {
                  // Tick when crossing a confidence zone boundary.
                  final before = _value >= 75
                      ? 2
                      : _value >= 40
                          ? 1
                          : 0;
                  final after = v >= 75
                      ? 2
                      : v >= 40
                          ? 1
                          : 0;
                  if (before != after) HapticFeedback.selectionClick();
                  setState(() => _value = v);
                },
                onChangeEnd: (v) => widget.onChanged(v.round()),
              ),
              // Faint hairlines marking the 40 and 75 zone boundaries.
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    // Matches the default slider track inset (overlay
                    // radius), so flex positions line up with values.
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Spacer(flex: 40),
                        Container(
                          width: 2,
                          height: 12,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        const Spacer(flex: 35),
                        Container(
                          width: 2,
                          height: 12,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        const Spacer(flex: 25),
                      ],
                    ),
                  ),
                ),
              ),
              // Zone end labels under the track ends.
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: 0,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coin flip',
                        style:
                            t.labelSmall?.copyWith(color: c.textTertiary),
                      ),
                      Text(
                        'Lock',
                        style: t.labelSmall?.copyWith(
                          color: _value >= 75 ? c.accent : c.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: 'Next',
            size: AppButtonSize.sm,
            onPressed: widget.onNext,
          ),
        ),
      ],
    );
  }
}

/// "Main card done — guess the prelims too?" opt-in gate.
class _PrelimsGatePage extends StatelessWidget {
  const _PrelimsGatePage({
    required this.count,
    required this.onGuess,
    required this.onSkip,
  });

  final int count;
  final VoidCallback onGuess;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: AppSpacing.allLg,
      child: OctagonCard(
        cut: 20,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF19191B), Color(0xFF0F0F11)],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.0,
                    colors: [
                      c.brand.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.allLg,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.sports_mma_rounded, size: 40, color: c.brand),
                  AppSpacing.vGapMd,
                  Text(
                    'MAIN CARD DONE',
                    textAlign: TextAlign.center,
                    style: t.labelSmall?.copyWith(
                      color: c.brand,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  Text(
                    'GUESS THE\nPRELIMS TOO?',
                    textAlign: TextAlign.center,
                    style: t.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  AppSpacing.vGapSm,
                  Text(
                    '$count more fights • extra points, extra glory',
                    textAlign: TextAlign.center,
                    style: t.bodySmall?.copyWith(color: c.textSecondary),
                  ),
                  AppSpacing.vGapXl,
                  AppButton(
                    label: 'Guess Prelims',
                    isFullWidth: true,
                    onPressed: onGuess,
                  ),
                  AppSpacing.vGapSm,
                  AppButton(
                    label: 'Skip to Summary',
                    variant: AppButtonVariant.ghost,
                    isFullWidth: true,
                    onPressed: onSkip,
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

/// YOUR CARD: every pick as its own object — portrait, confidence, risk
/// badge — plus the bonus pick, risk score and submit.
class _SummaryPage extends ConsumerWidget {
  const _SummaryPage({
    required this.event,
    required this.bouts,
    required this.byId,
    required this.card,
  });

  final Event event;
  final List<Bout> bouts;
  final Map<String, Fighter> byId;
  final PickCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final mainCount = event.mainCard.length;
    final madeMain = card.picks.keys.where((i) => i < mainCount).length;
    final madePrelims =
        card.picks.keys.where((i) => i >= mainCount).length;
    final complete = madeMain == mainCount;
    final dna = analyzeCard(card, event, byId);

    final ordered = card.picks.keys.toList()..sort();

    return ListView(
      padding: AppSpacing.allLg,
      children: [
        Text(
          'YOUR CARD',
          textAlign: TextAlign.center,
          style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        AppSpacing.vGapXs,
        Text(
          '$madeMain/$mainCount main card'
          '${madePrelims > 0 ? ' • +$madePrelims prelims' : ''}',
          textAlign: TextAlign.center,
          style: t.bodySmall?.copyWith(color: c.textSecondary),
        ),
        AppSpacing.vGapLg,
        for (final i in ordered)
          if (i < bouts.length)
            _CardPickRow(
              event: event,
              bout: bouts[i],
              boutIndex: i,
              pick: card.picks[i]!,
              byId: byId,
            ),
        AppSpacing.vGapLg,
        OctagonCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _SummaryStat(
                    value: '${dna.favorites}', label: 'FAVORITES'),
              ),
              Container(
                width: 1,
                height: 30,
                color: const Color(0xFF232325),
              ),
              Expanded(
                child: _SummaryStat(
                    value: '${dna.underdogs}', label: 'UNDERDOGS'),
              ),
              Container(
                width: 1,
                height: 30,
                color: const Color(0xFF232325),
              ),
              Expanded(
                child: _SummaryStat(
                  value: '${dna.riskScore}',
                  label: 'RISK',
                  color: dna.riskScore >= 60
                      ? c.brand
                      : dna.riskScore >= 35
                          ? c.warning
                          : c.success,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGapLg,
        Text(
          'BONUS: ANY SUBMISSION TONIGHT?',
          textAlign: TextAlign.center,
          style: t.labelSmall?.copyWith(
            color: c.brand,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        AppSpacing.vGapSm,
        // Chips span the content width so they align with the stat strip.
        Row(
          children: [
            for (final (label, value) in [('Yes', true), ('No', false)]) ...[
              if (!value) AppSpacing.hGapSm,
              Expanded(
                child: _BonusChip(
                  label: label,
                  selected: card.anySubmission == value,
                  onTap: () => ref
                      .read(pickemProvider.notifier)
                      .setAnySubmission(event.id, value),
                ),
              ),
            ],
          ],
        ),
        AppSpacing.vGapLg,
        if (!complete)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Finish the main card to submit',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: c.warning),
            ),
          ),
        // Brand glow while the card is ready to lock — the payoff moment.
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            boxShadow: complete
                ? [
                    BoxShadow(
                      color: c.brand.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: AppButton(
            label: card.submitted ? 'Update Picks' : 'Lock In Picks',
            isFullWidth: true,
            onPressed: complete
                ? () async {
                    HapticFeedback.heavyImpact();
                    await ref.read(pickemProvider.notifier).submit(event.id);
                    if (context.mounted) {
                      await _showLockedInSheet(
                          context, event, madeMain + madePrelims);
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

/// Post-lock celebration: picks locked, share now or view the card.
Future<void> _showLockedInSheet(
    BuildContext context, Event event, int pickCount) {
  final c = context.colors;
  final t = context.text;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    builder: (sheetContext) => Container(
      margin: AppSpacing.allMd,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1C1E), Color(0xFF0F0F11)],
        ),
        shape: OctagonBorderShape(
          cut: 18,
          side: BorderSide(color: c.brand.withValues(alpha: 0.6)),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.8),
                  radius: 1.1,
                  colors: [
                    c.brand.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.allXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: c.brand.withValues(alpha: 0.16),
                    shape: const OctagonBorderShape(cut: 10),
                  ),
                  child: Icon(Icons.lock_rounded, color: c.brand, size: 28),
                ),
                AppSpacing.vGapMd,
                Text(
                  '$pickCount PICKS LOCKED IN',
                  textAlign: TextAlign.center,
                  style: t.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                AppSpacing.vGapXs,
                Text(
                  'Your card is set for '
                  '${event.eventType.isEmpty ? event.name : event.eventType}. '
                  'Call your shot before the cage door closes.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: c.textSecondary),
                ),
                AppSpacing.vGapLg,
                AppButton(
                  label: 'Share My Card',
                  icon: Icons.ios_share_rounded,
                  isFullWidth: true,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.pushReplacement(
                        AppRoutes.pickemSharePath(event.id));
                  },
                ),
                AppSpacing.vGapSm,
                AppButton(
                  label: 'View My Card',
                  variant: AppButtonVariant.ghost,
                  isFullWidth: true,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.pushReplacement(
                        AppRoutes.pickemResultsPath(event.id));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      children: [
        Text(
          value,
          style: t.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: t.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

/// A single pick as a collectible object: portrait, name, confidence meter
/// and its risk badge.
class _CardPickRow extends StatelessWidget {
  const _CardPickRow({
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final fighter = byId[pick.fighterId];
    final name = fighter?.name ??
        (pick.fighterId == bout.redCornerId ? bout.redName : bout.blueName);
    final oppName = pick.fighterId == bout.redCornerId
        ? (byId[bout.blueCornerId]?.name ?? bout.blueName)
        : (byId[bout.redCornerId]?.name ?? bout.redName);

    final favorite = isFavoritePick(bout, pick.fighterId, byId);
    final community = communityPct(event.id, boutIndex, pick.fighterId);
    final (badge, badgeColor) = !favorite && community < 35
        ? ('UPSET', c.brand)
        : !favorite
            ? ('RISKY', c.warning)
            : ('SAFE', c.success);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: OctagonCard(
        cut: 12,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            AppAvatar(
              name: name,
              imageUrl: fighter?.imageUrl ?? '',
              size: 40,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'vs $oppName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall
                        ?.copyWith(color: c.textSecondary),
                  ),
                  AppSpacing.vGapXs,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pick.percent / 100,
                      minHeight: 3,
                      backgroundColor: const Color(0xFF2A2A2C),
                      valueColor: AlwaysStoppedAnimation(c.brand),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapMd,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pick.percent}%',
                  style: t.labelLarge?.copyWith(
                    color: c.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                AppSpacing.vGapXs,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.16),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(
                    badge,
                    style: t.labelSmall?.copyWith(
                      fontSize: 9,
                      color: badgeColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
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

class _BonusChip extends StatelessWidget {
  const _BonusChip({
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
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: ShapeDecoration(
          color: selected ? c.brand : const Color(0xFF141414),
          shape: OctagonBorderShape(
            cut: 10,
            side: BorderSide(
              color: selected ? c.brand : const Color(0xFF3A3A3C),
            ),
          ),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(
            color: selected ? c.onBrand : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
