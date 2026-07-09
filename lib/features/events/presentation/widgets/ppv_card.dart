import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';

import 'card_label.dart';
import 'glow_vs.dart';

/// Poster-style event card: cover art, date badge, stacked main-event names,
/// venue and bout line. Used on the events PPV rail and the home feed.
class PpvCard extends StatelessWidget {
  const PpvCard({
    super.key,
    required this.event,
    required this.onTap,
    this.highlight = false,
  });

  static const double height = 280;
  static const double width = 240;

  final Event event;
  final VoidCallback onTap;

  /// The nearest event gets a brand-colored border.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final parts =
        event.subtitle.split(RegExp(r'\s+vs\.?\s+', caseSensitive: false));
    final main = event.mainEvent;
    final isTitle = main?.isTitleFight ?? false;
    final wl = main == null
        ? ''
        : (main.weightLabel.isNotEmpty
            ? main.weightLabel
            : main.weightClass.label);

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            border: Border.all(
              color: highlight ? c.brand : c.border,
              width: highlight ? 1.5 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (event.heroImage.isNotEmpty)
                Image.asset(
                  event.heroImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: c.surfaceElevated),
                )
              else
                ColoredBox(color: c.surfaceElevated),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Color(0x00000000),
                      Color(0xE6000000),
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: AppSpacing.allMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _DateBadge(date: event.date),
                        const Spacer(),
                        Text(
                          event.eventType.toUpperCase(),
                          style: cardLabelStyle(context),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (parts.length == 2) ...[
                      _PosterName(parts[0], suffix: 'VS'),
                      _PosterName(parts[1]),
                    ] else
                      _PosterName(event.subtitle),
                    AppSpacing.vGapSm,
                    Row(
                      children: [
                        const Icon(AppIcons.location,
                            size: 12, color: Colors.white70),
                        AppSpacing.hGapXs,
                        Expanded(
                          child: Text(
                            [
                              if (event.venue.isNotEmpty) event.venue,
                              if (event.location.isNotEmpty) event.location,
                            ].join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(
                                color: Colors.white70, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                    if (wl.isNotEmpty) ...[
                      AppSpacing.vGapXs,
                      Row(
                        children: [
                          Icon(
                            isTitle ? AppIcons.record : AppIcons.weightClass,
                            size: 12,
                            color: isTitle ? c.accent : Colors.white70,
                          ),
                          AppSpacing.hGapXs,
                          Expanded(
                            child: Text(
                              isTitle ? '$wl Title Bout' : '$wl Bout',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(
                                  color: Colors.white70, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _PosterName extends StatelessWidget {
  const _PosterName(this.text, {this.suffix});
  final String text;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text.toUpperCase(),
        children: [
          if (suffix != null)
            GlowVs.span(context, size: 12, text: ' $suffix'),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.titleLarge?.copyWith(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        height: 1.2,
      ),
    );
  }
}

/// Small stacked "JUN 28" badge on poster cards.
class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: AppRadius.brSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date.monthShort.toUpperCase(),
            style: cardLabelStyle(context, color: Colors.white),
          ),
          Text(
            '${date.day}'.padLeft(2, '0'),
            style: t.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
