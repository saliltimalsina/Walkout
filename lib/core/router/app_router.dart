import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../features/onboarding/presentation/screens/build_your_corner_screen.dart';
import '../../features/onboarding/presentation/screens/never_miss_a_fight_screen.dart';
import '../../features/onboarding/presentation/screens/whats_your_walkout_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/fighter/presentation/screens/fighter_detail_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/pickem/presentation/screens/pick_flow_screen.dart';
import '../../features/pickem/presentation/screens/pickem_results_screen.dart';
import '../../features/pickem/presentation/screens/pickem_screen.dart';
import '../../features/pickem/presentation/screens/share_card_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/rankings/presentation/screens/rankings_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../constants/app_constants.dart';
import '../providers/app_providers.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Centralized app router. Exposed as a provider so the onboarding-gate redirect
/// can read persisted state from [StorageService].
final goRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(storageServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // The splash always plays; it decides where to go when it finishes.
      if (state.matchedLocation == AppRoutes.splash) return null;
      // Dev mode: no gate — cold-start lands on onboarding, navigation is free.
      if (AppConstants.alwaysShowOnboarding) return null;
      final onboarded = storage.onboardingComplete;
      final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!onboarded && !atOnboarding) return AppRoutes.onboarding;
      if (onboarded && atOnboarding) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.nSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.nOnboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.buildCorner,
        name: AppRoutes.nBuildCorner,
        builder: (context, state) => const BuildYourCornerScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifyPrefs,
        name: AppRoutes.nNotifyPrefs,
        builder: (context, state) => const NeverMissAFightScreen(),
      ),
      GoRoute(
        path: AppRoutes.fanStyle,
        name: AppRoutes.nFanStyle,
        builder: (context, state) => const WhatsYourWalkoutScreen(),
      ),

      // Bottom-nav shell with four persistent branches.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.nHome,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rankings,
                name: AppRoutes.nRankings,
                builder: (context, state) => const RankingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.pickem,
                name: AppRoutes.nPickem,
                builder: (context, state) => const PickemScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.events,
                name: AppRoutes.nEvents,
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.nProfile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes pushed over the shell.
      GoRoute(
        path: AppRoutes.search,
        name: AppRoutes.nSearch,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.nNotifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.fighter,
        name: AppRoutes.nFighter,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            FighterDetailScreen(fighterId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.event,
        name: AppRoutes.nEvent,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.pickemFlow,
        name: AppRoutes.nPickemFlow,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            PickFlowScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.pickemResults,
        name: AppRoutes.nPickemResults,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            PickemResultsScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.pickemShare,
        name: AppRoutes.nPickemShare,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ShareCardScreen(eventId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
