import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';

import 'card_label.dart';
import 'event_countdown.dart';
import 'glow_vs.dart';
import '../../../../shared/widgets/app_image.dart';

/// Full-bleed hero for the next event: cover art, stacked main-event names,
/// bout line, date · venue and a live countdown.
class FeaturedEventCard extends StatelessWidget {
  const FeaturedEventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.height = 400,
  });

  final Event event;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final parts =
        event.subtitle.split(RegExp(r'\s+vs\.?\s+', caseSensitive: false));
    final main = event.mainEvent;
    final wl = main == null
        ? ''
        : (main.weightLabel.isNotEmpty
            ? main.weightLabel
            : main.weightClass.label);
    final boutLine = main == null
        ? ''
        : (main.isTitleFight ? '$wl Championship' : '$wl Bout');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.brXl,
          border: Border.all(color: c.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: event.heroImage.isNotEmpty
                  ? Image(image: appImageProvider(event.heroImage),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) =>
                          ColoredBox(color: c.surfaceElevated),
                    )
                  : ColoredBox(color: c.surfaceElevated),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x00000000),
                      Color(0xD9000000),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            if (event.eventType.isNotEmpty)
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Text(
                    event.eventType.toUpperCase(),
                    style: cardLabelStyle(context, color: c.onBrand),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: AppSpacing.allLg,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (parts.length == 2)
                      HeroMatchupLine(red: parts[0], blue: parts[1])
                    else
                      HeroName(event.subtitle),
                    if (boutLine.isNotEmpty) ...[
                      AppSpacing.vGapXs,
                      Text(
                        boutLine.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: cardLabelStyle(context, color: Colors.white70),
                      ),
                    ],
                    AppSpacing.vGapSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.events,
                            size: 13, color: Colors.white70),
                        AppSpacing.hGapXs,
                        Text(
                          event.date.mediumDate,
                          style:
                              t.bodySmall?.copyWith(color: Colors.white70),
                        ),
                        if (event.location.isNotEmpty ||
                            event.venue.isNotEmpty) ...[
                          AppSpacing.hGapSm,
                          Container(
                              width: 1, height: 12, color: Colors.white24),
                          AppSpacing.hGapSm,
                          const Icon(AppIcons.location,
                              size: 13, color: Colors.white70),
                          AppSpacing.hGapXs,
                          Flexible(
                            child: Text(
                              [
                                if (event.venue.isNotEmpty) event.venue,
                                if (event.location.isNotEmpty)
                                  event.location,
                              ].join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                        ],
                      ],
                    ),
                    AppSpacing.vGapMd,
                    EventCountdown(event: event, compact: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "TOPURIA VS OLIVEIRA" on one line — bold names, red VS, shrinks to fit.
class HeroMatchupLine extends StatelessWidget {
  const HeroMatchupLine({super.key, required this.red, required this.blue});

  final String red;
  final String blue;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: red.toUpperCase()),
            GlowVs.span(context, size: 16),
            TextSpan(text: blue.toUpperCase()),
          ],
        ),
        maxLines: 1,
        style: context.text.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class HeroName extends StatelessWidget {
  const HeroName(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        style: context.text.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
