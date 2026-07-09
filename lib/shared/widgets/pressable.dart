import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_motion.dart';

/// Subtle press feedback used by tappable primitives (buttons, cards, tiles).
/// Scales to [pressedScale] while held — the small, premium-feeling motion the
/// design system standardizes on. Respects [enabled] and disables reduce-motion
/// awkwardness by keeping the effect tiny.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.pressedScale = 0.97,
    this.borderRadius,
    this.semanticLabel,
    this.haptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final double pressedScale;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  /// Light selection tick on press-down; the app-wide tactile default.
  final bool haptics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _setPressed(bool value) {
    if (!_interactive) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: _interactive,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        onTapDown: (_) {
          if (_interactive && widget.haptics) {
            HapticFeedback.selectionClick();
          }
          _setPressed(true);
        },
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1.0,
          duration: AppDuration.fast,
          curve: AppCurves.emphasized,
          child: widget.child,
        ),
      ),
    );
  }
}
