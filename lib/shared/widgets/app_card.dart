import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';
import 'pressable.dart';

/// Surface container primitive. Optionally tappable with press feedback.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.allMd,
    this.elevated = false,
    this.bordered = true,
    this.color,
    this.borderRadius = AppRadius.brLg,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool elevated;
  final bool bordered;
  final Color? color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (elevated ? c.surfaceElevated : c.surface),
        borderRadius: borderRadius,
        border: bordered ? Border.all(color: c.border) : null,
        boxShadow: elevated ? AppShadows.sm : AppShadows.none,
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Pressable(
      onTap: onTap,
      borderRadius: borderRadius,
      child: container,
    );
  }
}
