import 'package:flutter/animation.dart';

/// Motion tokens. Keep animations subtle and under ~300ms.
abstract final class AppDuration {
  const AppDuration._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);
}

abstract final class AppCurves {
  const AppCurves._();

  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve decelerate = Curves.decelerate;
}
