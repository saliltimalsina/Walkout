import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/shared/data/notification_repository.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../utils/notification_link_resolver.dart';
import '../widgets/notification_tile.dart';

/// The user's notification feed. Lets them mark everything read at once via
/// the app bar action, or tap an individual tile to mark just that one and
/// deep-link to the fighter or event it mentions.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(WidgetRef ref) async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.invalidate(notificationsProvider);
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
    NotificationLink? link,
  ) async {
    await ref.read(notificationRepositoryProvider).markRead(item.id);
    ref.invalidate(notificationsProvider);
    if (link != null && context.mounted) context.push(link.routePath);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final hasUnread = notificationsAsync.maybeWhen(
      data: (items) => items.any((item) => !item.read),
      orElse: () => false,
    );

    // Deep-link sources. Fall back to empty lists while loading so the feed
    // itself is never blocked — tiles just render without links until data
    // arrives.
    final fighters = ref.watch(fightersProvider).value ?? const <Fighter>[];
    final events = <Event>[
      ...?ref.watch(upcomingEventsProvider).value,
      ...?ref.watch(pastEventsProvider).value,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Padding(
            padding: AppSpacing.hMd,
            child: AppButton(
              label: 'Mark all read',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              onPressed: hasUnread ? () => _markAllRead(ref) : null,
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const _NotificationsLoading(),
        error: (_, __) => AppEmptyState.error(
          message: 'We couldn\'t load your notifications. Please try again.',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              title: "You're all caught up",
              message: 'New fights, results and rankings will show up here.',
              icon: AppIcons.notifications,
            );
          }

          return ListView.builder(
            padding: AppSpacing.allMd,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final link = resolveNotificationLink(
                item,
                fighters: fighters,
                events: events,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: NotificationTile(
                  notification: item,
                  matchedFighter: link?.fighter,
                  onTap: () => _handleTap(context, ref, item, link),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Skeleton placeholder shown while notifications load, echoing the shape of
/// [NotificationTile] so the layout doesn't jump once data arrives.
class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.allMd,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            child: Row(
              children: [
                const AppSkeleton.circle(size: 44),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSkeleton(width: 180, height: 14),
                      AppSpacing.vGapSm,
                      const AppSkeleton(width: 130, height: 12),
                      AppSpacing.vGapSm,
                      const AppSkeleton(width: 60, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
