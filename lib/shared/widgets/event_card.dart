import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';
import '../../core/utils/date_x.dart';
import '../models/event.dart';
import 'app_card.dart';

/// Reusable event summary card used on home and the events list.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.onTap});

  final Event event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppCard(
      onTap: onTap,
      padding: AppSpacing.allMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _DateBlock(date: event.date),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        event.name,
                        style: context.text.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (event.status == EventStatus.live) ...[
                      AppSpacing.hGapSm,
                      const _LiveDot(),
                    ],
                  ],
                ),
                if (event.subtitle.isNotEmpty) ...[
                  AppSpacing.vGapXs,
                  Text(
                    event.subtitle,
                    style: context.text.bodyMedium?.copyWith(color: c.brand),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                AppSpacing.vGapXs,
                Row(
                  children: [
                    Icon(AppIcons.location, size: 14, color: c.textTertiary),
                    AppSpacing.hGapXs,
                    Expanded(
                      child: Text(
                        event.location.isEmpty ? event.venue : event.location,
                        style: context.text.bodySmall
                            ?.copyWith(color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          Icon(AppIcons.forward, size: 20, color: c.textTertiary),
        ],
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.brandContainer,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date.monthShort.toUpperCase(),
            style: context.text.labelSmall?.copyWith(color: c.brand),
          ),
          Text(
            '${date.day}'.padLeft(2, '0'),
            style: context.text.headlineSmall?.copyWith(color: c.brand),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: c.brand,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        'LIVE',
        style: context.text.labelSmall?.copyWith(color: c.onBrand),
      ),
    );
  }
}
