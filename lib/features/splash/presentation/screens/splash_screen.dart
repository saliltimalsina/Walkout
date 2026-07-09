import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_drawing/path_drawing.dart';

import 'package:walkout/core/constants/app_constants.dart';
import 'package:walkout/core/router/app_routes.dart';

/// "The Walk Begins" — cinematic splash.
///
/// One continuous shot, no cuts: darkness → a doorway of light → smoke →
/// the walk forward → arena lights ignite → the world falls away and the
/// doorway itself glides in, shrinks, and inverts into the Walkout mark.
/// The logo was the tunnel all along.
///
/// Motion language: heavy. Long eases, no springs, no bounce.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _walkDuration = Duration(milliseconds: 4600);
  static const _fadeDuration = Duration(milliseconds: 450);

  late final AnimationController _walk =
      AnimationController(vsync: this, duration: _walkDuration);
  late final AnimationController _fadeOut =
      AnimationController(vsync: this, duration: _fadeDuration);

  @override
  void initState() {
    super.initState();
    _walk.forward();
    _walk.addStatusListener((status) async {
      if (status != AnimationStatus.completed) return;
      // Let the logo breathe, then dip to black and hand over.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await _fadeOut.forward();
      if (!mounted) return;
      context.go(
        AppConstants.alwaysShowOnboarding
            ? AppRoutes.onboarding
            : AppRoutes.home,
      );
    });
  }

  @override
  void dispose() {
    _walk.dispose();
    _fadeOut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_walk, _fadeOut]),
        builder: (context, _) {
          final t = _walk.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _WalkPainter(t)),
              _Lockup(t: t),
              // Final dip to black before the home screen.
              IgnorePointer(
                child: Opacity(
                  opacity: _fadeOut.value,
                  child: const ColoredBox(color: Colors.black),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

/// Progress of [t] through [a]..[b], eased with [curve]. 0 before, 1 after.
double _seg(double t, double a, double b, [Curve curve = Curves.linear]) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return curve.transform((t - a) / (b - a));
}

// Scene boundaries (fraction of the 4.6s timeline). No dead air up front:
// the doorway starts emerging on the very first frame.
const _tDoorIn = 0.0; //     door emerges immediately
const _tSmoke = 0.14; //     ~0.6s  smoke escapes
const _tWalk = 0.30; //      ~1.4s  camera starts forward
const _tLights = 0.46; //    ~2.1s  arena lights ignite
const _tMorph = 0.62; //     ~2.9s  world falls away, door becomes the mark
const _tMorphEnd = 0.82; //  ~3.8s  icon locked
const _tWord = 0.83; //      ~3.8s  wordmark rises
const _tTag = 0.90; //       ~4.1s  tagline

// Logo geometry shared by painter and text lockup.
const _kIconSide = 84.0;
const _kIconLift = 64.0; // icon center sits this far above screen center

Rect _iconRect(Size size) => Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - _kIconLift),
      width: _kIconSide,
      height: _kIconSide,
    );

/// The Walkout mark (from assets/icon/app_icon.svg), in a 512×512 space.
/// A monolith wall with a doorway of light cut through it.
final Path _markPath512 = parseSvgPathData(
  'M115.282 76.111C126.114 75.9064 137.41 76.0482 148.272 76.0432L212.036 '
  '76.055L396.972 76.0443L397 435.842C392.646 434.703 388.869 432.825 '
  '384.747 431.085L368.986 424.523L316.037 402.45C311.172 400.433 300.385 '
  '395.165 295.835 394.515C295.999 380.984 296.031 367.453 295.933 '
  '353.922L295.912 289.66L295.96 189.937L216.246 189.986C216.039 198.556 '
  '216.178 207.773 216.183 216.37L216.193 262.168L216.256 394.15C207.621 '
  '397.215 197.472 401.752 188.924 405.342L135.542 427.754C129.119 430.379 '
  '121.428 433.783 115 436C115.423 433.348 115.297 427.627 115.293 '
  '424.786L115.257 406.41L115.217 341.259L115.238 162.374L115.245 '
  '102.729C115.258 93.8621 115.11 84.9684 115.282 76.111Z',
);

/// The doorway of light inside the mark — where the tunnel door lands.
/// (The mark's white gap: x 216..296, y 190..~435 in the 512 box.)
Rect _iconDoorRect(Size size) {
  final icon = _iconRect(size);
  return Rect.fromLTRB(
    icon.left + icon.width * 0.422,
    icon.top + icon.height * 0.371,
    icon.left + icon.width * 0.578,
    icon.top + icon.height * 0.83,
  );
}

