import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Wraps local persistence: [SharedPreferences] for small key/value settings
/// and Hive for collections (e.g. favorites). Injected via Riverpod so it can
/// be faked in tests.
class StorageService {
  StorageService._(this._prefs, this._favorites);

  final SharedPreferences _prefs;
  final Box<String> _favorites;

  /// Initializes backing stores. Call once during app bootstrap.
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    await Hive.initFlutter();
    final favorites = await Hive.openBox<String>(AppConstants.hiveFavoritesBox);
    return StorageService._(prefs, favorites);
  }

  // Theme mode: 'light' | 'dark' | 'system'
  String? get themeMode => _prefs.getString(AppConstants.prefsThemeMode);
  Future<void> setThemeMode(String value) =>
      _prefs.setString(AppConstants.prefsThemeMode, value);

  // Onboarding
  bool get onboardingComplete =>
      _prefs.getBool(AppConstants.prefsOnboardingComplete) ?? false;
  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(AppConstants.prefsOnboardingComplete, value);

  // Fan style ("The Finisher", etc.), chosen during onboarding.
  String? get fanStyle => _prefs.getString(AppConstants.prefsFanStyle);
  Future<void> setFanStyle(String value) =>
      _prefs.setString(AppConstants.prefsFanStyle, value);

  bool get notifyEnabled =>
      _prefs.getBool(AppConstants.prefsNotifyEnabled) ?? false;
  Future<void> setNotifyEnabled(bool value) =>
      _prefs.setBool(AppConstants.prefsNotifyEnabled, value);

  // Dev time-travel offset for the Living Widget (hours). The bundled
  // dataset is static, so QA/demo of fight-night states needs a shifted
  // "now". 0 in production use.
  int get widgetTimeOffsetHours =>
      _prefs.getInt(AppConstants.prefsWidgetTimeOffset) ?? 0;
  Future<void> setWidgetTimeOffsetHours(int value) =>
      _prefs.setInt(AppConstants.prefsWidgetTimeOffset, value);

  // Pick'Em cards, serialized as one JSON blob keyed by event id.
  String? get pickemData => _prefs.getString(AppConstants.prefsPickem);
  Future<void> setPickemData(String value) =>
      _prefs.setString(AppConstants.prefsPickem, value);

  // Favorites (fighter ids)
  Set<String> get favoriteFighterIds => _favorites.values.toSet();
  bool isFavorite(String id) => _favorites.containsKey(id);

  Future<void> toggleFavorite(String id) async {
    if (_favorites.containsKey(id)) {
      await _favorites.delete(id);
    } else {
      await _favorites.put(id, id);
    }
  }
}
