import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/providers/app_providers.dart';
import 'package:walkout/core/router/app_routes.dart';

/// Marks onboarding complete and routes to Home. Called from the final step or
/// any "Skip".
Future<void> completeOnboarding(BuildContext context, WidgetRef ref) async {
  await ref.read(storageServiceProvider).setOnboardingComplete(true);
  if (context.mounted) context.go(AppRoutes.home);
}

/// Total number of profile-building onboarding steps (corner, notify, style).
const int kOnboardingSteps = 3;