// ---------------------------------------------------------------------------
// The one-shot painter
// ---------------------------------------------------------------------------

class _WalkPainter extends CustomPainter {
  _WalkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    final w = size.width;
    final h = size.height;
    // Centered exactly where the Android 12 system-splash icon sits, so the
    // OS→Flutter handoff doesn't hop.
    final tunnelCenter = Offset(w / 2, h * 0.5);

    // Forward walk stops where the morph begins.
    final approach = _seg(t, _tWalk, _tMorph, Curves.easeInOutCubic);
    final scale = 1.0 + approach * 1.15;

    // Already lit on frame one — the OS splash shows the same doorway, so
    // the handoff must not dip back into darkness.
    final doorIn =
        0.55 + 0.45 * _seg(t, _tDoorIn, _tSmoke, Curves.easeInOutCubic);

    // The world exhales to black as the door becomes the mark.
    final morph = _seg(t, _tMorph, _tMorphEnd, Curves.easeInOutCubic);
    final env = (1 - _seg(t, _tMorph, _tMorph + 0.10, Curves.easeInOut));

    // Tunnel-door rect glides into the icon's door rect.
    // Base size mirrors the system-splash icon (~63×192dp on a 412dp body).
    final tunnelDoor = Rect.fromCenter(
      center: tunnelCenter,
      width: w * 0.15 * scale,
      height: h * 0.21 * scale,
    );
    final door = Rect.lerp(tunnelDoor, _iconDoorRect(size), morph)!;

    final lightLift = 0.55 + 0.45 * _seg(t, _tWalk, _tMorph);
    final glow = doorIn * lightLift;

