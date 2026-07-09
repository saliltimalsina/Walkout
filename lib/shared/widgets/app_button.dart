import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';
import 'pressable.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

enum AppButtonSize { sm, md, lg }

/// The app's primary action widget. One widget, many variants/sizes — no
/// bespoke button implementations elsewhere.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  bool get _enabled => onPressed != null && !isLoading;

  double get _height => switch (size) {
        AppButtonSize.sm => 40,
        AppButtonSize.md => 48,
        AppButtonSize.lg => 56,
      };

  double get _horizontalPadding => switch (size) {
        AppButtonSize.sm => AppSpacing.md,
        AppButtonSize.md => AppSpacing.lg,
        AppButtonSize.lg => AppSpacing.xl,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = _resolveStyle(c);

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(style.foreground),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18, color: style.foreground),
            AppSpacing.hGapSm,
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelLarge?.copyWith(color: style.foreground),
            ),
          ),
          if (trailingIcon != null) ...[
            AppSpacing.hGapSm,
            Icon(trailingIcon, size: 18, color: style.foreground),
          ],
        ],
      ],
    );

    return Opacity(
      opacity: _enabled ? 1 : 0.5,
      child: Pressable(
        enabled: _enabled,
        onTap: onPressed,
        borderRadius: AppRadius.brMd,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: _height,
          width: isFullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: AppRadius.brMd,
            border: style.border,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }

  _ButtonStyle _resolveStyle(AppColors c) {
    return switch (variant) {
      AppButtonVariant.primary => _ButtonStyle(
          background: c.brand,
          foreground: c.onBrand,
        ),
      AppButtonVariant.destructive => _ButtonStyle(
          background: c.danger,
          foreground: c.onBrand,
        ),
      AppButtonVariant.secondary => _ButtonStyle(
          background: c.surfaceElevated,
          foreground: c.textPrimary,
          border: Border.all(color: c.border),
        ),
      AppButtonVariant.ghost => _ButtonStyle(
          background: Colors.transparent,
          foreground: c.textPrimary,
        ),
    };
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Border? border;
}
