import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/app_providers.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/storage_service.dart';
import 'features/home_widgets/home_widget_service.dart';
import 'shared/data/app_dataset.dart';

/// Runs in a background isolate when the dashboard publishes a data-changed
/// push while the app is closed. Re-renders the home-screen widgets from the
/// latest Firestore data. No-op until the backend is live.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.init();
  final storage = await StorageService.init();
  AppDataset.reset();
  await HomeWidgetService.refresh(storage);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize local storage before the app starts so the router's onboarding
  // gate and the theme controller can read persisted state synchronously.
  final storage = await StorageService.init();

  if (AppConstants.firebaseEnabled) {
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
    await FirebaseBootstrap.init();
  }

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const WalkoutApp(),
    ),
  );
}
