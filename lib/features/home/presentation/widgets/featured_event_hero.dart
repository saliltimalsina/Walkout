import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_motion.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/features/events/presentation/widgets/featured_event_card.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';
import '../providers/home_theme.dart';

/// Full-bleed, swipeable event hero (UFC-style) driven by real cover art.
class FeaturedEventHero extends ConsumerStatefulWidget {
  const FeaturedEventHero({super.key});

  @override
  ConsumerState<FeaturedEventHero> createState() => _FeaturedEventHeroState();
}

class _FeaturedEventHeroState extends ConsumerState<FeaturedEventHero> {
  /// Peek carousel: neighbouring covers peek in from the edges.
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Resolve the cover's tint (cached) and push it to the home background.
  void _applyTint(String asset) {
    ref.read(heroTintProvider(asset).future).then((color) {
      if (mounted) ref.read(currentHomeTintProvider.notifier).state = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(upcomingEventsProvider);
    final height =
        (MediaQuery.sizeOf(context).height * 0.5).clamp(360.0, 440.0).toDouble();

    return async.when(
      loading: () => AppSkeleton(height: height, borderRadius: AppRadius.brXl),
      error: (_, __) => _HeroErrorCard(
        onRetry: () => ref.invalidate(upcomingEventsProvider),
      ),
      data: (all) {
        final events = all.take(5).toList();
        if (events.isEmpty) return const SizedBox.shrink();
        // Tint the page for the first cover once.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ref.read(currentHomeTintProvider) == null) {
            _applyTint(events[_page.clamp(0, events.length - 1)].heroImage);
          }
        });
        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _controller,
                itemCount: events.length,
                onPageChanged: (i) {
                  setState(() => _page = i);
                  _applyTint(events[i].heroImage);
                },
                itemBuilder: (context, i) => _ScaledPage(
                  controller: _controller,
                  index: i,
                  fallbackPage: _page,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: FeaturedEventCard(
                      event: events[i],
                      height: height,
                      onTap: () =>
                          context.push(AppRoutes.eventPath(events[i].id)),
                    ),
                  ),
                ),
              ),
            ),
            if (events.length > 1) ...[
              AppSpacing.vGapMd,
              _Dots(count: events.length, active: _page),
            ],
          ],
        );
      },
    );
  }
}

/// Scales a page down slightly as it moves away from the viewport centre so
/// the peeking neighbours read as background depth. Driven directly by the
/// [PageController] scroll position — no extra tickers, no jank.
class _ScaledPage extends StatelessWidget {
  const _ScaledPage({
    required this.controller,
    required this.index,
    required this.fallbackPage,
    required this.child,
  });

  final PageController controller;
  final int index;
  final int fallbackPage;
  final Widget child;

  static const double _minScale = 0.94;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final page =
            controller.hasClients && controller.position.haveDimensions
                ? controller.page ?? fallbackPage.toDouble()
                : fallbackPage.toDouble();
        final distance = (page - index).abs().clamp(0.0, 1.0).toDouble();
        return Transform.scale(
          scale: 1.0 - (1.0 - _minScale) * distance,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Branded fallback when the events feed fails: dark card with a retry.
class _HeroErrorCard extends StatelessWidget {
  const _HeroErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: AppSpacing.allLg,
      borderRadius: AppRadius.brXl,
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 28, color: c.textTertiary),
          AppSpacing.vGapSm,
          Text(
            "Couldn't load events",
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: c.textSecondary),
          ),
          AppSpacing.vGapMd,
          AppButton(
            label: 'Retry',
            size: AppButtonSize.sm,
            variant: AppButtonVariant.secondary,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDuration.fast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active ? c.brand : c.border,
              borderRadius: AppRadius.brPill,
            ),
          ),
      ],
    );
  }
}
