import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/features/pickem/presentation/widgets/confetti.dart';
import 'package:walkout/features/pickem/presentation/widgets/octagon_card.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/pickem_controller.dart';
import 'package:walkout/shared/widgets/widgets.dart';
import '../../../../shared/widgets/app_image.dart';

/// The four share formats. Results and Upset only exist once fights finish.
enum ShareFormat {
  fightCard('My Fight Card'),
  challenge('Challenge'),
  results('Results'),
  upset('Upset Call');

  const ShareFormat(this.label);
  final String label;
}

/// Story-ready share cards: pick a format, preview it 9:16, export as an
/// image straight to the system share sheet.
class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final _boundaryKey = GlobalKey();
  ShareFormat _format = ShareFormat.fightCard;
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/walkout_${_format.name}_${widget.eventId}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)]);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final fighters =
        ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[];
    final profile = ref.watch(currentUserProvider).valueOrNull;
    final card = ref.watch(pickemProvider)[widget.eventId];

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('SHARE')),
      body: eventAsync.when(
        loading: () => const AppLoading(),
        error: (_, __) => AppEmptyState.error(
          message: 'We could not load this card.',
          onRetry: () => ref.invalidate(eventProvider(widget.eventId)),
        ),
        data: (event) {
          if (card == null || card.picks.isEmpty) {
            return const AppEmptyState(
              title: 'No picks yet',
              message: 'Build your card first, then share it.',
            );
          }
          final byId = {for (final f in fighters) f.id: f};
          final score = scoreCard(card, event);
          final handle = (profile?.handle.isNotEmpty ?? false)
              ? profile!.handle
              : '@walkout';
          final userName =
              (profile?.name.isNotEmpty ?? false) ? profile!.name : 'You';

          final upset = _bestUpset(card, event, byId);
          final formats = [
            ShareFormat.fightCard,
            ShareFormat.challenge,
            if (score.graded > 0) ShareFormat.results,
            if (upset != null) ShareFormat.upset,
          ];
          if (!formats.contains(_format)) _format = formats.first;

          return Column(
            children: [
              AppSpacing.vGapMd,
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: formats.length,
                  separatorBuilder: (_, __) => AppSpacing.hGapSm,
                  itemBuilder: (context, i) {
                    final f = formats[i];
                    final selected = f == _format;
                    return Center(
                      child: Pressable(
                        onTap: () => setState(() => _format = f),
                        semanticLabel: f.label,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? c.brand
                                : const Color(0xFF141414),
                            borderRadius: AppRadius.brPill,
                            border: Border.all(
                              color: selected
                                  ? c.brand
                                  : const Color(0xFF3A3A3C),
                            ),
                          ),
                          child: Text(
                            f.label,
                            style: context.text.labelMedium?.copyWith(
                              color:
                                  selected ? c.onBrand : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              AppSpacing.vGapMd,
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: switch (_format) {
                        ShareFormat.fightCard => _FightCardPoster(
                            event: event,
                            card: card,
                            byId: byId,
                            handle: handle,
                          ),
                        ShareFormat.challenge => _ChallengePoster(
                            event: event,
                            card: card,
                            userName: userName,
                            handle: handle,
                          ),
                        ShareFormat.results => _ResultsPoster(
                            event: event,
                            card: card,
                            byId: byId,
                            score: score,
                            handle: handle,
                          ),
                        ShareFormat.upset => _UpsetPoster(
                            event: event,
                            upset: upset!,
                            byId: byId,
                            handle: handle,
                          ),
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: AppSpacing.allLg,
                child: AppButton(
                  label: _sharing ? 'Preparing…' : 'Share',
                  icon: Icons.ios_share_rounded,
                  isFullWidth: true,
                  isLoading: _sharing,
                  onPressed: _sharing ? null : _share,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The boldest correct underdog call, if any: (boutIndex, pick, communityPct).
(int, FightPick, int)? _bestUpset(
    PickCard card, Event event, Map<String, Fighter> byId) {
  final bouts = pickableBouts(event);
  (int, FightPick, int)? best;
  for (final e in card.picks.entries) {
    if (e.key >= bouts.length) continue;
    final bout = bouts[e.key];
    if (bout.winnerId == null || bout.winnerId != e.value.fighterId) {
      continue;
    }
    if (isFavoritePick(bout, e.value.fighterId, byId)) continue;
    final pct = communityPct(event.id, e.key, e.value.fighterId);
    if (pct >= 35) continue;
    if (best == null || pct < best.$3) best = (e.key, e.value, pct);
  }
  return best;
}

String _lastName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? name : parts.last;
}

// ═════════════════════════ Poster foundation ═════════════════════════
//
// Every poster is designed on a fixed 360×640 (9:16) canvas and scaled to
// fit with a FittedBox. Type sizes and layout are therefore exact and
// deterministic on any device, and overflow is impossible — the same pixels
// export at 1080×1920 through the RepaintBoundary at pixelRatio 3.

const double _canvasW = 360;
const double _canvasH = 640;

/// Saturation-0 matrix for dramatic grayscale portrait treatments.
const ColorFilter _grayscaleFilter = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// "Jones vs Aspinall" → ("Jones", "Aspinall"). Null when it doesn't parse.
(String, String)? _splitVs(String s) {
  final m = RegExp(r'\s+vs\.?\s+', caseSensitive: false).firstMatch(s);
  if (m == null) return null;
  final a = s.substring(0, m.start).trim();
  final b = s.substring(m.end).trim();
  if (a.isEmpty || b.isEmpty) return null;
  return (a, b);
}

/// Shared poster scaffold: layered dark texture (base gradient, brand glow,
/// vignette), optional full-bleed [background] art, and the Walkout footer
/// with its red accent line.
class _PosterShell extends StatelessWidget {
  const _PosterShell({
    required this.child,
    required this.handle,
    this.background,
    this.glowCenter = const Alignment(0, -0.85),
    this.glowColor,
    this.glowAlpha = 0.30,
  });

  final Widget child;
  final String handle;

  /// Full-bleed art painted behind the content (portraits, hero image…).
  final Widget? background;
  final Alignment glowCenter;
  final Color? glowColor;
  final double glowAlpha;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: const Color(0xFF060607),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _canvasW,
          height: _canvasH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster stock: near-black vertical falloff, never flat.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF18181B),
                      Color(0xFF0C0C0E),
                      Color(0xFF060607),
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
              ),
              if (background != null) Positioned.fill(child: background!),
              // Brand glow.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: glowCenter,
                    radius: 1.1,
                    colors: [
                      (glowColor ?? c.brand).withValues(alpha: glowAlpha),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Vignette: edges fall off like printed poster stock.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.1),
                    radius: 1.35,
                    colors: [Colors.transparent, Color(0xA6000000)],
                    stops: [0.55, 1],
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(child: child),
                  _Footer(handle: handle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// WALKOUT wordmark bar with the signature red rule above it.
class _Footer extends StatelessWidget {
  const _Footer({required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 3, color: c.brand),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'WALK',
                      style: TextStyle(color: c.brand),
                    ),
                    const TextSpan(
                      text: 'OUT',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                style: t.titleLarge?.copyWith(
                  fontSize: 15,
                  height: 1,
                  letterSpacing: 2.5,
                ),
              ),
              const Spacer(),
              Text(
                handle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelSmall?.copyWith(
                  fontSize: 10,
                  color: c.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fighter portrait that melts into the poster: optional grayscale, optional
/// horizontal flip, and a linear fade so the image never has a hard edge.
class _FadedPortrait extends StatelessWidget {
  const _FadedPortrait({
    required this.imageUrl,
    this.grayscale = false,
    this.flip = false,
    this.opacity = 1,
    this.alignment = const Alignment(0, -0.8),
    this.fadeBegin = Alignment.topCenter,
    this.fadeEnd = Alignment.bottomCenter,
    this.fadeStops = const [0.0, 0.62, 1.0],
  });

  final String imageUrl;
  final bool grayscale;
  final bool flip;
  final double opacity;
  final Alignment alignment;
  final Alignment fadeBegin;
  final Alignment fadeEnd;
  final List<double> fadeStops;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const SizedBox.shrink();
    Widget img = Image(image: appImageProvider(imageUrl),
      fit: BoxFit.cover,
      alignment: alignment,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
    if (flip) img = Transform.flip(flipX: true, child: img);
    if (grayscale) {
      img = ColorFiltered(colorFilter: _grayscaleFilter, child: img);
    }
    img = ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: fadeBegin,
        end: fadeEnd,
        colors: const [Colors.white, Colors.white, Colors.transparent],
        stops: fadeStops,
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: img,
    );
    return opacity == 1 ? img : Opacity(opacity: opacity, child: img);
  }
}

/// Section kicker: red rules flanking heavy letterspaced Anton.
class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    Widget bar() => Container(width: 26, height: 2, color: c.brand);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        bar(),
        const SizedBox(width: 10),
        Text(
          text,
          style: t.titleLarge?.copyWith(
            fontSize: 13,
            height: 1,
            letterSpacing: 3.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        bar(),
      ],
    );
  }
}

/// Tiny letterspaced context line, e.g. "UFC 332 • SAT, AUG 15".
class _TopTag extends StatelessWidget {
  const _TopTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: context.text.labelSmall?.copyWith(
        fontSize: 9,
        letterSpacing: 2.6,
        color: Colors.white70,
      ),
    );
  }
}

// ══════════════════════ 1 — MY FIGHT CARD ═══════════════════════════

/// UFC-poster style: main-event portraits and hero art fused into a dark
/// header under huge event type, then the pick list with headshots, locked
/// line and the Walkout footer.
class _FightCardPoster extends StatelessWidget {
  const _FightCardPoster({
    required this.event,
    required this.card,
    required this.byId,
    required this.handle,
  });

  final Event event;
  final PickCard card;
  final Map<String, Fighter> byId;
  final String handle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bouts = pickableBouts(event);
    final ordered = card.picks.keys.toList()..sort();
    final shown = ordered.take(6).toList();

    return _PosterShell(
      handle: handle,
      glowCenter: const Alignment(0, -1.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MainEventHeader(event: event, byId: byId),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  const _Kicker('MY PICKS'),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final i in shown)
                          if (i < bouts.length)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _PickRow(
                                index: shown.indexOf(i),
                                bout: bouts[i],
                                pick: card.picks[i]!,
                                byId: byId,
                              ),
                            ),
                        if (ordered.length > shown.length)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '+ ${ordered.length - shown.length} MORE ON '
                              'MY CARD',
                              style: t.titleLarge?.copyWith(
                                fontSize: 10,
                                height: 1,
                                letterSpacing: 2,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 22, height: 2, color: c.brand),
                      const SizedBox(width: 8),
                      Icon(Icons.lock_rounded, size: 12, color: c.brand),
                      const SizedBox(width: 5),
                      Text(
                        '${ordered.length} PICKS LOCKED IN',
                        style: t.titleLarge?.copyWith(
                          fontSize: 14,
                          height: 1,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 22, height: 2, color: c.brand),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MAKE YOUR PICKS ON WALKOUT',
                    style: t.labelSmall?.copyWith(
                      fontSize: 8,
                      letterSpacing: 2.4,
                      color: c.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark cinematic header: event hero art + the two main-event portraits
/// facing off, all melting downward into the pick list.
class _MainEventHeader extends StatelessWidget {
  const _MainEventHeader({required this.event, required this.byId});

  final Event event;
  final Map<String, Fighter> byId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final me = event.mainEvent;
    final red = me == null ? null : byId[me.redCornerId];
    final blue = me == null ? null : byId[me.blueCornerId];
    final names = _splitVs(event.subtitle) ??
        ((red != null && blue != null)
            ? (_lastName(red.name), _lastName(blue.name))
            : null);
    final title = event.eventType.isEmpty ? event.name : event.eventType;
    final dateLine = '${event.date.mediumDate}'
        '${event.venue.isEmpty ? '' : ' • ${event.venue}'}';

    return SizedBox(
      height: 206,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // All imagery fades to nothing at the header's bottom edge so it
          // melts into the poster body.
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.7, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (event.heroImage.isNotEmpty)
                  Opacity(
                    opacity: 0.45,
                    child: ColorFiltered(
                      colorFilter: _grayscaleFilter,
                      child: Image(image: appImageProvider(event.heroImage),
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.4),
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x66000000)),
                ),
                if ((red?.imageUrl ?? '').isNotEmpty)
                  Positioned(
                    left: -22,
                    bottom: 0,
                    width: 158,
                    height: 182,
                    child: _FadedPortrait(
                      imageUrl: red!.imageUrl,
                      alignment: const Alignment(0, -0.9),
                      fadeBegin: Alignment.centerLeft,
                      fadeEnd: Alignment.centerRight,
                      fadeStops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                if ((blue?.imageUrl ?? '').isNotEmpty)
                  Positioned(
                    right: -22,
                    bottom: 0,
                    width: 158,
                    height: 182,
                    child: _FadedPortrait(
                      imageUrl: blue!.imageUrl,
                      flip: true,
                      alignment: const Alignment(0, -0.9),
                      fadeBegin: Alignment.centerRight,
                      fadeEnd: Alignment.centerLeft,
                      fadeStops: const [0.0, 0.55, 1.0],
                    ),
                  ),
              ],
            ),
          ),
          // Diagonal brand slash for energy behind the title block.
          Positioned(
            left: -60,
            right: -60,
            top: 122,
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                height: 30,
                color: c.brand.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopTag(dateLine),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    style: t.displayLarge?.copyWith(
                      fontSize: 46,
                      height: 1,
                      letterSpacing: 1,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                if (names != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          names.$1.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleLarge?.copyWith(
                            fontSize: 15,
                            height: 1,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'VS',
                          style: t.titleLarge?.copyWith(
                            fontSize: 12,
                            height: 1,
                            color: c.brand,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          names.$2.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleLarge?.copyWith(
                            fontSize: 15,
                            height: 1,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (event.subtitle.isNotEmpty)
                  Text(
                    event.subtitle.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleLarge?.copyWith(
                      fontSize: 15,
                      height: 1,
                      letterSpacing: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One pick: chamfered octagon row — number, headshot, name, conviction,
/// status check.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.index,
    required this.bout,
    required this.pick,
    required this.byId,
  });

  final int index;
  final Bout bout;
  final FightPick pick;
  final Map<String, Fighter> byId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final fighter = byId[pick.fighterId];
    final name = fighter?.name ??
        (pick.fighterId == bout.redCornerId ? bout.redName : bout.blueName);
    final opp = pick.fighterId == bout.redCornerId
        ? (byId[bout.blueCornerId]?.name ?? bout.blueName)
        : (byId[bout.redCornerId]?.name ?? bout.redName);
    final graded = bout.winnerId != null;
    final correct = graded && bout.winnerId == pick.fighterId;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(
        color: const Color(0xCC121216),
        shape: const OctagonBorderShape(
          cut: 10,
          side: BorderSide(color: Color(0xFF29292D)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}'.padLeft(2, '0'),
              style: t.titleLarge?.copyWith(
                fontSize: 11,
                height: 1,
                color: c.brand.withValues(alpha: 0.9),
              ),
            ),
          ),
          AppAvatar(
            name: name,
            imageUrl: fighter?.imageUrl ?? '',
            size: 28,
            borderColor: const Color(0xFF3A3A40),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastName(name).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleLarge?.copyWith(
                    fontSize: 14,
                    height: 1.05,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'vs ${_lastName(opp)}'.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelSmall?.copyWith(
                    fontSize: 8,
                    letterSpacing: 1.2,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${pick.percent}%',
            style: t.labelSmall?.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(width: 7),
          Icon(
            graded
                ? (correct
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded)
                : Icons.check_circle_rounded,
            size: 17,
            color: graded
                ? (correct ? c.success : c.danger)
                : c.success.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════ 2 — HEAD-TO-HEAD CHALLENGE ═════════════════════

/// Hype battle poster built for tagging a friend: giant PICK'EM BATTLE on a
/// slashed red bar, red-vs-blue glowing avatars, a skewed glowing VS.
class _ChallengePoster extends StatelessWidget {
  const _ChallengePoster({
    required this.event,
    required this.card,
    required this.userName,
    required this.handle,
  });

  final Event event;
  final PickCard card;
  final String userName;
  final String handle;

  static const _challengerBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final firstName = userName.trim().split(RegExp(r'\s+')).first;
    final title = event.eventType.isEmpty ? event.name : event.eventType;

    return _PosterShell(
      handle: handle,
      glowCenter: Alignment.center,
      glowAlpha: 0.22,
      background: event.heroImage.isEmpty
          ? null
          : Opacity(
              opacity: 0.2,
              child: ColorFiltered(
                colorFilter: _grayscaleFilter,
                child: Image(image: appImageProvider(event.heroImage),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
      child: Stack(
        children: [
          // Corner-crossing color slashes: red for me, blue for the
          // challenger.
          Positioned(
            left: -80,
            right: -80,
            top: 208,
            child: Transform.rotate(
              angle: -0.14,
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c.brand.withValues(alpha: 0),
                      c.brand.withValues(alpha: 0.2),
                      c.brand.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -80,
            right: -80,
            top: 300,
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _challengerBlue.withValues(alpha: 0),
                      _challengerBlue.withValues(alpha: 0.16),
                      _challengerBlue.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 18),
                _TopTag('$title • ${event.date.mediumDate}'),
                const Spacer(),
                Text(
                  "PICK'EM",
                  style: t.displayLarge?.copyWith(
                    fontSize: 54,
                    height: 0.95,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Transform.rotate(
                  angle: -0.045,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 3),
                    decoration: BoxDecoration(
                      color: c.brand,
                      boxShadow: [
                        BoxShadow(
                          color: c.brand.withValues(alpha: 0.45),
                          blurRadius: 26,
                        ),
                      ],
                    ),
                    child: Text(
                      'BATTLE',
                      style: t.displayLarge?.copyWith(
                        fontSize: 42,
                        height: 1,
                        letterSpacing: 7,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BattleAvatar(
                      label: firstName,
                      glyph: firstName.isEmpty
                          ? '?'
                          : firstName[0].toUpperCase(),
                      ring: c.brand,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 26, 14, 0),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.skewX(-0.18),
                        child: Text(
                          'VS',
                          style: t.displayLarge?.copyWith(
                            fontSize: 40,
                            height: 1,
                            color: c.brand,
                            shadows: [
                              Shadow(
                                color: c.brand.withValues(alpha: 0.9),
                                blurRadius: 22,
                              ),
                              Shadow(
                                color: c.brand.withValues(alpha: 0.5),
                                blurRadius: 48,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const _BattleAvatar(
                      label: 'YOU?',
                      glyph: '?',
                      ring: _challengerBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  'WHO WILL WIN MORE?',
                  textAlign: TextAlign.center,
                  style: t.displayLarge?.copyWith(
                    fontSize: 27,
                    height: 1.08,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${card.picks.length} PICKS LOCKED • BEAT ME IF YOU CAN',
                  style: t.labelSmall?.copyWith(
                    fontSize: 9,
                    letterSpacing: 1.6,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 7, 16, 5),
                  decoration: ShapeDecoration(
                    color: const Color(0xB30D0D10),
                    shape: OctagonBorderShape(
                      cut: 9,
                      side: BorderSide(
                        color: c.brand.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  child: Text(
                    'TAG YOUR OPPONENT',
                    style: t.titleLarge?.copyWith(
                      fontSize: 12,
                      height: 1,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleLarge?.copyWith(
                    fontSize: 20,
                    height: 1,
                    letterSpacing: 1.5,
                    color: c.brand,
                  ),
                ),
                if (event.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _TopTag(event.subtitle),
                ],
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular battle avatar with a colored glow ring and name plate.
class _BattleAvatar extends StatelessWidget {
  const _BattleAvatar({
    required this.label,
    required this.glyph,
    required this.ring,
  });

  final String label;
  final String glyph;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF232329), Color(0xFF121216)],
            ),
            border: Border.all(color: ring, width: 2.5),
            boxShadow: [
              BoxShadow(color: ring.withValues(alpha: 0.55), blurRadius: 24),
              BoxShadow(
                color: ring.withValues(alpha: 0.22),
                blurRadius: 56,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Text(
            glyph,
            style: t.displayLarge?.copyWith(
              fontSize: 34,
              height: 1,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 9),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 104),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.titleLarge?.copyWith(
              fontSize: 13,
              height: 1,
              letterSpacing: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════ 3 — RESULTS CARD ══════════════════════════

/// Wrapped-style score flex: giant score, gold CORRECT, worldwide pill,
/// stat strip, best-pick chip — over deterministic confetti and a ghosted
/// best-pick portrait.
class _ResultsPoster extends StatelessWidget {
  const _ResultsPoster({
    required this.event,
    required this.card,
    required this.byId,
    required this.score,
    required this.handle,
  });

  final Event event;
  final PickCard card;
  final Map<String, Fighter> byId;
  final CardScore score;
  final String handle;

  /// Highest-conviction correct call: (fighter, lastName, method line).
  (Fighter?, String, String)? get _bestPick {
    final bouts = pickableBouts(event);
    (Fighter?, String, String)? best;
    var bestPct = -1;
    for (final e in card.picks.entries) {
      if (e.key >= bouts.length) continue;
      final b = bouts[e.key];
      if (b.winnerId != e.value.fighterId) continue;
      if (e.value.percent <= bestPct) continue;
      bestPct = e.value.percent;
      final fighter = byId[e.value.fighterId];
      final name = _lastName(fighter?.name ??
          (e.value.fighterId == b.redCornerId ? b.redName : b.blueName));
      final method = [
        if (b.method.isNotEmpty) b.method,
        if (b.finishRound.isNotEmpty) b.finishRound,
      ].join(' • ');
      best = (fighter, name.toUpperCase(), method.toUpperCase());
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final accuracy =
        score.graded == 0 ? 0.0 : score.correct / score.graded;
    final rank = (1 + (1 - accuracy) * 400).round();
    final topPct = (100 - accuracy * 97).clamp(1, 99).round();
    final best = _bestPick;
    final title = event.eventType.isEmpty ? event.name : event.eventType;

    final scoreBase = t.displayLarge?.copyWith(height: 0.95, letterSpacing: 0);

    return _PosterShell(
      handle: handle,
      glowColor: c.accent,
      glowAlpha: 0.16,
      glowCenter: const Alignment(0, -0.6),
      background: Stack(
        fit: StackFit.expand,
        children: [
          if ((best?.$1?.imageUrl ?? '').isNotEmpty)
            Positioned(
              right: -46,
              bottom: 0,
              width: 250,
              height: 330,
              child: _FadedPortrait(
                imageUrl: best!.$1!.imageUrl,
                grayscale: true,
                opacity: 0.32,
                alignment: const Alignment(0, -0.9),
                fadeBegin: Alignment.bottomCenter,
                fadeEnd: Alignment.topCenter,
                fadeStops: const [0.0, 0.5, 1.0],
              ),
            ),
          CustomPaint(
            painter: ConfettiPainter(
              colors: [c.accent, c.brand, Colors.white],
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 18),
            _TopTag('$title • ${event.date.mediumDate}'),
            const Spacer(),
            const _Kicker('MY RESULTS'),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${score.correct}',
                    style: scoreBase?.copyWith(
                      fontSize: 116,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: c.accent.withValues(alpha: 0.35),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                  TextSpan(
                    text: ' / ',
                    style:
                        scoreBase?.copyWith(fontSize: 54, color: c.brand),
                  ),
                  TextSpan(
                    text: '${score.graded}',
                    style: scoreBase?.copyWith(
                      fontSize: 54,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              score.perfect ? 'PERFECT CARD' : 'CORRECT',
              style: t.displayLarge?.copyWith(
                fontSize: 25,
                height: 1,
                letterSpacing: 8,
                color: c.accent,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 5),
              decoration: ShapeDecoration(
                color: const Color(0xB30D0D10),
                shape: OctagonBorderShape(
                  cut: 9,
                  side: BorderSide(color: c.brand.withValues(alpha: 0.85)),
                ),
              ),
              child: Text(
                'TOP $topPct% WORLDWIDE',
                style: t.titleLarge?.copyWith(
                  fontSize: 14,
                  height: 1,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const ShapeDecoration(
                color: Color(0xD9101014),
                shape: OctagonBorderShape(
                  cut: 12,
                  side: BorderSide(color: Color(0xFF2C2C32)),
                ),
              ),
              child: Row(
                children: [
                  _Stat(label: 'RANK', value: '#$rank'),
                  const _StatDivider(),
                  _Stat(label: 'POINTS', value: '${score.points}'),
                  const _StatDivider(),
                  _Stat(
                    label: 'ACCURACY',
                    value: '${(accuracy * 100).round()}%',
                  ),
                ],
              ),
            ),
            if (best != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xB30D0D10),
                  shape: OctagonBorderShape(
                    cut: 9,
                    side: BorderSide(
                      color: c.accent.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAvatar(
                      name: best.$2,
                      imageUrl: best.$1?.imageUrl ?? '',
                      size: 26,
                      borderColor: c.accent,
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BEST PICK',
                          style: t.labelSmall?.copyWith(
                            fontSize: 7.5,
                            letterSpacing: 2,
                            color: c.accent,
                          ),
                        ),
                        Text(
                          best.$3.isEmpty
                              ? best.$2
                              : '${best.$2} • ${best.$3}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleLarge?.copyWith(
                            fontSize: 13,
                            height: 1.1,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: t.titleLarge?.copyWith(fontSize: 20, height: 1),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: t.labelSmall?.copyWith(
              fontSize: 8,
              letterSpacing: 1.8,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: const Color(0xFF2C2C32));
  }
}

// ════════════════════════ 4 — UPSET CALL ════════════════════════════

/// Badge of honor: slashed red UPSET CALLED banner, giant ONLY N%, the name
/// in red, gold "You did. ✓" — over the fighter rising grayscale from the
/// bottom of the poster.
class _UpsetPoster extends StatelessWidget {
  const _UpsetPoster({
    required this.event,
    required this.upset,
    required this.byId,
    required this.handle,
  });

  final Event event;
  final (int, FightPick, int) upset;
  final Map<String, Fighter> byId;
  final String handle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bouts = pickableBouts(event);
    final bout = bouts[upset.$1];
    final fighter = byId[upset.$2.fighterId];
    final name = _lastName(fighter?.name ??
        (upset.$2.fighterId == bout.redCornerId
            ? bout.redName
            : bout.blueName));
    final title = event.eventType.isEmpty ? event.name : event.eventType;
    final bannerStyle = t.displayLarge?.copyWith(
      fontSize: 22,
      height: 1,
      letterSpacing: 3,
    );

    return _PosterShell(
      handle: handle,
      glowCenter: const Alignment(0, 1.05),
      glowAlpha: 0.38,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The underdog rises grayscale from the bottom edge.
          if ((fighter?.imageUrl ?? '').isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.52,
                widthFactor: 1,
                child: _FadedPortrait(
                  imageUrl: fighter!.imageUrl,
                  grayscale: true,
                  alignment: const Alignment(0, -0.7),
                  fadeBegin: Alignment.bottomCenter,
                  fadeEnd: Alignment.topCenter,
                  fadeStops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          // Ground shadow keeps the footer edge clean.
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 90,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x99000000)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 18),
                _TopTag('$title • ${event.date.mediumDate}'),
                const SizedBox(height: 24),
                // Slashed banner: an offset outline echo behind the red bar.
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: 0.05,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: c.brand.withValues(alpha: 0.55),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'UPSET CALLED',
                          style: bannerStyle?.copyWith(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -0.035,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                        decoration: BoxDecoration(
                          color: c.brand,
                          boxShadow: [
                            BoxShadow(
                              color: c.brand.withValues(alpha: 0.5),
                              blurRadius: 28,
                            ),
                          ],
                        ),
                        child: Text(
                          'UPSET CALLED',
                          style:
                              bannerStyle?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'ONLY',
                  style: t.displayLarge?.copyWith(
                    fontSize: 19,
                    height: 1,
                    letterSpacing: 10,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${upset.$3}%',
                  style: t.displayLarge?.copyWith(
                    fontSize: 112,
                    height: 1,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: c.brand.withValues(alpha: 0.55),
                        blurRadius: 44,
                      ),
                    ],
                  ),
                ),
                Text(
                  'PICKED',
                  style: t.displayLarge?.copyWith(
                    fontSize: 19,
                    height: 1,
                    letterSpacing: 10,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name.toUpperCase(),
                    maxLines: 1,
                    style: t.displayLarge?.copyWith(
                      fontSize: 46,
                      height: 1,
                      letterSpacing: 1.5,
                      color: c.brand,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Transform.rotate(
                  angle: -0.025,
                  child: Text(
                    'You did. ✓',
                    style: t.bodyLarge?.copyWith(
                      fontSize: 21,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: c.accent,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'THE OTHER ${100 - upset.$3}% WERE WRONG',
                  style: t.labelSmall?.copyWith(
                    fontSize: 8.5,
                    letterSpacing: 2.4,
                    color: Colors.white70,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 10),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
