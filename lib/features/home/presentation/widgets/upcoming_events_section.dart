import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/features/events/presentation/widgets/ppv_card.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// "Upcoming Events" section: horizontal rail of poster-style event cards
/// (shared with the events screen's PPV rail); the nearest event is
/// highlighted with a brand border.
class UpcomingEventsSection extends ConsumerWidget {
  const UpcomingEventsSection({super.key});

  static const int _maxItems = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingEventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Upcoming Events',
          actionLabel: 'View all',
          onAction: () => context.push(AppRoutes.events),
        ),
        events.when(
          data: (all) {
            if (all.isEmpty) {
              return const AppEmptyState(
                title: 'No upcoming events',
                message: 'Check back soon for the next fight night.',
              );
            }
            // The hero carousel already shows the first event — start after it.
            final items = all.skip(1).take(_maxItems).toList();
            return SizedBox(
              height: PpvCard.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: items.length,
                separatorBuilder: (_, __) => AppSpacing.hGapMd,
                itemBuilder: (context, i) => PpvCard(
                  event: items[i],
                  highlight: false,
                  onTap: () =>
                      context.push(AppRoutes.eventPath(items[i].id)),
                ),
              ),
            );
          },
          loading: () => const _EventsSkeleton(),
          error: (_, __) => AppEmptyState.error(
            title: 'Could not load events',
            onRetry: () => ref.invalidate(upcomingEventsProvider),
          ),
        ),
      ],
    );
  }
}

class _EventsSkeleton extends StatelessWidget {
  const _EventsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PpvCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: 3,
        separatorBuilder: (_, __) => AppSpacing.hGapMd,
        itemBuilder: (_, __) => const AppSkeleton(
          width: PpvCard.width,
          height: PpvCard.height,
          borderRadius: AppRadius.brLg,
        ),
      ),
    );
  }
}
