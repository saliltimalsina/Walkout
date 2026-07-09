import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_motion.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/fighter.dart';
import 'package:walkout/shared/widgets/app_avatar.dart';

/// A single corner slot: an empty "+" target, or a chosen fighter's portrait
/// with a name label and a remove badge. Fills with a scale/fade transition.
class CornerSlot extends StatelessWidget {
  const CornerSlot({
    super.key,
    required this.fighter,
    this.onRemove,
    this.size = 64,
  });

  final Fighter? fighter;
  final VoidCallback? onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    final f = fighter;

    final child = f == null
        ? _Empty(size: size, key: const ValueKey('empty'))
        : _Filled(
            key: ValueKey(f.id),
            fighter: f,
            size: size,
            onRemove: onRemove,
          );

    return AnimatedSwitcher(
      duration: AppDuration.medium,
      switchInCurve: AppCurves.emphasized,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween(begin: 0.6, end: 1.0).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: child,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.size, super.key});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.surface.withValues(alpha: 0.4),
        border: Border.all(color: c.border),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.add_rounded, color: c.textTertiary, size: size * 0.4),
    );
  }
}

class _Filled extends StatelessWidget {
  const _Filled({
    required this.fighter,
    required this.size,
    this.onRemove,
    super.key,
  });

  final Fighter fighter;
  final double size;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size + 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                name: fighter.name,
                imageUrl: fighter.imageUrl,
                size: size,
                borderColor: c.brand,
              ),
              Positioned(
                right: -4,
                top: -4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: c.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.background, width: 2),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 13, color: c.onBrand),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fighter.name.split(' ').last.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.text.labelSmall?.copyWith(color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}
