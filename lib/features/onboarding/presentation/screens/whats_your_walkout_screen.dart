import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/providers/app_providers.dart';
import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import '../providers/onboarding_flow.dart';
import '../widgets/onboarding_bottom_cta.dart';
import '../widgets/onboarding_info_card.dart';
import '../widgets/onboarding_step_header.dart';
import '../widgets/walkout_style_card.dart';

final _selectedStyleProvider = StateProvider<int?>((ref) => null);

/// Onboarding step 3 (final): pick a fan style to personalize the experience.
class WhatsYourWalkoutScreen extends ConsumerWidget {
  const WhatsYourWalkoutScreen({super.key});

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final idx = ref.read(_selectedStyleProvider);
    if (idx != null) {
      await ref.read(storageServiceProvider).setFanStyle(fanStyles[idx].title);
    }
    if (context.mounted) await completeOnboarding(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final selected = ref.watch(_selectedStyleProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingStepHeader(
              current: 2,
              total: kOnboardingSteps,
              onBack: () => context.go(AppRoutes.notifyPrefs),
              onSkip: () => completeOnboarding(context, ref),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.hLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: "WHAT'S YOUR\n"),
                        TextSpan(text: 'WALKOUT?',
                            style: TextStyle(color: c.brand)),
                      ]),
                      style: context.text.displayLarge
                          ?.copyWith(fontWeight: FontWeight.w800, height: 0.95),
                    ),
                    AppSpacing.vGapSm,
                    Text(
                      'Every fan has a style. Choose the one that fits you best.',
                      style: context.text.bodyMedium
                          ?.copyWith(color: c.textSecondary),
                    ),
                    AppSpacing.vGapMd,
                    for (var i = 0; i < fanStyles.length; i++) ...[
                      WalkoutStyleCard(
                        style: fanStyles[i],
                        selected: selected == i,
                        onTap: () =>
                            ref.read(_selectedStyleProvider.notifier).state = i,
                      ),
                      AppSpacing.vGapSm,
                    ],
                    const OnboardingInfoCard(
                      icon: AppIcons.profile,
                      title: 'Your experience, your way.',
                      message:
                          "We'll customize your home feed, content, and "
                          'recommendations to match your style.',
                    ),
                    AppSpacing.vGapMd,
                  ],
                ),
              ),
            ),
            OnboardingBottomCta(
              label: 'Confirm My Walkout',
              enabled: selected != null,
              onPressed: () => _confirm(context, ref),
              footnote: 'You can change this anytime in your profile.',
              footnoteIcon: Icons.lock_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
