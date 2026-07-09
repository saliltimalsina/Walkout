import 'package:flutter/widgets.dart';

import 'face_kit.dart';

// ── NEWS · LATEST STORIES (4x2) ──────────────────────────────────────

/// One story row: a thumbnail, a headline, and a relative time. Mirrors the
/// in-app "Latest Stories" section — derived from the featured event + the
/// champions, so it stays honest to the bundled data.
class NewsItem {
  const NewsItem({
    required this.image,
    required this.title,
    required this.time,
    this.source = 'WALKOUT',
  });
  final String image;
  final String title;
  final String time;
  final String source;
}

/// Headline list with right-hand thumbnails and a red source line, styled
/// after a premium sports-news widget. Fits three stories in a 4x2 cell.
class NewsFace extends StatelessWidget {
  const NewsFace({super.key, required this.items});
  final List<NewsItem> items;

  @override
  Widget build(BuildContext context) {
    final rows = items.take(3).toList();
    return Stack(
      children: [
        FaceKit.scaffold(
          auraAlpha: 0.16,
          auraCenter: const Alignment(-0.9, -0.9),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 3, height: 11, color: FaceKit.brand),
                  const SizedBox(width: 6),
                  Text('NEWS', style: FaceKit.over(9.5, FaceKit.brand)),
                ],
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < rows.length; i++) ...[
                Expanded(child: _row(rows[i])),
                if (i != rows.length - 1) FaceKit.rule(),
              ],
            ],
          ),
        ),
        // PRO ribbon, top-right.
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: FaceKit.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: FaceKit.gold.withValues(alpha: 0.6)),
            ),
            child: Text('PRO', style: FaceKit.over(7.5, FaceKit.gold, ls: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _row(NewsItem s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FaceKit.meta(10, FaceKit.white)
                          .copyWith(fontWeight: FontWeight.w700, height: 1.1)),
                ),
                const SizedBox(height: 3),
                Text('${s.source} · ${s.time}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FaceKit.meta(7.5, FaceKit.brand)
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              width: 60,
              height: double.infinity,
              child: s.image.isEmpty
                  ? const ColoredBox(color: FaceKit.bgDeep)
                  : FaceKit.image(s.image,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.3),
                      fallback: const ColoredBox(color: FaceKit.bgDeep)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── UPCOMING EVENTS (4x2) ────────────────────────────────────────────

class UpcomingItem {
  const UpcomingItem({
    required this.tag,
    required this.subtitle,
    required this.date,
    required this.daysAway,
  });
  final String tag; // "UFC 329" / "FIGHT NIGHT"
  final String subtitle; // "McGregor vs Holloway"
  final DateTime date;
  final int daysAway;
}

class UpcomingFace extends StatelessWidget {
  const UpcomingFace({super.key, required this.items});
  final List<UpcomingItem> items;

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final rows = items.take(3).toList();
    return FaceKit.scaffold(
      auraAlpha: 0.16,
      auraCenter: const Alignment(0.9, -0.9),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('UPCOMING', style: FaceKit.over(9, FaceKit.brand)),
              const SizedBox(width: 6),
              Text('· FIGHT CARDS', style: FaceKit.over(9, FaceKit.t3)),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final e in rows) _row(e)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(UpcomingItem e) {
    return Row(
      children: [
        // Date chip.
        SizedBox(
          width: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_months[e.date.month - 1],
                  style: FaceKit.over(8, FaceKit.brand, ls: 1)),
              Text('${e.date.day}', style: FaceKit.anton(18)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FaceKit.meta(10.5, FaceKit.white)
                      .copyWith(fontWeight: FontWeight.w800)),
              Text(e.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FaceKit.meta(8.5, FaceKit.t2)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(e.daysAway <= 0 ? 'NOW' : '${e.daysAway}D',
            style: FaceKit.over(9, e.daysAway <= 1 ? FaceKit.brand : FaceKit.t2)),
      ],
    );
  }
}

// ── FIGHT WEEK · SCHEDULE + TIMER (4x2) ──────────────────────────────

/// One fight-week beat with a derived timestamp. `real` marks the main card,
/// whose time comes straight from the event date; the rest are the standard
/// UFC cadence offset from it (labeled "typical" on the face).
class ScheduleSession {
  const ScheduleSession({
    required this.label,
    required this.time,
    required this.at,
  });
  final String label; // WEIGH-INS / PRELIMS / MAIN CARD
  final String time; // "9:00 PM"
  final DateTime at;
}

class FightWeekScheduleFace extends StatelessWidget {
  const FightWeekScheduleFace({
    super.key,
    required this.eventTag,
    required this.sessions,
    required this.now,
  });
  final String eventTag;
  final List<ScheduleSession> sessions;
  final DateTime now;

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    // First session still in the future is "next".
    final nextIdx = sessions.indexWhere((s) => s.at.isAfter(now));
    final next = nextIdx >= 0 ? sessions[nextIdx] : null;

    String countdown() {
      if (next == null) return 'CARD IN PROGRESS';
      final d = next.at.difference(now);
      final days = d.inDays;
      final hrs = d.inHours % 24;
      final mins = d.inMinutes % 60;
      if (days > 0) return '${next.label} · ${days}D ${hrs}H';
      if (hrs > 0) return '${next.label} · ${hrs}H ${mins}M';
      return '${next.label} · ${mins}M';
    }

    return FaceKit.scaffold(
      auraAlpha: 0.2,
      auraCenter: const Alignment(-0.9, -0.7),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('FIGHT WEEK', style: FaceKit.over(9, FaceKit.brand)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('· $eventTag',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FaceKit.over(9, FaceKit.t3)),
              ),
              Text('TYPICAL', style: FaceKit.over(6.5, FaceKit.t3)),
            ],
          ),
          const SizedBox(height: 3),
          // Next-up countdown line.
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: FaceKit.brand),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(countdown(), style: FaceKit.anton(17)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < sessions.length; i++)
                  _row(sessions[i], isNext: i == nextIdx, done: i < nextIdx),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ScheduleSession s, {required bool isNext, required bool done}) {
    final c = isNext
        ? FaceKit.white
        : done
            ? FaceKit.t3
            : FaceKit.t2;
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(_weekdays[s.at.weekday - 1],
              style: FaceKit.over(8, isNext ? FaceKit.brand : FaceKit.t3)),
        ),
        Expanded(
          child: Text(s.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FaceKit.meta(10.5, c).copyWith(
                  fontWeight: isNext ? FontWeight.w800 : FontWeight.w600)),
        ),
        Text(s.time, style: FaceKit.meta(9.5, c)),
      ],
    );
  }
}