    if (env > 0.01) {
      _paintTunnelWalls(canvas, size, door, env);
      _paintFloorReflection(canvas, size, tunnelDoor, glow * env);
      _paintSmoke(canvas, size, tunnelDoor, glow * env);
      _paintArenaLights(canvas, size, tunnelDoor, scale, env);
      _paintDust(canvas, size, tunnelDoor, glow * env);
    }
    _paintDoorBecomingMark(canvas, size, door, glow, morph);
    if (env > 0.01) _paintVignette(canvas, size, env);
  }

  // -- Door → mark -----------------------------------------------------------
  //
  // The tunnel door glides into position and the white tile blooms out
  // around it; the dark mark then settles over the tile, leaving the
  // doorway as the white gap cut through it. The light never goes out —
  // it lives inside the logo.

  void _paintDoorBecomingMark(
      Canvas canvas, Size size, Rect door, double glow, double morph) {
    final icon = _iconRect(size);

    // Bloom condenses as the door shrinks; a breath of it survives around
    // the finished mark.
    final settled = _seg(t, _tMorphEnd, 1.0);
    final breathe = 0.5 +
        0.5 * math.sin((t - _tMorphEnd).clamp(0, 1) * 2 * math.pi * 3.5);
    final bloomAlpha =
        (1 - morph) * 0.30 * glow + settled * (0.05 + 0.04 * breathe);
    final bloomTarget = morph < 0.5 ? door : icon;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bloomTarget.inflate(bloomTarget.width * 0.35),
        Radius.circular(bloomTarget.width * 0.3),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: bloomAlpha)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, bloomTarget.width * 0.5),
    );

    // The white tile blooms out of the doorway — light wraps around you
    // as you cross the threshold.
    final invert = _seg(morph, 0.40, 0.88, Curves.easeInOutCubic);
    if (invert > 0) {
      final tile = Rect.lerp(door.inflate(door.width * 0.06), icon, invert)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          tile,
          // Squares off into the app icon's corner radius (32/512).
          Radius.circular(tile.width * (0.10 - 0.0375 * invert)),
        ),
        Paint()..color = Colors.white.withValues(alpha: invert),
      );
    }

    // The door of light itself. Warm in the tunnel, pure white once it is
    // the gap in the mark.
    final coreColor = Color.lerp(
      Color.lerp(Colors.white, const Color(0xFFEFEAE0), 0.35)!,
      Colors.white,
      morph,
    )!
        .withValues(alpha: glow.clamp(0.0, 1.0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        door,
        Radius.circular(door.width * 0.06 * (1 - morph)),
      ),
      Paint()..color = coreColor,
    );

    // The mark settles over the tile — the lock beat. The doorway stays
    // white because the mark is cut around it.
    final markIn = _seg(morph, 0.80, 1.0, Curves.easeOut);
    if (markIn > 0) {
      canvas.save();
      canvas.translate(icon.left, icon.top);
      canvas.scale(icon.width / 512, icon.height / 512);
      canvas.drawPath(
        _markPath512,
        Paint()
          ..color = const Color(0xFF19191B).withValues(alpha: markIn),
      );
      canvas.restore();
    }
  }

  // -- Concrete walls, barely there ------------------------------------------

  void _paintTunnelWalls(Canvas canvas, Size size, Rect door, double env) {
    final a =
        _seg(t, _tWalk, _tMorph - 0.02, Curves.easeInOutCubic) * 0.13 * env;
    if (a <= 0.005) return;
    final w = size.width, h = size.height;
    for (final left in [true, false]) {
      final xEdge = left ? 0.0 : w;
      final xDoor = left ? door.left : door.right;
      final wall = Path()
        ..moveTo(xEdge, 0)
        ..lineTo(xDoor, door.top - door.height * 0.35)
        ..lineTo(xDoor, door.bottom + door.height * 0.25)
        ..lineTo(xEdge, h)
        ..close();
      canvas.drawPath(
        wall,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: left
                ? [Colors.black, Color.lerp(Colors.black, Colors.white, 0.045)!]
                : [
                    Color.lerp(Colors.black, Colors.white, 0.045)!,
                    Colors.black
                  ],
          ).createShader(
              Rect.fromPoints(Offset(xEdge, 0), Offset(xDoor, size.height)))
          ..color = Colors.white.withValues(alpha: a),
      );
    }
  }

  // -- Polished-concrete floor catches the door light ------------------------

  void _paintFloorReflection(
      Canvas canvas, Size size, Rect door, double glow) {
    if (glow <= 0.01) return;
    final spread = door.width * 2.6;
    final path = Path()
      ..moveTo(door.left, door.bottom)
      ..lineTo(door.right, door.bottom)
      ..lineTo(door.center.dx + spread, size.height)
      ..lineTo(door.center.dx - spread, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.20 * glow),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTRB(
            door.center.dx - spread, door.bottom,
            door.center.dx + spread, size.height))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  // -- Smoke: pooling at the base, wisps escaping ----------------------------

  void _paintSmoke(Canvas canvas, Size size, Rect door, double glow) {
    final vis = _seg(t, _tSmoke, _tSmoke + 0.12, Curves.easeInOut) * glow;
    if (vis <= 0.01) return;
    final rnd = math.Random(7);
    final seconds = t * 4.6;

    for (var i = 0; i < 10; i++) {
      final phase = rnd.nextDouble();
      final speed = 0.03 + rnd.nextDouble() * 0.03;
      final side = (rnd.nextDouble() - 0.5) * 2;
      final life = (seconds * speed + phase) % 1.0;
      final px = door.center.dx +
          side * door.width * (0.5 + life * 1.7) +
          math.sin(seconds * 0.5 + i * 1.7) * door.width * 0.10;
      final py = door.bottom - door.height * 0.06 +
          math.sin(seconds * 0.4 + i) * door.height * 0.05;
      final r = door.width * (0.55 + life * 0.75);
      final alpha =
          math.sin(life * math.pi) * 0.11 * vis * (1 - life * 0.7);
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
      );
    }

    for (var i = 0; i < 12; i++) {
      final phase = rnd.nextDouble();
      final speed = 0.05 + rnd.nextDouble() * 0.04;
      final drift = (rnd.nextDouble() - 0.5) * 1.4;
      final life = (seconds * speed + phase) % 1.0;
      final px = door.center.dx +
          drift * door.width * (0.35 + life * 1.6) +
          math.sin(seconds * 0.7 + i) * door.width * 0.12;
      final py = door.bottom - life * door.height * 1.05;
      final r = door.width * (0.30 + life * 0.7);
      final litByDoor = (1 - life) * 0.75 + 0.25;
      final alpha = math.sin(life * math.pi) * 0.055 * vis * litByDoor;
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.75),
      );
    }
  }

  // -- Arena rigs: lamps on trusses in the upper corners ---------------------

  void _paintArenaLights(
      Canvas canvas, Size size, Rect door, double scale, double env) {
    final begin = _seg(t, _tLights, _tMorph);
    if (begin <= 0) return;
    final w = size.width, h = size.height;
    final drift = (scale - 1) * 0.10;
    const perRig = 4;
    for (var i = 0; i < perRig; i++) {
      final f = i / (perRig - 1);
      final on = _seg(t, _tLights + i * 0.024, _tLights + i * 0.024 + 0.03);
      if (on <= 0) continue;
      final sinceOn = t - (_tLights + i * 0.024 + 0.03);
      final flicker = sinceOn < 0.018 && sinceOn > 0
          ? 0.5 + 0.5 * math.sin(t * 800 + i * 3)
          : 1.0;
      final x = w * (0.07 + f * 0.28) * (1 - drift * 0.6);
      final y = h * (0.06 + f * 0.085) * (1 - drift) + h * 0.02;
      final r = (5.5 - f * 2.5) * (0.85 + scale * 0.15);
      final a = (0.55 + 0.35 * (1 - f)) * on * flicker * env;
      for (final mirror in [false, true]) {
        final p = Offset(mirror ? w - x : x, y);
        canvas.drawCircle(
            p,
            r * 4.5,
            Paint()
              ..color = Colors.white.withValues(alpha: a * 0.13)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 3.5));
        final flare = Paint()
          ..color = Colors.white.withValues(alpha: a * 0.35)
          ..strokeWidth = r * 0.28
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35);
        canvas.drawLine(
            p - Offset(r * 3.2, 0), p + Offset(r * 3.2, 0), flare);
        canvas.drawLine(
            p - Offset(0, r * 2.4), p + Offset(0, r * 2.4), flare);
        canvas.drawCircle(
            p,
            r,
            Paint()
              ..color = Colors.white.withValues(alpha: a)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3));
        final target = Offset(door.center.dx, door.bottom + door.height * 0.1);
        final dir = (target - p);
        final len = dir.distance * 0.85;
        final n = dir / dir.distance;
        final perp = Offset(-n.dy, n.dx);
        final beam = Path()
          ..moveTo(p.dx, p.dy)
          ..lineTo((p + n * len + perp * r * 4).dx,
              (p + n * len + perp * r * 4).dy)
          ..lineTo((p + n * len - perp * r * 4).dx,
              (p + n * len - perp * r * 4).dy)
          ..close();
        canvas.drawPath(
            beam,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: a * 0.055),
                  Colors.white.withValues(alpha: 0),
                ],
              ).createShader(Rect.fromPoints(p, p + n * len))
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.5));
      }
    }
  }

  // -- Dust drifting through the beam ----------------------------------------

  void _paintDust(Canvas canvas, Size size, Rect door, double glow) {
    final vis = _seg(t, _tSmoke, _tWalk) * glow;
    if (vis <= 0.02) return;
    final rnd = math.Random(23);
    final seconds = t * 4.6;
    for (var i = 0; i < 22; i++) {
      final phase = rnd.nextDouble();
      final speed = 0.03 + rnd.nextDouble() * 0.04;
      final life = (seconds * speed + phase) % 1.0;
      final px = door.center.dx +
          (rnd.nextDouble() - 0.5) * door.width * 3.4 +
          math.sin(seconds * 0.9 + i * 2.1) * 6;
      final py = door.top + life * door.height * 1.6;
      final nearLight =
          1 - ((px - door.center.dx).abs() / (door.width * 2)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(px, py),
        0.9 + (i % 3) * 0.5,
        Paint()
          ..color = Colors.white.withValues(
              alpha: 0.30 * vis * nearLight * math.sin(life * math.pi)),
      );
    }
  }

  // -- Keeps the frame's edges black no matter how bright it gets ------------

  void _paintVignette(Canvas canvas, Size size, double env) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.05),
          radius: 1.15,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.55 * env),
          ],
          stops: const [0.55, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_WalkPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Wordmark + tagline (painter owns the icon for pixel continuity)
// ---------------------------------------------------------------------------

class _Lockup extends StatelessWidget {
  const _Lockup({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final wordIn = _seg(t, _tWord, _tWord + 0.06, Curves.easeOutCubic);
    if (wordIn == 0) return const SizedBox.shrink();
    final tagIn = _seg(t, _tTag, _tTag + 0.06, Curves.easeOut);

    return Align(
      alignment: Alignment.center,
      child: Padding(
        // Sits below the icon painted at (center - _kIconLift).
        padding: const EdgeInsets.only(top: _kIconSide + 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: wordIn,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - wordIn)),
                child: Text(
                  'WALKOUT',
                  style: GoogleFonts.archivoNarrow(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: tagIn,
              child: Text(
                'EVERY FIGHT. EVERY FAN.',
                style: GoogleFonts.archivoNarrow(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4.5,
                  color: const Color(0xFFD20A0A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
