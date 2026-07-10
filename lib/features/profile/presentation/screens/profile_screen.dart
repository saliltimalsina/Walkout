import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/providers/app_providers.dart';
import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/favorites_controller.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../widgets/favorites_section.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/settings_section.dart';
import '../widgets/walkout_aura_card.dart';

/// The signed-in user's profile: identity, prediction stats, favorite
/// fighters, and app settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final favoritesCount = ref.watch(favoritesProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        loading: () => const AppLoading(),
        error: (_, __) => AppEmptyState.error(
          message: "We couldn't load your profile. Please try again.",
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) => SafeArea(
          child: SingleChildScrollView(
            child: ResponsiveCenter(
              padding: AppSpacing.allLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(user: user),
                  AppSpacing.vGapLg,
                  const WalkoutAuraCard(),
                  AppSpacing.vGapLg,
                  ProfileStats(user: user, favoritesCount: favoritesCount),
                  AppSpacing.vGapXl,
                  const FavoritesSection(),
                  AppSpacing.vGapXl,
                  const SettingsSection(),
                  AppSpacing.vGapXl,
                  AppButton(
                    label: 'Sign out',
                    variant: AppButtonVariant.destructive,
                    isFullWidth: true,
                    onPressed: () => _handleSignOut(context, ref),
                  ),
                  AppSpacing.vGapXl,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Sign out?',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed != true) return;
    // Reset the onboarding gate so the user lands back on the first screen.
    await ref.read(storageServiceProvider).setOnboardingComplete(false);
    if (context.mounted) context.go(AppRoutes.onboarding);
  }
}
