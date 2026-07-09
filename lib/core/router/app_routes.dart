/// Centralized route paths and names. Reference these constants for
/// navigation — never hardcode path strings at call sites.
abstract final class AppRoutes {
  const AppRoutes._();

  // Splash
  static const String splash = '/';

  // Onboarding
  static const String onboarding = '/onboarding';
  static const String buildCorner = '/onboarding/corner';
  static const String notifyPrefs = '/onboarding/notify';
  static const String fanStyle = '/onboarding/style';

  // Shell branches (bottom nav)
  static const String home = '/home';
  static const String rankings = '/rankings';
  static const String pickem = '/pickem';
  static const String events = '/events';
  static const String profile = '/profile';

  // NB: detail paths deliberately do NOT sit under '/pickem' — a sub-path of
  // a shell-branch route gets shadowed by the branch and never pushes.
  /// Pick'Em flow for one event — build / edit the card.
  static const String pickemFlow = '/pickem-flow/:id';
  static String pickemFlowPath(String id) => '/pickem-flow/$id';

  /// Pick'Em results / live progress for one event.
  static const String pickemResults = '/pickem-results/:id';
  static String pickemResultsPath(String id) => '/pickem-results/$id';

  /// Pick'Em share-card studio for one event.
  static const String pickemShare = '/pickem-share/:id';
  static String pickemSharePath(String id) => '/pickem-share/$id';

  // Pushed detail / modal routes
  static const String search = '/search';
  static const String notifications = '/notifications';

  /// Fighter detail — pass the fighter id as a path parameter.
  static const String fighter = '/fighter/:id';
  static String fighterPath(String id) => '/fighter/$id';

  /// Event detail.
  static const String event = '/event/:id';
  static String eventPath(String id) => '/event/$id';

  // Named routes (mirror the paths' final segment for readability).
  static const String nSplash = 'splash';
  static const String nOnboarding = 'onboarding';
  static const String nBuildCorner = 'buildCorner';
  static const String nNotifyPrefs = 'notifyPrefs';
  static const String nFanStyle = 'fanStyle';
  static const String nHome = 'home';
  static const String nRankings = 'rankings';
  static const String nPickem = 'pickem';
  static const String nPickemFlow = 'pickemFlow';
  static const String nPickemResults = 'pickemResults';
  static const String nPickemShare = 'pickemShare';
  static const String nEvents = 'events';
  static const String nProfile = 'profile';
  static const String nSearch = 'search';
  static const String nNotifications = 'notifications';
  static const String nFighter = 'fighter';
  static const String nEvent = 'event';
}
