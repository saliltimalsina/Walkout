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
import '../shared/providers/data_providers.dart';
import '../shared/providers/favorites_controller.dart';

/// Root application widget. Wires the router, light/dark themes, the persisted
/// theme mode, responsive breakpoints, and the home-screen widget bridge.
class WalkoutApp extends ConsumerStatefulWidget {
  const WalkoutApp({super.key});

  @override
  ConsumerState<WalkoutApp> createState() => _WalkoutAppState();
}

class _WalkoutAppState extends ConsumerState<WalkoutApp>
    with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _widgetClicks;
  DateTime _lastResumeRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHomeWidgets());
  }

  /// Foregrounding the app is the cheapest freshness trigger there is: the
  /// widgets re-render and the time-derived event lists re-filter, so a LIVE
  /// flip that happened while backgrounded shows without a pull-to-refresh.
  /// This also re-pulls Firestore (throttled to once a minute), which is what
  /// recovers a session that cold-started offline on the bundled JSON.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (now.difference(_lastResumeRefresh) < const Duration(minutes: 1)) {
      return;
    }
    _lastResumeRefresh = now;
    // Ingest runs every 30 min, so a 15-min window catches new data roughly one
    // cycle behind at worst while capping refetches at ~4/hour.
    refreshAppDataIfStale(ref, maxAge: const Duration(minutes: 15));
    unawaited(HomeWidgetService.refresh(ref.read(storageServiceProvider)));
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
    // cached dataset, re-pull the on-screen lists and re-render the widgets
    // with the latest Firestore data.
    if (AppConstants.firebaseEnabled &&
        await FirebaseBootstrap.ensureReady() &&
        mounted) {
      FirebaseMessaging.onMessage.listen((_) {
        if (!mounted) return;
        refreshAppData(ref);
        unawaited(HomeWidgetService.refresh(storage));
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
