import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Client-side search across fighters and events for a non-empty [query].
/// [query] is already trimmed and lowercased by the parent screen.
class SearchResults extends ConsumerWidget {
  const SearchResults({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fightersAsync = ref.watch(fightersProvider);
    final upcomingAsync = ref.watch(upcomingEventsProvider);
    final pastAsync = ref.watch(pastEventsProvider);

    final fighters = fightersAsync.value;
    final upcoming = upcomingAsync.value;
    final past = pastAsync.value;

    // Only render results once every source has data; surface loading /
    // error states otherwise.
    if (fighters == null || upcoming == null || past == null) {
      final hasError = fightersAsync.hasError ||
          upcomingAsync.hasError ||
          pastAsync.hasError;
      if (hasError) {
        return AppEmptyState.error(
          message: "We couldn't load search results. Please try again.",
          onRetry: () => ref
            ..invalidate(fightersProvider)
            ..invalidate(upcomingEventsProvider)
            ..invalidate(pastEventsProvider),
        );
      }
      return const AppLoading();
    }

    final matchedFighters =
        fighters.where((f) => _matchesFighter(f, query)).toList();
    final matchedEvents = [...upcoming, ...past]
        .where((e) => _matchesEvent(e, query))
        .toList();

    if (matchedFighters.isEmpty && matchedEvents.isEmpty) {
      return const AppEmptyState(
        title: 'No results',
        message: 'Try a fighter, division, or event name.',
        icon: AppIcons.search,
      );
    }

    return ListView(
      padding: AppSpacing.allMd,
      children: [
        if (matchedFighters.isNotEmpty) ...[
          SectionHeader(title: 'Fighters (${matchedFighters.length})'),
          for (final fighter in matchedFighters) ...[
            FighterListCard(
              fighter: fighter,
              onTap: () => context.push(AppRoutes.fighterPath(fighter.id)),
            ),
            AppSpacing.vGapSm,
          ],
          AppSpacing.vGapMd,
        ],
        if (matchedEvents.isNotEmpty) ...[
          SectionHeader(title: 'Events (${matchedEvents.length})'),
          for (final event in matchedEvents) ...[
            EventCard(
              event: event,
              onTap: () => context.push(AppRoutes.eventPath(event.id)),
            ),
            AppSpacing.vGapSm,
          ],
        ],
      ],
    );
  }

  bool _matchesFighter(Fighter fighter, String q) {
    return fighter.name.toLowerCase().contains(q) ||
        fighter.nickname.toLowerCase().contains(q) ||
        fighter.country.toLowerCase().contains(q) ||
        fighter.weightClass.label.toLowerCase().contains(q);
  }

  bool _matchesEvent(Event event, String q) {
    return event.name.toLowerCase().contains(q) ||
        event.subtitle.toLowerCase().contains(q) ||
        event.location.toLowerCase().contains(q);
  }
}
