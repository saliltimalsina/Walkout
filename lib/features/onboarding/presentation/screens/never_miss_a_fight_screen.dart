import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/providers/app_providers.dart';
import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/pressable.dart';
import '../providers/notify_providers.dart';
import '../providers/onboarding_flow.dart';
import '../widgets/notify_fighter_card.dart';
import '../widgets/onboarding_bottom_cta.dart';
import '../widgets/onboarding_info_card.dart';
import '../widgets/onboarding_step_header.dart';

/// Onboarding step 2: choose who/what to be notified about.
class NeverMissAFightScreen extends ConsumerWidget {
  const NeverMissAFightScreen({super.key});

  Future<void> _next(BuildContext context, WidgetRef ref) async {
    await ref.read(storageServiceProvider).setNotifyEnabled(true);
    if (context.mounted) context.go(AppRoutes.fanStyle);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final fighters = ref.watch(notifyCandidatesProvider);
    final notify = ref.watch(notifyFightersProvider);
    final ppv = ref.watch(notifyPpvProvider);
    final fightNights = ref.watch(notifyFightNightsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingStepHeader(
              current: 1,
              total: kOnboardingSteps,
              onBack: () => context.go(AppRoutes.buildCorner),
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
                        const TextSpan(text: 'NEVER MISS\nA '),
                        TextSpan(text: 'FIGHT', style: TextStyle(color: c.brand)),
                      ]),
                      style: context.text.displayLarge
                          ?.copyWith(fontWeight: FontWeight.w800, height: 0.95),
                    ),
                    AppSpacing.vGapSm,
                    Text(
                      'Get notified about the fighters and events you care about.',
                      style: context.text.bodyMedium
                          ?.copyWith(color: c.textSecondary),
                    ),
                    AppSpacing.vGapLg,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('WHO SHOULD WE NOTIFY YOU ABOUT?',
                              style: context.text.labelMedium?.copyWith(
                                  color: c.textSecondary, letterSpacing: 0.5)),
                        ),
                        Text('Tap to toggle',
                            style: context.text.labelSmall
                                ?.copyWith(color: c.textTertiary)),
                      ],
                    ),
                    AppSpacing.vGapMd,
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.70,
                      children: [
                        for (final f in fighters)
                          NotifyFighterCard(
                            fighter: f,
                            selected: notify.contains(f.id),
                            onTap: () => ref
                                .read(notifyFightersProvider.notifier)
                                .toggle(f.id),
                          ),
                      ],
                    ),
                    AppSpacing.vGapMd,
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _EventNotifyCard(
                              title: 'UFC PPVs',
                              subtitle: 'All Pay-Per-Views',
                              selected: ppv,
                              onTap: () => ref
                                  .read(notifyPpvProvider.notifier)
                                  .update((v) => !v),
                            ),
                          ),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: _EventNotifyCard(
                              title: 'Fight Nights',
                              subtitle: 'All Fight Nights',
                              selected: fightNights,
                              onTap: () => ref
                                  .read(notifyFightNightsProvider.notifier)
                                  .update((v) => !v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vGapLg,
                    const OnboardingInfoCard(
                      icon: AppIcons.notifications,
                      title: 'Stay ahead of every moment.',
                      message:
                          "We'll send you alerts for fights, news, weigh-ins, "
                          'and exclusive updates.',
                    ),
                    AppSpacing.vGapMd,
                  ],
                ),
              ),
            ),
            OnboardingBottomCta(
              label: 'Enable Notifications',
              icon: AppIcons.notifications,
              enabled: true,
              onPressed: () => _next(context, ref),
              footnote: 'You can change this anytime in settings.',
              footnoteIcon: Icons.lock_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventNotifyCard extends StatelessWidget {
  const _EventNotifyCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.brLg,
      child: Container(
        padding: AppSpacing.allMd,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.brandContainer, c.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.brLg,
          border: Border.all(color: selected ? c.brand : c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(AppIcons.events, size: 18, color: c.textSecondary),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected ? c.brand : c.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? c.brand : c.border),
                  ),
                  child: Icon(
                    selected
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    size: 14,
                    color: selected ? c.onBrand : c.textTertiary,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapMd,
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall
                    ?.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}
