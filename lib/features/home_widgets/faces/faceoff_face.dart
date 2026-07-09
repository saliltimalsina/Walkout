import 'package:flutter/material.dart';

import 'package:walkout/shared/models/models.dart';

/// The Face-Off home-screen widget face: two corners edge to edge, met by a
/// red aura seam — wallpaper-grade poster of the featured fight.
///
/// Rendered OFFSCREEN to PNG via home_widget; it must not depend on
/// MediaQuery/Theme inheritance, so all colors/type come in explicitly.
class FaceoffFace extends StatelessWidget {
  const FaceoffFace({
    super.key,
    required this.event,
    required this.bout,
    required this.red,
    required this.blue,
    this.result,
  });

  final Event event;
  final Bout bout;
  final Fighter? red;
  final Fighter? blue;

  /// "FINAL · W KO" ribbon text when showing a past event fallback.
  final String? result;

  static const _bg = Color(0xFF0B0B0D);
  static const _brand = Color(0xFFD20A0A);
  static const _gold = Color(0xFFFACC15);

  @override
  Widget build(BuildContext context) {
    final wl = bout.weightLabel.isNotEmpty
        ? bout.weightLabel
        : bout.weightClass.label;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: _bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Two portraits, edge to edge.
            Row(
              children: [
                Expanded(child: _portrait(red, alignRight: false)),
                Expanded(child: _portrait(blue, alignRight: true)),
              ],
            ),
            // Center seam aura.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      _brand.withValues(alpha: 0.34),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Container(width: 1.5, color: _brand.withValues(alpha: 0.5)),
            ),
            // Bottom scrim for the name stack.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99000000),
                      Color(0x00000000),
                      Color(0xE6000000),
                    ],
                    stops: [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
            // Top overline: event · date (baked, day-granular).
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (event.eventType.isEmpty ? event.name : event.eventType)
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: _brand,
                      ),
                    ),
                  ),
                  Text(
                    _dateLabel(event.date),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Name stack + meta.
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bout.isTitleFight || result != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        result ?? '$wl TITLE FIGHT'.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: result != null ? Colors.white : _gold,
                        ),
                      ),
                    ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: _last(red?.name ?? bout.redName)),
                          const TextSpan(
                            text: '  VS  ',
                            style: TextStyle(
                              fontSize: 22,
                              color: _brand,
                              shadows: [
                                Shadow(color: _brand, blurRadius: 18),
                              ],
                            ),
                          ),
                          TextSpan(text: _last(blue?.name ?? bout.blueName)),
                        ],
                      ),
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Anton',
                        fontSize: 40,
                        height: 1.05,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_cornerMeta(red, bout.redName)}     ·     '
                    '${_cornerMeta(blue, bout.blueName)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.72),
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

  Widget _portrait(Fighter? f, {required bool alignRight}) {
    if (f == null || f.imageUrl.isEmpty) {
      return const ColoredBox(color: Color(0xFF161618));
    }
    return Image.asset(
      f.imageUrl,
      fit: BoxFit.cover,
      alignment: Alignment(alignRight ? 0.2 : -0.2, -0.9),
      errorBuilder: (_, __, ___) =>
          const ColoredBox(color: Color(0xFF161618)),
    );
  }

  static String _last(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.last.toUpperCase();
  }

  static String _cornerMeta(Fighter? f, String fallback) {
    if (f == null) return _last(fallback);
    final rank = f.isChampion
        ? 'C'
        : f.rankingPosition != null
            ? '#${f.rankingPosition}'
            : '';
    return [f.record.display, if (rank.isNotEmpty) rank].join(' · ');
  }

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  static String _dateLabel(DateTime d) => '${_months[d.month - 1]} ${d.day}';
}
