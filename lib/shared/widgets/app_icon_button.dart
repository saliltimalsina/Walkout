import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/utils/context_extensions.dart';
import 'pressable.dart';

/// Compact, tappable icon affordance with optional filled/outlined surface.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.filled = false,
    this.size = 40,
    this.iconSize = 20,
    this.color,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filled;
  final double size;
  final double iconSize;
  final Color? color;

  /// Renders a small dot indicator (e.g. unread notifications).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;

    Widget button = Pressable(
      enabled: enabled,
      onTap: onPressed,
      semanticLabel: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? c.surfaceElevated : Colors.transparent,
          borderRadius: AppRadius.brMd,
          border: filled ? Border.all(color: c.border) : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: iconSize,
          color: (color ?? c.textPrimary).withValues(alpha: enabled ? 1 : 0.4),
        ),
      ),
    );

    if (badge) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: c.brand,
                shape: BoxShape.circle,
                border: Border.all(color: c.background, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
