import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/app_providers.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/storage_service.dart';
import 'features/home_widgets/home_widget_service.dart';
import 'features/home_widgets/widget_scheduler.dart';
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

/// Runs in a background isolate for the workmanager tasks (30-min periodic
/// net + one-off phase-boundary renders) so widget PNGs stay fresh with the
/// app closed. Same headless pattern as [fcmBackgroundHandler].
@pragma('vm:entry-point')
void widgetBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await FirebaseBootstrap.init(); // tolerates failure → bundled fallback
    final storage = await StorageService.init();
    AppDataset.reset();
    await HomeWidgetService.refresh(storage);
    return true;
  });
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

  if (!kIsWeb && Platform.isAndroid) {
    await Workmanager().initialize(widgetBackgroundDispatcher);
    await WidgetScheduler.registerPeriodic();
  }

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const WalkoutApp(),
    ),
  );
}
