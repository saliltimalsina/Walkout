import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../providers/home_theme.dart';
import '../widgets/featured_event_hero.dart';
import '../widgets/fight_card_section.dart';
import '../widgets/fight_pass_banner.dart';
import '../widgets/latest_stories_section.dart';
import '../widgets/rankings_movers_section.dart';
import '../widgets/stats_leaders_section.dart';
import '../widgets/the_pulse_section.dart';
import '../widgets/trending_section.dart';
import '../widgets/upcoming_events_section.dart';
import '../widgets/your_corner_rail.dart';

/// Premium home feed: featured event hero, champions rail, upcoming events and
/// a fighters shortlist. Each section owns its own loading / error state so a
/// single failure never blanks the whole page.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(featuredEventProvider);
    ref.invalidate(championsProvider);
    ref.invalidate(upcomingEventsProvider);
    ref.invalidate(fightersProvider);
    await Future.wait([
      ref.read(featuredEventProvider.future),
      ref.read(championsProvider.future),
      ref.read(upcomingEventsProvider.future),
      ref.read(fightersProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final unread = ref.watch(unreadNotificationCountProvider);
    final tint = ref.watch(currentHomeTintProvider) ?? c.background;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tint, c.background],
          stops: const [0.0, 0.5],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: AppSpacing.lg,
        title: const _Wordmark(),
        actions: [
          AppIconButton(
            icon: AppIcons.search,
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.search),
          ),
          AppSpacing.hGapXs,
          AppIconButton(
            icon: AppIcons.notifications,
            tooltip: 'Notifications',
            badge: unread > 0,
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          AppSpacing.hGapXs,
          const _ProfileAvatarButton(),
          AppSpacing.hGapSm,
        ],
      ),
      body: RefreshIndicator(
        color: c.brand,
        backgroundColor: c.surface,
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: const [
            ResponsiveCenter(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FeaturedEventHero(),
                  AppSpacing.vGapXl,
                  YourCornerRail(),
                  AppSpacing.vGapXl,
                  FightCardSection(),
                  AppSpacing.vGapXl,
                  UpcomingEventsSection(),
                  AppSpacing.vGapXl,
                  ThePulseSection(),
                  AppSpacing.vGapXl,
                  TrendingSection(),
                  AppSpacing.vGapXl,
                  RankingsMoversSection(),
                  AppSpacing.vGapXl,
                  StatsLeadersSection(),
                  AppSpacing.vGapXl,
                  LatestStoriesSection(),
                  AppSpacing.vGapXl,
                  FightPassBanner(),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Profile entry point: the user's avatar when loaded, a plain icon while
/// loading or on error — the app bar never shows a blank slot.
class _ProfileAvatarButton extends ConsumerWidget {
  const _ProfileAvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return AppIconButton(
        icon: AppIcons.profile,
        tooltip: 'Profile',
        onPressed: () => context.push(AppRoutes.profile),
      );
    }
    return Tooltip(
      message: 'Profile',
      child: Pressable(
        onTap: () => context.push(AppRoutes.profile),
        semanticLabel: 'Profile',
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: AppAvatar(
              name: user.name,
              imageUrl: user.avatarUrl,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = context.text.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: 'WALK', style: TextStyle(color: c.brand)),
          TextSpan(text: 'OUT', style: TextStyle(color: c.textPrimary)),
        ],
      ),
    );
  }
}
