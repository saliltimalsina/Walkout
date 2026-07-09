import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

/// Darkens a color until it's safe as a page background behind white/near-white
/// foreground text — targets a relative luminance that yields WCAG AA (>= ~4.5:1)
/// contrast against white, while keeping the source hue so the tint reads as
/// "from the cover".
Color deriveTint(Color base) {
  var hsl = HSLColor.fromColor(base);
  hsl = hsl.withSaturation(hsl.saturation.clamp(0.25, 0.6));
  var l = hsl.lightness.clamp(0.0, 0.35);
  var color = hsl.withLightness(l).toColor();
  // White-on-bg AA needs bg luminance <= ~0.18; aim a touch below for headroom.
  while (color.computeLuminance() > 0.15 && l > 0.05) {
    l -= 0.02;
    color = hsl.withLightness(l).toColor();
  }
  return color;
}

/// Dominant-color tint for a bundled cover image, contrast-corrected. Cached
/// per asset path.
final heroTintProvider = FutureProvider.family<Color, String>((ref, asset) async {
  if (asset.isEmpty) return const Color(0xFF090909);
  try {
    final pg = await PaletteGenerator.fromImageProvider(
      AssetImage(asset),
      size: const Size(220, 140),
      maximumColorCount: 8,
    );
    final base = pg.dominantColor?.color ??
        pg.vibrantColor?.color ??
        pg.mutedColor?.color;
    if (base == null) return const Color(0xFF090909);
    return deriveTint(base);
  } catch (_) {
    return const Color(0xFF090909);
  }
});

/// The active home background tint (from the visible hero). Null = default.
final currentHomeTintProvider = StateProvider<Color?>((ref) => null);
