/// App-wide constants. No magic strings scattered across the codebase.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Walkout';

  // Networking
  static const String baseUrl = 'https://api.walkout.example.com/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Local storage keys
  static const String prefsThemeMode = 'prefs.theme_mode';
  static const String prefsOnboardingComplete = 'prefs.onboarding_complete';
  static const String prefsFanStyle = 'prefs.fan_style';
  static const String prefsNotifyEnabled = 'prefs.notify_enabled';
  static const String prefsPickem = 'prefs.pickem_cards';
  static const String prefsWidgetTimeOffset = 'prefs.widget_time_offset_hours';
  static const String hiveFavoritesBox = 'favorites';

  // Layout
  static const double maxContentWidth = 1200;

  // Behavior
  static const bool useMockData = true;

  /// Dev flag: when true the app always cold-starts on the onboarding screen
  /// and the persisted onboarding gate is bypassed. Flip to false for the real
  /// "show onboarding once" behavior.
  static const bool alwaysShowOnboarding = false;
}
