import 'package:flutter/material.dart';

/// Semantic color tokens exposed as a [ThemeExtension] so every widget reads
/// colors from the theme (via `context.colors`) instead of hardcoding values.
///
/// Colors are named by purpose (surface, textPrimary, danger…), never by
/// appearance (red500, gray900).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brand,
    required this.brandContainer,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceOverlay,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.onBrand,
    required this.success,
    required this.warning,
    required this.danger,
    required this.skeleton,
  });

  final Color brand;
  final Color brandContainer;
  final Color secondary;
  final Color accent;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceOverlay;

  final Color border;
  final Color divider;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color onBrand;

  final Color success;
  final Color warning;
  final Color danger;

  final Color skeleton;

  /// UFC-inspired dark palette (default).
  static const AppColors dark = AppColors(
    brand: Color(0xFFD20A0A),
    brandContainer: Color(0xFF3A0808),
    secondary: Color(0xFFF5F5F5),
    accent: Color(0xFFFACC15),
    background: Color(0xFF090909),
    surface: Color(0xFF141414),
    surfaceElevated: Color(0xFF1C1C1E),
    surfaceOverlay: Color(0xE6141414),
    border: Color(0xFF2C2C2C),
    divider: Color(0xFF232323),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA3A3A3),
    textTertiary: Color(0xFF707070),
    textDisabled: Color(0xFF4A4A4A),
    onBrand: Color(0xFFFFFFFF),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFACC15),
    danger: Color(0xFFEF4444),
    skeleton: Color(0xFF1F1F1F),
  );

  /// Light palette.
  static const AppColors light = AppColors(
    brand: Color(0xFFD20A0A),
    brandContainer: Color(0xFFFCE4E4),
    secondary: Color(0xFF141414),
    accent: Color(0xFFB45309),
    background: Color(0xFFF7F7F8),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceOverlay: Color(0xE6FFFFFF),
    border: Color(0xFFE4E4E7),
    divider: Color(0xFFEDEDF0),
    textPrimary: Color(0xFF0A0A0A),
    textSecondary: Color(0xFF52525B),
    textTertiary: Color(0xFF8A8A94),
    textDisabled: Color(0xFFB8B8C0),
    onBrand: Color(0xFFFFFFFF),
    success: Color(0xFF16A34A),
    warning: Color(0xFFCA8A04),
    danger: Color(0xFFDC2626),
    skeleton: Color(0xFFECECEF),
  );

  @override
  AppColors copyWith({
    Color? brand,
    Color? brandContainer,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceOverlay,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? onBrand,
    Color? success,
    Color? warning,
    Color? danger,
    Color? skeleton,
  }) {
    return AppColors(
      brand: brand ?? this.brand,
      brandContainer: brandContainer ?? this.brandContainer,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      onBrand: onBrand ?? this.onBrand,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      skeleton: skeleton ?? this.skeleton,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandContainer: Color.lerp(brandContainer, other.brandContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
    );
  }
}
