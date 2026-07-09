import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ergonomic access to theme tokens and layout info from a [BuildContext].
extension AppContextX on BuildContext {
  /// Semantic color tokens for the active theme.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  TextTheme get text => Theme.of(this).textTheme;

  ThemeData get theme => Theme.of(this);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// Coarse breakpoints for responsive layout decisions.
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
}
