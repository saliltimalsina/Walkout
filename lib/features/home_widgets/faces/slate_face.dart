import 'package:flutter/widgets.dart';

import 'face_kit.dart';
import 'feed_faces.dart';
import 'octagon_ring.dart';

// ── WEEKEND SLATE · FIGHT-WEEK ITINERARY (4x2) ───────────────────────

/// Grand-Prix-poster take on fight week: the LEFT third is a poster block —
/// the event tag stacked as two Anton wordmark lines (bright gold over dull
/// gold, the lower line nudged right and overlapping up like a drop layer)
/// with a low-alpha octagon watermark bleeding off the card edge, then the
/// matchup and a main-card meta line. The RIGHT side is the five-session
/// weekend itinerary; the next upcoming session carries the brand accent,
/// past sessions dim out.
class SlateFace extends StatelessWidget {
  const SlateFace({
    super.key,
    required this.eventTag,
    required this.subtitle,
    required this.sessions,
    required this.now,
  });

  final String eventTag; // 'UFC 330' / 'UFC FIGHT NIGHT'
  final String subtitle; // 'Makhachev vs Garry'
  final List<ScheduleSession> sessions; // 5, chronological
  final DateTime now;

  /// Hand-tuned dark gold for the wordmark's drop layer.
  static const _dullGold = Color(0xFF8A7010);

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  /// 'UFC 330' → ('UFC', '330'); 'UFC FIGHT NIGHT' → ('FIGHT', 'NIGHT').
  (String, String) _tagLines() {
    final parts = eventTag.trim().toUpperCase().split(RegExp(r'\s+'));
    if (parts.length < 2) return (parts.first, '');
    if (parts.length >= 3 && parts.first == 'UFC') {
      return (parts[1], parts.sublist(2).join(' '));
    }
    return (parts.first, parts.sublist(1).join(' '));
  }

  @override
  Widget build(BuildContext context) {
    final nextIdx = sessions.indexWhere((s) => s.at.isAfter(now));

    return FaceKit.scaffold(
      aura: FaceKit.gold,
      auraAlpha: 0.14,
      auraCenter: const Alignment(-0.9, -0.6),
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Octagon watermark bleeding off the left edge, like the F1
          // circuit outline behind the GP wordmark.
          Positioned(
            left: -44,
            top: 4,
            child: OctagonRing(
              progress: 1,
              size: 118,
              track: FaceKit.gold.withValues(alpha: 0.10),
              fill: FaceKit.gold.withValues(alpha: 0.17),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 116, child: _poster()),
                const SizedBox(width: 14),
                Expanded(child: _itinerary(nextIdx)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Poster block: stacked wordmark + matchup + main-card meta.
  Widget _poster() {
    final (top, bottom) = _tagLines();
    final main = sessions.isNotEmpty ? sessions.last : null;
    final meta = main == null
        ? ''
        : '${main.label} · ${_months[main.at.month - 1]} ${main.at.day}'
            ' · ${main.time}';

    Widget line(String text, Color c) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, maxLines: 1, style: FaceKit.anton(37, c: c)),
        );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(top, FaceKit.gold),
        if (bottom.isNotEmpty)
          Transform.translate(
            offset: const Offset(16, -10),
            child: line(bottom, _dullGold),
          ),
        Text(subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FaceKit.meta(9, FaceKit.white)
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(meta,
              maxLines: 1, style: FaceKit.meta(7, FaceKit.t3)),
        ),
      ],
    );
  }

  // Five-row session itinerary.
  Widget _itinerary(int nextIdx) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sessions.length; i++)
          _row(
            sessions[i],
            isNext: i == nextIdx,
            done: nextIdx == -1 || i < nextIdx,
          ),
      ],
    );
  }

  Widget _row(ScheduleSession s, {required bool isNext, required bool done}) {
    final dayC = isNext
        ? FaceKit.brand
        : done
            ? FaceKit.t3
            : FaceKit.white;
    final wkC = isNext ? FaceKit.brand.withValues(alpha: 0.85) : FaceKit.t3;
    final labelC = isNext
        ? FaceKit.white
        : done
            ? FaceKit.t3
            : FaceKit.t2;
    final timeC = isNext
        ? FaceKit.t2
        : done
            ? FaceKit.t3.withValues(alpha: 0.75)
            : FaceKit.t3;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Mini date column: day-of-month over weekday abbreviation.
        SizedBox(
          width: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.at.day}', style: FaceKit.anton(13, c: dayC)),
              Text(_weekdays[s.at.weekday - 1],
                  style: FaceKit.over(6, wkC, ls: 1)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FaceKit.meta(8.5, labelC).copyWith(
                    fontWeight: isNext ? FontWeight.w800 : FontWeight.w700,
                    letterSpacing: 0.6,
                  )),
              const SizedBox(height: 1),
              Text(s.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FaceKit.meta(7.5, timeC)),
            ],
          ),
        ),
      ],
    );
  }
}
