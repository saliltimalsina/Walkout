import 'package:flutter/material.dart';

import 'package:walkout/core/utils/context_extensions.dart';

/// The house "VS" treatment — brand red, extra-bold, with the double red
/// glow (blur 16 + 32) used on the event detail matchup cards.
///
/// Use the widget standalone between stacked names, or [GlowVs.span] inline
/// inside a "NAME VS NAME" rich-text line.
class GlowVs extends StatelessWidget {
  const GlowVs({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Text('VS', style: style(context, size: size));
  }

  /// Inline span variant for matchup lines. [text] carries the surrounding
  /// spacing (e.g. `'  VS  '`).
  static TextSpan span(
    BuildContext context, {
    double size = 12,
    String text = '  VS  ',
  }) =>
      TextSpan(text: text, style: style(context, size: size));

  /// Canonical glowing-VS style: red w800 with the double shadow (16/32).
  static TextStyle? style(BuildContext context, {double size = 20}) {
    final c = context.colors;
    return context.text.titleLarge?.copyWith(
      color: c.brand,
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
      shadows: [
        Shadow(color: c.brand.withValues(alpha: 0.9), blurRadius: 16),
        Shadow(color: c.brand.withValues(alpha: 0.5), blurRadius: 32),
      ],
    );
  }
}
