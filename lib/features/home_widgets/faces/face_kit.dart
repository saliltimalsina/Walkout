import 'package:flutter/widgets.dart';

import '../widget_image_resolver.dart';

/// Shared visual language for every widget face. Faces render offscreen to
/// PNG, so everything here must paint synchronously (no ShaderMask, no
/// network images) and use only `widgets.dart` primitives.
abstract final class FaceKit {
  static const bg = Color(0xFF121214);
  static const bgDeep = Color(0xFF08080A);
  static const brand = Color(0xFFE50914);
  static const gold = Color(0xFFFACC15);
  static const green = Color(0xFF22C55E);
  static const white = Color(0xFFFFFFFF);
  static const t2 = Color(0xFFA6A6AD);
  static const t3 = Color(0xFF6E6E76);
  static const line = Color(0x22FFFFFF);

  static TextStyle anton(double s, {Color c = white}) => TextStyle(
        fontFamily: 'Anton',
        fontSize: s,
        color: c,
        height: 1.0,
        letterSpacing: 0.5,
      );

  static TextStyle over(double s, Color c, {double ls = 2}) => TextStyle(
        fontFamily: 'Inter',
        fontSize: s,
        fontWeight: FontWeight.w800,
        letterSpacing: ls,
        color: c,
      );

  static TextStyle meta(double s, Color c) => TextStyle(
        fontFamily: 'Inter',
        fontSize: s,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: c,
      );

  /// Paints a face image from a bundled asset path OR a remote CDN URL
  /// (pre-downloaded by [WidgetImageResolver]). Falls back to [fallback] (or
  /// nothing) if a remote image isn't cached, so faces never show a broken box.
  static Widget image(
    String ref, {
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    Widget? fallback,
  }) {
    final provider = WidgetImageResolver.provider(ref);
    if (provider == null) return fallback ?? const SizedBox.shrink();
    return Image(
      image: provider,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
    );
  }

  static String lastName(String? n) {
    if (n == null || n.isEmpty) return '';
    return n.trim().split(RegExp(r'\s+')).last.toUpperCase();
  }

  static Widget glowVs(double size) => Text(
        'VS',
        style: TextStyle(
          fontFamily: 'Anton',
          fontSize: size,
          color: brand,
          shadows: const [
            Shadow(color: brand, blurRadius: 16),
            Shadow(color: Color(0x80E50914), blurRadius: 32),
          ],
        ),
      );

  /// `RED VS BLUE` on one line, the VS glowing brand-red. Both names Anton.
  static Widget dualName(String red, String blue, {double size = 26}) =>
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: red),
            TextSpan(
              text: '  VS  ',
              style: TextStyle(
                fontSize: size * 0.6,
                color: brand,
                shadows: const [Shadow(color: brand, blurRadius: 14)],
              ),
            ),
            TextSpan(text: blue),
          ],
        ),
        maxLines: 1,
        style: TextStyle(
          fontFamily: 'Anton',
          fontSize: size,
          height: 1.05,
          letterSpacing: 0.5,
          color: white,
        ),
      );

  /// Card shell: diagonal near-black gradient + tinted radial aura + padding.
  static Widget scaffold({
    required Widget child,
    Color aura = brand,
    Alignment auraCenter = const Alignment(0.85, -0.5),
    double auraAlpha = 0.34,
    EdgeInsets padding = const EdgeInsets.all(14),
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg, bgDeep],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: auraCenter,
                    radius: 1.2,
                    colors: [
                      aura.withValues(alpha: auraAlpha),
                      const Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }

  /// Edge portrait: asset image fading into the card so cutouts feel
  /// full-bleed. Bottom + inner-side gradient overlays (no ShaderMask).
  static Widget portrait(
    String asset, {
    double width = 110,
    Alignment align = Alignment.bottomCenter,
    bool fadeLeft = false,
    bool fadeRight = false,
  }) {
    if (asset.isEmpty) return SizedBox(width: width);
    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image(asset, fit: BoxFit.cover, alignment: align),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x00000000),
                    bgDeep.withValues(alpha: 0.85),
                  ],
                  stops: const [0.55, 1],
                ),
              ),
            ),
          ),
          if (fadeLeft || fadeRight)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        fadeLeft ? Alignment.centerLeft : Alignment.centerRight,
                    end:
                        fadeLeft ? Alignment.centerRight : Alignment.centerLeft,
                    colors: [
                      bgDeep.withValues(alpha: 0.9),
                      const Color(0x00000000),
                    ],
                    stops: const [0, 0.6],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// A single fighter cutout bleeding off one side, its inner edge faded into
  /// the card. Use as a background layer under text. No `Opacity`/`ShaderMask`
  /// (they force a saveLayer that the offscreen capture can't flush cleanly) —
  /// dimming is done with a flat [scrim] overlay instead.
  static Widget sideCutout(
    String asset, {
    bool right = true,
    double width = 130,
    Alignment imageAlign = const Alignment(0, -0.82),
    int scrim = 0x00000000,
    bool bottomScrim = true,
  }) {
    if (asset.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image(asset, fit: BoxFit.cover, alignment: imageAlign),
            // Fade the inner edge into the card.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: right ? Alignment.centerRight : Alignment.centerLeft,
                  end: right ? Alignment.centerLeft : Alignment.centerRight,
                  colors: const [Color(0x00000000), bgDeep],
                  stops: const [0.38, 1.0],
                ),
              ),
            ),
            if (bottomScrim)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x99000000)],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
            if (scrim != 0) ColoredBox(color: Color(scrim)),
          ],
        ),
      ),
    );
  }

  /// Small bordered pill, e.g. phase / SIM tags.
  static Widget pill(String text,
      {Color c = brand, double fontSize = 8, Color? fill}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: fill ?? c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.55), width: 0.8),
      ),
      child: Text(text, style: over(fontSize, c, ls: 1.2)),
    );
  }

  /// Hairline divider.
  static Widget rule({double height = 1}) =>
      Container(height: height, color: line);
}
