import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/providers/app_providers.dart';
import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/features/onboarding/presentation/widgets/walkout_style_card.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// "Your Walkout" aura card: shows the fan style chosen during onboarding as
/// a dark gradient card with a radial glow tinted in the style's color.
/// Tapping opens the onboarding style picker so the user can change it. When
/// no style is stored yet, it becomes a "Choose your walkout" CTA.
class WalkoutAuraCard extends ConsumerStatefulWidget {
  const WalkoutAuraCard({super.key});

  @override
  ConsumerState<WalkoutAuraCard> createState() => _WalkoutAuraCardState();
}

class _WalkoutAuraCardState extends ConsumerState<WalkoutAuraCard> {
  Future<void> _openStylePicker() async {
    await context.push(AppRoutes.fanStyle);
    // SharedPreferences isn't reactive — re-read the stored style once the
    // picker route has been popped off the stack.
    if (mounted) setState(() {});
  }

  FanStyle? get _storedStyle {
    final title = ref.read(storageServiceProvider).fanStyle;
    if (title == null) return null;
    for (final style in fanStyles) {
      if (style.title == title) return style;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = _storedStyle;
    final auraColor = style?.color ?? c.brand;

    return Pressable(
      onTap: _openStylePicker,
      borderRadius: AppRadius.brLg,
      semanticLabel: style != null
          ? 'Your walkout: ${style.title}. Tap to change.'
          : 'Choose your walkout',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          border: Border.all(color: auraColor.withValues(alpha: 0.4)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(c.surface, auraColor, 0.10)!,
              c.surface,
              c.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Radial aura tinted with the style color, bleeding off the
            // top-right corner.
            Positioned(
              top: -56,
              right: -56,
              child: IgnorePointer(
                child: Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        auraColor.withValues(alpha: 0.30),
                        auraColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.allMd,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: auraColor.withValues(alpha: 0.14),
                      border:
                          Border.all(color: auraColor.withValues(alpha: 0.5)),
                    ),
                    child: Icon(
                      style?.icon ?? Icons.sports_mma_rounded,
                      size: 24,
                      color: auraColor,
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR WALKOUT',
                          style: context.text.labelSmall?.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                        AppSpacing.vGapXs,
                        Text(
                          style?.title.toUpperCase() ?? 'CHOOSE YOUR WALKOUT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.headlineSmall?.copyWith(
                            color: style != null ? auraColor : c.textPrimary,
                          ),
                        ),
                        AppSpacing.vGapXs,
                        Text(
                          style != null
                              ? 'Tap to change'
                              : 'Pick the fan style that fits you',
                          style: context.text.labelSmall?.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Icon(Icons.chevron_right_rounded, color: c.textTertiary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
