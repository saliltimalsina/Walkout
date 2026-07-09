import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/fighter.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/favorites_controller.dart';
import 'package:walkout/shared/widgets/app_divider.dart';
import 'package:walkout/shared/widgets/app_empty_state.dart';
import 'package:walkout/shared/widgets/app_loading.dart';
import '../providers/corner_providers.dart';
import '../providers/onboarding_flow.dart';
import '../widgets/corner_filter_dock.dart';
import '../widgets/corner_fighter_row.dart';
import '../widgets/corner_octagon.dart';
import '../widgets/onboarding_bottom_cta.dart';
import '../widgets/onboarding_step_header.dart';

/// Onboarding step 1: assemble a "corner" of up to five favorite fighters.
class BuildYourCornerScreen extends ConsumerWidget {
  const BuildYourCornerScreen({super.key});

  Future<void> _next(BuildContext context, WidgetRef ref) async {
    final ids = ref.read(cornerSelectionProvider);
    if (ids.isNotEmpty) {
      await ref.read(favoritesProvider.notifier).addAll(ids);
    }
    if (context.mounted) context.go(AppRoutes.notifyPrefs);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final selection = ref.watch(cornerSelectionProvider);
    final byId = {
      for (final f in ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[])
        f.id: f,
    };
    final slotFighters = List<Fighter?>.generate(
      CornerController.maxSize,
      (i) => i < selection.length ? byId[selection[i]] : null,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingStepHeader(
              current: 0,
              total: kOnboardingSteps,
              onBack: () => context.go(AppRoutes.onboarding),
              onSkip: () => completeOnboarding(context, ref),
              trailing: Text(
                '${selection.length}/${CornerController.maxSize}',
                style: context.text.labelLarge?.copyWith(
                  color: selection.isEmpty ? c.textTertiary : c.brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.hLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'BUILD YOUR '),
                              TextSpan(
                                  text: 'CORNER',
                                  style: TextStyle(color: c.brand)),
                            ]),
                            style: context.text.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            'Pick up to 5 fighters to build your corner. '
                            'You can change it anytime.',
                            style: context.text.bodySmall
                                ?.copyWith(color: c.textSecondary),
                          ),
                          AppSpacing.vGapSm,
                          CornerOctagon(
                            fighters: slotFighters,
                            onRemove: (i) {
                              if (i < selection.length) {
                                ref
                                    .read(cornerSelectionProvider.notifier)
                                    .remove(selection[i]);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(pinned: true, delegate: _DockDelegate()),
                  const _FighterSliver(),
                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                ],
              ),
            ),
            OnboardingBottomCta(
              label: 'Continue',
              enabled: selection.isNotEmpty,
              onPressed: () => _next(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockDelegate extends SliverPersistentHeaderDelegate {
  static const double _extent = 220;

  @override
  double get minExtent => _extent;
  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.colors.background,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        children: const [
          Expanded(child: CornerFilterDock()),
          AppDivider(),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DockDelegate oldDelegate) => false;
}

class _FighterSliver extends ConsumerWidget {
  const _FighterSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cornerFilteredProvider);
    final selection = ref.watch(cornerSelectionProvider);
    final full = selection.length >= CornerController.maxSize;

    return async.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: AppSpacing.xl),
          child: AppLoading(),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: AppEmptyState.error(
          onRetry: () => ref.invalidate(fightersProvider),
        ),
      ),
      data: (fighters) {
        if (fighters.isEmpty) {
          return const SliverToBoxAdapter(
            child: AppEmptyState(
              title: 'No fighters',
              message: 'Try a different filter or search.',
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.separated(
            itemCount: fighters.length,
            separatorBuilder: (_, __) => const AppDivider(),
            itemBuilder: (context, i) {
              final f = fighters[i];
              return CornerFighterRow(
                fighter: f,
                selected: selection.contains(f.id),
                enabled: !full,
                onToggle: () =>
                    ref.read(cornerSelectionProvider.notifier).toggle(f.id),
              );
            },
          ),
        );
      },
    );
  }
}
