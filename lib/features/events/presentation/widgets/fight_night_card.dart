import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/core/utils/date_x.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import 'card_label.dart';
import 'glow_vs.dart';
import '../../../../shared/widgets/app_image.dart';

/// Full-width Fight Night row with poster energy: the main-event duo
/// portraits fade in from the right edge, the matchup gets the house
/// glowing-VS treatment, and the trailing status is time-derived — a solid
/// red LIVE pill while the card is running, otherwise a days-away label.
/// The soonest fight night gets a brand border via [highlight].
class FightNightCard extends StatelessWidget {
  const FightNightCard({
    super.key,
    required this.event,
    required this.fightersById,
    required this.onTap,
    this.highlight = false,
  });

  static const double height = 118;

  /// Width of the portrait band anchored to the right edge. The fade keeps
  /// its left half translucent, so only ~half of it is reserved from text.
  static const double _portraitBand = 168;

  final Event event;
  final Map<String, Fighter> fightersById;
  final VoidCallback onTap;

  /// The nearest fight night gets a brand-colored border.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final main = event.mainEvent;
    // CDN cutout when ingest has one, bundled asset otherwise.
    final redImg =
        main == null ? '' : (fightersById[main.redCornerId]?.photo ?? '');
    final blueImg =
        main == null ? '' : (fightersById[main.blueCornerId]?.photo ?? '');
    final hasPortraits = redImg.isNotEmpty || blueImg.isNotEmpty;

    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.brLg,
      semanticLabel: event.name,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: highlight ? c.brand : c.border,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPortraits)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: _portraitBand,
                child: _PortraitDuo(redImg: redImg, blueImg: blueImg),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DateBlock(date: event.date),
                  AppSpacing.hGapMd,
                  Container(
                    width: 2,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.brand,
                      borderRadius: AppRadius.brPill,
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Padding(
                      // Text may run under the translucent half of the fade
                      // but stays clear of the opaque portrait area.
                      padding: EdgeInsets.only(
                          right: hasPortraits ? _portraitBand * 0.45 : 0),
                      child: _Content(event: event, onArt: hasPortraits),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overline + status row, then the stacked glowing-VS matchup (both names
/// always fully visible), then one combined meta line.
class _Content extends StatelessWidget {
  const _Content({required this.event, required this.onArt});

  final Event event;

  /// Whether the right side of the card carries portrait art.
  final bool onArt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final main = event.mainEvent;
    final isTitle = main?.isTitleFight ?? false;
    final wl = main == null
        ? ''
        : main.division;

    final city = event.location.isNotEmpty
        ? event.location.split(',').first.trim()
        : event.venue;
    final overline = [
      event.eventType.isEmpty ? event.name : event.eventType,
      if (city.isNotEmpty) city,
    ].join(' • ').toUpperCase();

    // One meta line: "Sat, Aug 29 · 3:45 PM · Title Bout".
    final meta = [
      event.date.dateTimeLabel,
      if (wl.isNotEmpty) isTitle ? '$wl Title' : wl,
    ].join(' · ');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                overline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cardLabelStyle(context, color: c.textTertiary),
              ),
            ),
            AppSpacing.hGapSm,
            _StatusLabel(event: event),
          ],
        ),
        AppSpacing.vGapXs,
        ..._matchupLines(context),
        AppSpacing.vGapXs,
        Row(
          children: [
            if (isTitle) ...[
              Icon(AppIcons.record, size: 12, color: c.accent),
              AppSpacing.hGapXs,
            ],
            Flexible(
              child: Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(
                  color: isTitle ? c.accent : c.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Stacked poster names — "NURMAGOMEDOV VS" over "OPPONENT" — each line
  /// scale-to-fit so long names shrink instead of truncating.
  List<Widget> _matchupLines(BuildContext context) {
    final style = context.text.titleLarge?.copyWith(
      fontSize: 16.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      height: 1.15,
    );
    final matchup = event.subtitle.isEmpty ? event.name : event.subtitle;
    final parts =
        matchup.split(RegExp(r'\s+vs\.?\s+', caseSensitive: false));

    Widget fitted(Widget child) => Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: child,
          ),
        );

    if (parts.length != 2) {
      return [fitted(Text(matchup.toUpperCase(), style: style))];
    }
    return [
      fitted(
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: parts[0].toUpperCase()),
              GlowVs.span(context, size: 11),
            ],
          ),
          style: style,
        ),
      ),
      fitted(Text(parts[1].toUpperCase(), style: style)),
    ];
  }
}

/// Head-to-head corner portraits melting into the card leftward through the
/// house dstIn fade, so the copy on the left always stays readable. Empty
/// image paths degrade to nothing; broken assets fall back to a surface box.
class _PortraitDuo extends StatelessWidget {
  const _PortraitDuo({required this.redImg, required this.blueImg});

  final String redImg;
  final String blueImg;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget portrait(String img) {
      if (img.isEmpty) return const SizedBox.shrink();
      // CDN cutouts from ingest are URLs; roster art is bundled assets.
      if (img.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: img,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.9),
          errorWidget: (_, __, ___) => ColoredBox(color: c.surfaceElevated),
        );
      }
      return Image(image: appImageProvider(img),
        fit: BoxFit.cover,
        alignment: const Alignment(0, -0.9),
        errorBuilder: (_, __, ___) => ColoredBox(color: c.surfaceElevated),
      );
    }

    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.4, 0.82],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            children: [
              Expanded(child: portrait(redImg)),
              Expanded(child: portrait(blueImg)),
            ],
          ),
          // Seam between the two corners.
          if (redImg.isNotEmpty && blueImg.isNotEmpty)
            Center(child: Container(width: 1, color: Colors.black45)),
        ],
      ),
    );
  }
}

/// Stacked "AUG / 15" date anchor, matching the house event-card date block.
class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date.monthShort.toUpperCase(),
            style: cardLabelStyle(context),
          ),
          Text(
            '${date.day}'.padLeft(2, '0'),
            style: context.text.headlineSmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Time-derived status: a solid brand LIVE pill while the event runs,
/// otherwise a compact days-away label. Sits in the overline row so it never
/// competes with the matchup for width.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();

    if (event.isLiveAt(now)) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
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

    // Calendar-day distance, clamped so a card never shows negative days.
    final today = DateTime(now.year, now.month, now.day);
    final eventDay =
        DateTime(event.date.year, event.date.month, event.date.day);
    final days = eventDay.difference(today).inDays;
    final label = days <= 0
        ? 'TODAY'
        : days == 1
            ? 'TOMORROW'
            : 'IN $days DAYS';
    return Text(label, style: cardLabelStyle(context));
  }
}
