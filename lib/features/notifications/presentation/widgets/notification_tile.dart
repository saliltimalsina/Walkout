import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// A single row in the notification feed: a type icon badge (or the matched
/// fighter's portrait), the title/body/timestamp, and an unread indicator.
/// Unread tiles get a brand-red left border so they read at a glance on the
/// near-black surface. Tapping invokes [onTap] so the parent can mark the
/// notification as read and follow its deep link.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.matchedFighter,
  });

  final NotificationItem notification;
  final VoidCallback onTap;

  /// When the notification text matched a known fighter, their portrait
  /// replaces the type icon as the tile's leading visual.
  final Fighter? matchedFighter;

  IconData get _icon => switch (notification.type) {
        NotificationType.event => AppIcons.events,
        NotificationType.fight => AppIcons.record,
        NotificationType.ranking => AppIcons.ranking,
        NotificationType.news => AppIcons.notifications,
        NotificationType.system => AppIcons.settings,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isUnread = !notification.read;
    final iconColor =
        notification.type == NotificationType.ranking ? c.accent : c.brand;

    final fighter = matchedFighter;
    final Widget leading = fighter != null
        ? AppAvatar(name: fighter.name, imageUrl: fighter.imageUrl, size: 44)
        : Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brandContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 20, color: iconColor),
          );

    final card = AppCard(
      onTap: onTap,
      elevated: isUnread,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                    color: isUnread ? c.textPrimary : c.textSecondary,
                  ),
                ),
                if (notification.body.isNotEmpty) ...[
                  AppSpacing.vGapXs,
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
                AppSpacing.vGapXs,
                Text(
                  notification.timestamp.relativeFrom(DateTime.now()),
                  style: context.text.labelSmall?.copyWith(
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            AppSpacing.hGapSm,
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
              ),
            ),
          ],
        ],
      ),
    );

    if (!isUnread) return card;

    // Unread affordance: a 3px brand-red edge. The elevated surface and the
    // dot alone don't register against the near-black background.
    return ClipRRect(
      borderRadius: AppRadius.brLg,
      child: Stack(
        children: [
          card,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(width: 3, color: c.brand),
            ),
          ),
        ],
      ),
    );
  }
}
