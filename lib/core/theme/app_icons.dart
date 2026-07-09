import 'package:flutter/material.dart';

/// Centralized icon set — one family (Material) used throughout the app.
/// Reference these instead of scattering raw [Icons] across widgets.
abstract final class AppIcons {
  const AppIcons._();

  // Navigation
  static const IconData home = Icons.home_rounded;
  static const IconData rankings = Icons.leaderboard_rounded;
  static const IconData events = Icons.calendar_month_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData profile = Icons.person_rounded;
  static const IconData notifications = Icons.notifications_rounded;

  // Actions
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData forward = Icons.chevron_right_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData filter = Icons.tune_rounded;
  static const IconData share = Icons.ios_share_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData favoriteBorder = Icons.favorite_border_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData play = Icons.play_arrow_rounded;

  // Domain
  static const IconData weightClass = Icons.fitness_center_rounded;
  static const IconData record = Icons.military_tech_rounded;
  static const IconData country = Icons.public_rounded;
  static const IconData ranking = Icons.trending_up_rounded;
  static const IconData live = Icons.sensors_rounded;
  static const IconData location = Icons.location_on_rounded;
  static const IconData theme = Icons.brightness_6_rounded;

  // States
  static const IconData empty = Icons.inbox_rounded;
  static const IconData error = Icons.error_outline_rounded;
}
