import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_providers.dart';
import '../core/router/app_router.dart';
import '../core/services/firebase_bootstrap.dart';
import '../core/theme/app_theme.dart';
import '../features/home_widgets/home_widget_service.dart';
import '../shared/data/app_dataset.dart';
import '../shared/providers/favorites_controller.dart';

/// Root application widget. Wires the router, light/dark themes, the persisted
/// theme mode, responsive breakpoints, and the home-screen widget bridge.
class WalkoutApp extends ConsumerStatefulWidget {
  const WalkoutApp({super.key});

  @override
  ConsumerState<WalkoutApp> createState() => _WalkoutAppState();
}

class _WalkoutAppState extends ConsumerState<WalkoutApp> {
  StreamSubscription<Uri?>? _widgetClicks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHomeWidgets());
  }

  Future<void> _initHomeWidgets() async {
    // Cold-launch from a widget tap: route to its deep link.
    final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    final launchRoute = HomeWidgetService.routeFromUri(launchUri);
    if (launchRoute != null && mounted) {
      ref.read(goRouterProvider).go(launchRoute);
    }
    // Warm-app widget taps.
    _widgetClicks = HomeWidget.widgetClicked.listen((uri) {
      final route = HomeWidgetService.routeFromUri(uri);
      if (route != null && mounted) ref.read(goRouterProvider).push(route);
    });
    // First render + keep faces fresh when favorites change.
    final storage = ref.read(storageServiceProvider);
    unawaited(HomeWidgetService.refresh(storage));
    ref.listenManual(favoritesProvider, (_, __) {
      unawaited(HomeWidgetService.refresh(storage));
    });

    // Dashboard publish → data-changed push while the app is open: drop the
    // cached dataset and re-render widgets with the latest Firestore data.
    if (AppConstants.firebaseEnabled && FirebaseBootstrap.isReady) {
      FirebaseMessaging.onMessage.listen((_) {
        AppDataset.reset();
        unawaited(HomeWidgetService.refresh(storage));
      });
    }
  }

  @override
  void dispose() {
    _widgetClicks?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 600, name: MOBILE),
          Breakpoint(start: 601, end: 1024, name: TABLET),
          Breakpoint(start: 1025, end: 1920, name: DESKTOP),
          Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}
