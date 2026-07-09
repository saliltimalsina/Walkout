import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../services/storage_service.dart';

/// Overridden in `main()` once [StorageService.init] resolves.
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('storageServiceProvider not initialized'),
);

/// Shared Dio client for all repositories.
final dioClientProvider = Provider<DioClient>((ref) => DioClient());

/// App theme mode, persisted to local storage.
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.read(storageServiceProvider).themeMode;
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark, // default to the dark, arena-style theme
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(storageServiceProvider).setThemeMode(mode.name);
  }

  Future<void> toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
