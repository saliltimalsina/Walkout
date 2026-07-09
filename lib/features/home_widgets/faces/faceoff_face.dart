import 'package:flutter/material.dart';

import 'package:walkout/shared/models/models.dart';

import 'face_kit.dart';

/// The Face-Off home-screen widget face: two corners edge to edge, met by a
/// red aura seam — poster of the featured fight, tuned for a 4x2 cell.
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
              top: 10,
              left: 14,
              right: 14,
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
                        fontSize: 9.5,
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
                      fontSize: 9,
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
              left: 14,
              right: 14,
              bottom: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bout.isTitleFight || result != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        result ??
                            '${bout.weightClass.label} TITLE FIGHT'
                                .toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
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
                              fontSize: 15,
                              color: _brand,
                              shadows: [
                                Shadow(color: _brand, blurRadius: 14),
                              ],
                            ),
                          ),
                          TextSpan(text: _last(blue?.name ?? bout.blueName)),
                        ],
                      ),
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Anton',
                        fontSize: 26,
                        height: 1.05,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_cornerMeta(red, bout.redName)}     ·     '
                    '${_cornerMeta(blue, bout.blueName)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
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
    if (f == null || f.photo.isEmpty) {
      return const ColoredBox(color: Color(0xFF161618));
    }
    // Fade the inner edge into the dark bg with a gradient overlay instead of
    // a ShaderMask — no saveLayer, so the offscreen widget render is
    // paint-ready synchronously.
    return Stack(
      fit: StackFit.expand,
      children: [
        FaceKit.image(
          f.photo,
          fit: BoxFit.cover,
          alignment: Alignment(alignRight ? 0.2 : -0.2, -0.9),
          fallback: const ColoredBox(color: Color(0xFF161618)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignRight
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              end: alignRight ? Alignment.centerLeft : Alignment.centerRight,
              colors: const [Colors.transparent, _bg],
              stops: const [0.55, 1.0],
            ),
          ),
        ),
      ],
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
