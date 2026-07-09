import 'package:flutter/material.dart';

/// Typography tokens. A single type scale drives the whole app.
///
/// Styles intentionally omit color — color is applied by the theme's
/// [TextTheme] / [DefaultTextStyle] so text follows the active color scheme.
abstract final class AppTypography {
  const AppTypography._();

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  static const FontWeight extraBold = FontWeight.w800;

  /// Body / UI font — Inter (bundled asset; no runtime fetch so background
  /// widget renders always have the face available).
  static TextStyle _base(double size, double height, FontWeight weight,
      {double? letterSpacing}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  /// Display / heading font — Anton, a heavy condensed block face; the
  /// closest free match to UFC's headline typography. Single ultra-bold
  /// weight, so requested weights are decorative only. Bundled asset.
  static TextStyle _display(double size, double height, FontWeight weight,
      {double letterSpacing = 0.4}) {
    return TextStyle(
      fontFamily: 'Anton',
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  // Condensed lets us set larger optical sizes without overflowing.
  static TextStyle get displayXl => _display(50, 54, extraBold);
  static TextStyle get displayL => _display(42, 46, extraBold);

  static TextStyle get h1 => _display(36, 40, extraBold);
  static TextStyle get h2 => _display(30, 34, extraBold);
  static TextStyle get h3 => _display(26, 30, bold);
  static TextStyle get h4 => _display(22, 26, bold);

  static TextStyle get bodyL => _base(18, 28, regular);
  static TextStyle get bodyM => _base(16, 24, regular);
  static TextStyle get bodyS => _base(14, 20, regular);

  static TextStyle get caption => _base(12, 16, medium);
  static TextStyle get overline =>
      _base(11, 14, semiBold, letterSpacing: 1.0);

  static TextStyle get button => _base(15, 20, semiBold, letterSpacing: 0.2);

  /// Builds a Material [TextTheme] from the scale, tinting with [color].
  static TextTheme textTheme(Color color) {
    final t = TextTheme(
      displayLarge: displayXl,
      displayMedium: displayL,
      displaySmall: _display(36, 40, extraBold),
      headlineLarge: h1,
      headlineMedium: h2,
      headlineSmall: h3,
      titleLarge: h4,
      bodyLarge: bodyL,
      bodyMedium: bodyM,
      bodySmall: bodyS,
      labelLarge: button,
      labelMedium: caption,
      labelSmall: overline,
    );
    return t.apply(bodyColor: color, displayColor: color);
  }
}
