import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/pressable.dart';

/// The house "aura" card shell shared by bout and marquee cards: vertical
/// dark gradient surface (surfaceElevated → surface), 1px token border and
/// a faint red radial glow rising from the centre.
class AuraCard extends StatelessWidget {
  const AuraCard({
    super.key,
    required this.child,
    this.glowAlpha = 0.22,
    this.height,
    this.onTap,
  });

  final Widget child;

  /// Strength of the red radial glow: 0.22 for marquee cards, 0.12 for
  /// compact rows.
  final double glowAlpha;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final card = Container(
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

    if (onTap == null) return card;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.brLg,
      child: card,
    );
  }
}
