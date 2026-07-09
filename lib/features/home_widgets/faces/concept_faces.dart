import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:walkout/shared/models/models.dart';

import 'face_kit.dart';
import 'octagon_ring.dart';

/// The 15 concept faces from the widget board, all ≤ 4x2 cells.
/// 4x2 renders at 329x158 logical, 2x2 at 158x158 (3x pixel ratio).
/// Every number shown is real dataset data unless tagged `SIM`.

// ── helpers ──────────────────────────────────────────────────────────

int _hash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// Deterministic pseudo-percent for SIM-tagged community numbers.
int simPct(String seed, {int min = 35, int max = 92}) =>
    min + _hash(seed) % (max - min + 1);

String _shortDate(DateTime d) {
  const m = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  return '${m[d.month - 1]} ${d.day}';
}

String _eventTag(Event e) =>
    (e.eventType.isNotEmpty ? e.eventType : e.name).toUpperCase();

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// "SAT · JUN 15" — weekday + short date for the countdown face.
String _fightClockDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]} · ${_shortDate(d)}';

// ── 1 · FIGHT CLOCK (4x2) ────────────────────────────────────────────

class FightClockFace extends StatelessWidget {
  const FightClockFace({
    super.key,
    required this.event,
    required this.now,
    this.red,
    this.blue,
  });
  final Event event;
  final DateTime now;

  /// Main-event corners. When both are present the face renders as a poster
  /// with two fighter cutouts + a big `RED VS BLUE`; otherwise it degrades to
  /// the event subtitle so fallback usages keep working.
  final Fighter? red;
  final Fighter? blue;

  @override
  Widget build(BuildContext context) {
    final diff = event.date.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    final fightWeek = !diff.isNegative && diff.inDays <= 7;
    final hasPortraits = (red?.photo.isNotEmpty ?? false) &&
        (blue?.photo.isNotEmpty ?? false);

    final title = hasPortraits
        ? '${FaceKit.lastName(red!.name)}  VS  ${FaceKit.lastName(blue!.name)}'
        : event.subtitle.toUpperCase();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [FaceKit.bg, FaceKit.bgDeep],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPortraits) ...[
              FaceKit.sideCutout(red!.photo,
                  right: false,
                  width: 92,
                  imageAlign: const Alignment(-0.1, -0.85)),
              FaceKit.sideCutout(blue!.photo,
                  right: true,
                  width: 92,
                  imageAlign: const Alignment(0.1, -0.85)),
            ],
            // Center readability wash.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [Color(0xE6000000), Color(0x66000000)],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(_eventTag(event),
                      style: FaceKit.over(9, FaceKit.brand)),
                  if (hasPortraits)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: FaceKit.dualName(
                          FaceKit.lastName(red!.name),
                          FaceKit.lastName(blue!.name),
                          size: 27),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(title,
                          textAlign: TextAlign.center,
                          style: FaceKit.anton(27)),
                    ),
                  // Countdown strip.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _unit('${days < 0 ? 0 : days}', days == 1 ? 'DAY' : 'DAYS'),
                      const SizedBox(width: 22),
                      _unit('$hours', 'HRS'),
                      const SizedBox(width: 22),
                      _unit('$mins', 'MINS'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (fightWeek) ...[
                        FaceKit.pill('FIGHT WEEK', fontSize: 7),
                        const SizedBox(width: 7),
                      ],
                      Flexible(
                        child: Text(
                          _fightClockDate(event.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FaceKit.meta(8.5, FaceKit.t2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unit(String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: FaceKit.anton(30)),
          Text(label, style: FaceKit.over(7.5, FaceKit.brand, ls: 1.2)),
        ],
      );
}

// ── 2 · YOUR CORNER (4x2) ────────────────────────────────────────────

class CornerEntry {
  const CornerEntry({required this.fighter, required this.sub});
  final Fighter fighter;
  final String sub; // e.g. "UFC 330" or record
}

class CornerFace extends StatelessWidget {
  const CornerFace({super.key, required this.entries, this.title = 'YOUR CORNER'});
  final List<CornerEntry> entries;
  final String title;

  @override
  Widget build(BuildContext context) {
    return FaceKit.scaffold(
      auraAlpha: 0.22,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 10, color: FaceKit.brand),
              const SizedBox(width: 6),
              Text(title, style: FaceKit.over(9, FaceKit.t2)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                for (final e in entries.take(4)) ...[
                  Expanded(child: _tile(e)),
                  if (e != entries.take(4).last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(CornerEntry e) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FaceKit.line),
              color: FaceKit.bgDeep,
            ),
            child: e.fighter.photo.isEmpty
                ? Center(
                    child: Text(FaceKit.lastName(e.fighter.name)[0],
                        style: FaceKit.anton(22, c: FaceKit.t3)))
                : FaceKit.image(e.fighter.photo,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    fallback: Center(
                        child: Text(FaceKit.lastName(e.fighter.name)[0],
                            style: FaceKit.anton(22, c: FaceKit.t3)))),
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(FaceKit.lastName(e.fighter.name),
              style: FaceKit.over(9, FaceKit.white, ls: 0.8)),
        ),
        const SizedBox(height: 1),
        Text(e.sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FaceKit.meta(7, FaceKit.t3)),
      ],
    );
  }
}

// ── 3 · OCTAGON COUNTDOWN (2x2) ──────────────────────────────────────

class OctagonCountFace extends StatelessWidget {
  const OctagonCountFace({super.key, required this.event, required this.now});
  final Event event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final days = event.date.difference(now).inDays;
    // Ring walks in over a 45-day promotion window.
    final p = (1 - days / 45).clamp(0.04, 1.0).toDouble();
    return FaceKit.scaffold(
      auraCenter: Alignment.center,
      auraAlpha: 0.2,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OctagonRing(
            progress: p,
            size: 98,
            fill: FaceKit.brand,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$days', style: FaceKit.anton(32)),
                Text(days == 1 ? 'DAY' : 'DAYS',
                    style: FaceKit.over(8, FaceKit.t2)),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(_eventTag(event), style: FaceKit.over(8.5, FaceKit.brand)),
        ],
      ),
    );
  }
}

// ── 5 · LAST 5 (2x2) ─────────────────────────────────────────────────

class Last5Face extends StatelessWidget {
  const Last5Face({super.key, required this.fighter, required this.results});
  final Fighter fighter;
  /// Most recent first: 'W' | 'L' | 'D'; may be shorter than 5.
  final List<String> results;

  static const _c = {
    'W': FaceKit.green,
    'L': FaceKit.brand,
    'D': FaceKit.gold,
  };

  @override
  Widget build(BuildContext context) {
    final slots = [...results.take(5)];
    while (slots.length < 5) {
      slots.add('');
    }
    return FaceKit.scaffold(
      padding: const EdgeInsets.all(12),
      auraAlpha: 0.18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('LAST 5', style: FaceKit.over(8, FaceKit.t3)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(FaceKit.lastName(fighter.name),
                style: FaceKit.anton(22)),
          ),
          const Spacer(),
          Row(
            children: [
              for (final r in slots) ...[
                Expanded(child: _badge(r)),
                if (r != slots.last) const SizedBox(width: 6),
              ],
            ],
          ),
          const Spacer(),
          FaceKit.rule(),
          const SizedBox(height: 9),
          Row(
            children: [
              _finish('KO', fighter.winsByKo, FaceKit.brand),
              _finish('SUB', fighter.winsBySub, FaceKit.gold),
              _finish('DEC', fighter.winsByDec, FaceKit.t2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String r) {
    final filled = r.isNotEmpty;
    final c = _c[r] ?? FaceKit.t3;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? c : const Color(0x0DFFFFFF),
          border: Border.all(
            color: filled ? c : FaceKit.line,
            width: 1,
          ),
          boxShadow: filled
              ? [BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 7)]
              : null,
        ),
        child: Text(r,
            style: FaceKit.over(
                11, filled ? FaceKit.white : FaceKit.t3,
                ls: 0)),
      ),
    );
  }

  Widget _finish(String label, int n, Color c) => Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: c)),
                const SizedBox(width: 4),
                Text('$n', style: FaceKit.anton(15)),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: FaceKit.over(7, FaceKit.t3, ls: 1)),
          ],
        ),
      );
}

// ── 6 · TALE OF THE TAPE (4x2) ───────────────────────────────────────

class TapeFace extends StatelessWidget {
  const TapeFace({super.key, required this.red, required this.blue});
  final Fighter red;
  final Fighter blue;

  @override
  Widget build(BuildContext context) {
    String cm(int v) => v == 0 ? '—' : '$v CM';
    String age(int v) => v == 0 ? '—' : '$v';
    final rows = <(String, String, String)>[
      (cm(red.heightCm), 'HEIGHT', cm(blue.heightCm)),
      (cm(red.reachCm), 'REACH', cm(blue.reachCm)),
      (age(red.age), 'AGE', age(blue.age)),
      (red.stance.toUpperCase(), 'STANCE', blue.stance.toUpperCase()),
    ];
    return FaceKit.scaffold(
      auraCenter: Alignment.topCenter,
      auraAlpha: 0.2,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          // Head band: two photo heads with names + a glowing VS between.
          Expanded(
            flex: 46,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _head(red)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(child: FaceKit.glowVs(15)),
                ),
                Expanded(child: _head(blue)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FaceKit.rule(),
          const SizedBox(height: 2),
          Expanded(
            flex: 54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (l, label, r) in rows)
                  Row(
                    children: [
                      Expanded(
                        child: Text(l,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FaceKit.meta(10, FaceKit.white)),
                      ),
                      Text(label, style: FaceKit.over(7.5, FaceKit.t3)),
                      Expanded(
                        child: Text(r,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FaceKit.meta(10, FaceKit.white)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _head(Fighter f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: FaceKit.line),
              color: FaceKit.bgDeep,
            ),
            child: f.photo.isEmpty
                ? Center(
                    child: Text(FaceKit.lastName(f.name)[0],
                        style: FaceKit.anton(20, c: FaceKit.t3)))
                : FaceKit.image(f.photo,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.7),
                    fallback: Center(
                        child: Text(FaceKit.lastName(f.name)[0],
                            style: FaceKit.anton(20, c: FaceKit.t3)))),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(FaceKit.lastName(f.name),
              style: FaceKit.over(9, FaceKit.white, ls: 0.6)),
        ),
      ],
    );
  }
}

// ── 7 · THE BELT (2x2) ───────────────────────────────────────────────

class BeltsFace extends StatelessWidget {
  const BeltsFace({super.key, required this.champ});
  final Fighter champ;

  @override
  Widget build(BuildContext context) {
    return FaceKit.scaffold(
      aura: FaceKit.gold,
      auraCenter: const Alignment(0.9, 0.9),
      auraAlpha: 0.26,
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (champ.photo.isNotEmpty)
            Positioned(
              right: -18,
              top: 4,
              bottom: 0,
              child: FaceKit.portrait(champ.photo,
                  width: 100, fadeLeft: true),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaceKit.pill('CHAMPION', c: FaceKit.gold),
                const Spacer(),
                Text(champ.weightClass.label.toUpperCase(),
                    style: FaceKit.over(7.5, FaceKit.t2)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(FaceKit.lastName(champ.name),
                      style: FaceKit.anton(24)),
                ),
                const SizedBox(height: 3),
                Text(champ.record.display,
                    style: FaceKit.meta(8.5, FaceKit.t2)),
                const SizedBox(height: 8),
                // Belt strap.
                SizedBox(
                  height: 16,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 7,
                        width: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(colors: [
                            Color(0xFF8A6D1B),
                            FaceKit.gold,
                            Color(0xFF8A6D1B),
                          ]),
                        ),
                      ),
                      for (final x in const [16.0, 62.0])
                        Positioned(
                          left: x,
                          child: Container(
                            width: 8,
                            height: 11,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 38,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFD4AF37),
                            border: Border.all(
                                color: const Color(0xFF6E5514), width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF6E5514),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 8 · MOMENTUM (2x2) ───────────────────────────────────────────────

class MomentumFace extends StatelessWidget {
  const MomentumFace(
      {super.key, required this.fighter, required this.streak});
  final Fighter fighter;
  /// Consecutive wins derived from dataset history (>=0).
  final int streak;

  @override
  Widget build(BuildContext context) {
    final hot = streak >= 2;
    return FaceKit.scaffold(
      padding: const EdgeInsets.all(12),
      auraCenter: const Alignment(0.8, 0.9),
      auraAlpha: hot ? 0.3 : 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MOMENTUM', style: FaceKit.over(8, FaceKit.t3)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(FaceKit.lastName(fighter.name),
                style: FaceKit.anton(18)),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$streak', style: FaceKit.anton(44, c: FaceKit.white)),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text('WIN\nSTREAK',
                    style: FaceKit.over(8, FaceKit.brand, ls: 1.4)),
              ),
              const Spacer(),
              // Rising bars.
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 7,
                    height: 10.0 + i * 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < streak.clamp(0, 4)
                          ? FaceKit.brand
                              .withValues(alpha: 0.45 + i * 0.18)
                          : const Color(0x14FFFFFF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('PRO ${fighter.record.display}',
              style: FaceKit.meta(8, FaceKit.t2)),
        ],
      ),
    );
  }
}

// ── 9 · DIVISION LADDER (4x2) ────────────────────────────────────────

class LadderRow {
  const LadderRow(
      {required this.rank, required this.name, required this.change});
  final String rank; // 'C', '1'...
  final String name;
  final int change;
}

class LadderFace extends StatelessWidget {
  const LadderFace({super.key, required this.division, required this.rows});
  final String division;
  final List<LadderRow> rows;

  @override
  Widget build(BuildContext context) {
    return FaceKit.scaffold(
      auraAlpha: 0.18,
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(division.toUpperCase(),
                  style: FaceKit.over(9, FaceKit.brand)),
              const SizedBox(width: 6),
              Text('· LADDER', style: FaceKit.over(9, FaceKit.t3)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final r in rows.take(5)) _row(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(LadderRow r) {
    final isChamp = r.rank == 'C';
    final (arrow, ac) = r.change > 0
        ? ('▲${r.change}', FaceKit.green)
        : r.change < 0
            ? ('▼${-r.change}', FaceKit.brand)
            : ('—', FaceKit.t3);
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(isChamp ? 'C' : '#${r.rank}',
              style: FaceKit.anton(12,
                  c: isChamp ? FaceKit.gold : FaceKit.t2)),
        ),
        Expanded(
          child: Text(r.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FaceKit.meta(10.5,
                  isChamp ? FaceKit.gold : FaceKit.white)),
        ),
        Text(isChamp ? 'CHAMP' : arrow,
            style: FaceKit.over(7.5, isChamp ? FaceKit.gold : ac, ls: 1)),
      ],
    );
  }
}

// ── 10 · WALKOUT CARD / TICKET (2x2) ─────────────────────────────────

class TicketFace extends StatelessWidget {
  const TicketFace({super.key, required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final seed = _hash(event.id);
    return FaceKit.scaffold(
      auraAlpha: 0.2,
      auraCenter: const Alignment(-0.8, -0.8),
      padding: const EdgeInsets.all(10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FaceKit.line),
          color: const Color(0x0AFFFFFF),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WALKOUT · ADMIT ONE',
                        style: FaceKit.over(6.5, FaceKit.brand, ls: 1.5)),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_eventTag(event),
                          style: FaceKit.anton(20)),
                    ),
                    const SizedBox(height: 2),
                    Text(event.subtitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FaceKit.meta(7.5, FaceKit.t2)),
                    const SizedBox(height: 2),
                    Text(
                        '${_shortDate(event.date)} · SEC OCT · ROW A',
                        style: FaceKit.meta(7, FaceKit.t3)),
                  ],
                ),
              ),
            ),
            // Perforation.
            Row(
              children: [
                for (var i = 0; i < 16; i++)
                  Expanded(
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      color: i.isEven ? FaceKit.line : const Color(0x00000000),
                    ),
                  ),
              ],
            ),
            // Barcode.
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Row(
                children: [
                  for (var i = 0; i < 24; i++)
                    Container(
                      width: ((seed >> i) & 1) == 1 ? 2.4 : 1.2,
                      height: 16,
                      margin: const EdgeInsets.only(right: 2.6),
                      color: const Color(0xCCFFFFFF),
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

// ── 11 · HYPE PULSE (2x2, SIM) ───────────────────────────────────────

class HypeFace extends StatelessWidget {
  const HypeFace({super.key, required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final pct = simPct('hype_${event.id}', min: 62, max: 97);
    final seed = _hash('wave_${event.id}');
    return FaceKit.scaffold(
      padding: const EdgeInsets.all(12),
      auraCenter: Alignment.bottomCenter,
      auraAlpha: 0.28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaceKit.pill('COMMUNITY · SIM', fontSize: 6.5),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$pct', style: FaceKit.anton(42)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Text('%', style: FaceKit.anton(18, c: FaceKit.brand)),
              ),
            ],
          ),
          Text('HYPE PULSE', style: FaceKit.over(8, FaceKit.t2)),
          const SizedBox(height: 8),
          SizedBox(
            height: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 14; i++)
                  Expanded(
                    child: Container(
                      height: 5.0 + ((seed >> (i * 2)) & 15),
                      margin: const EdgeInsets.only(right: 2.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5),
                        color: FaceKit.brand
                            .withValues(alpha: 0.35 + (i / 14) * 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(_eventTag(event), style: FaceKit.over(7.5, FaceKit.t3)),
        ],
      ),
    );
  }
}

// ── 12 · FINISH DNA (2x2) ────────────────────────────────────────────

class FinishDnaFace extends StatelessWidget {
  const FinishDnaFace({super.key, required this.fighter});
  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final ko = fighter.winsByKo;
    final sub = fighter.winsBySub;
    final dec = fighter.winsByDec;
    final total = math.max(1, ko + sub + dec);
    return FaceKit.scaffold(
      padding: const EdgeInsets.all(12),
      auraAlpha: 0.18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FINISH DNA', style: FaceKit.over(8, FaceKit.t3)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(FaceKit.lastName(fighter.name),
                style: FaceKit.anton(18)),
          ),
          const Spacer(),
          Row(
            children: [
              CustomPaint(
                size: const Size(58, 58),
                painter: _DonutPainter(ko / total, sub / total, dec / total),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _leg(FaceKit.brand, 'KO/TKO', ko),
                    const SizedBox(height: 4),
                    _leg(FaceKit.gold, 'SUB', sub),
                    const SizedBox(height: 4),
                    _leg(const Color(0xFF8E8E96), 'DEC', dec),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _leg(Color c, String label, int n) => Row(
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
          const SizedBox(width: 5),
          Text(label, style: FaceKit.over(7.5, FaceKit.t2, ls: 0.8)),
          const Spacer(),
          Text('$n', style: FaceKit.meta(9, FaceKit.white)),
        ],
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.ko, this.sub, this.dec);
  final double ko, sub, dec;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.butt;
    var start = -math.pi / 2;
    for (final (frac, color) in [
      (ko, FaceKit.brand),
      (sub, FaceKit.gold),
      (dec, const Color(0xFF8E8E96)),
    ]) {
      if (frac <= 0) continue;
      final sweep = frac * 2 * math.pi;
      canvas.drawArc(rect, start, sweep - 0.06, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.ko != ko || old.sub != sub || old.dec != dec;
}

// ── 13 · OCTAGON RADAR (2x2) ─────────────────────────────────────────

class RadarFace extends StatelessWidget {
  const RadarFace({super.key, required this.fighter});
  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final s = fighter.stats;
    // Normalised 0..1 against strong-elite ceilings.
    final axes = <(String, double)>[
      ('STR', (s.sigStrikesPerMin / 7).clamp(0.08, 1.0)),
      ('ACC', (s.strikingAccuracy / 65).clamp(0.08, 1.0)),
      ('DEF', (s.strikingDefense / 70).clamp(0.08, 1.0)),
      ('TDN', (s.takedownAvg / 5).clamp(0.08, 1.0)),
      ('SUB', (s.submissionAvg / 2.5).clamp(0.08, 1.0)),
    ];
    return FaceKit.scaffold(
      padding: const EdgeInsets.all(11),
      auraCenter: Alignment.center,
      auraAlpha: 0.16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(FaceKit.lastName(fighter.name),
                      style: FaceKit.anton(15)),
                ),
              ),
              Text('RADAR', style: FaceKit.over(7, FaceKit.t3)),
            ],
          ),
          Expanded(
            child: Center(
              child: CustomPaint(
                size: const Size(104, 104),
                painter: _RadarPainter(axes),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.axes);
  final List<(String, double)> axes;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rMax = size.shortestSide / 2 - 12;
    final n = axes.length;
    Offset pt(int i, double r) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      return c + Offset(math.cos(a), math.sin(a)) * r;
    }

    // Grid rings.
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = FaceKit.line;
    for (final f in [0.33, 0.66, 1.0]) {
      final path = Path()..moveTo(pt(0, rMax * f).dx, pt(0, rMax * f).dy);
      for (var i = 1; i <= n; i++) {
        final p = pt(i % n, rMax * f);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, pt(i, rMax), grid);
    }

    // Data polygon.
    final poly = Path()
      ..moveTo(pt(0, rMax * axes[0].$2).dx, pt(0, rMax * axes[0].$2).dy);
    for (var i = 1; i <= n; i++) {
      final p = pt(i % n, rMax * axes[i % n].$2);
      poly.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        poly,
        Paint()
          ..style = PaintingStyle.fill
          ..color = FaceKit.brand.withValues(alpha: 0.3));
    canvas.drawPath(
        poly,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = FaceKit.brand);

    // Labels.
    for (var i = 0; i < n; i++) {
      final p = pt(i, rMax + 8);
      final tp = TextPainter(
        text: TextSpan(text: axes[i].$1, style: FaceKit.over(6.5, FaceKit.t3)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.axes != axes;
}

// ── 14 · THE JOURNEY (4x2) ───────────────────────────────────────────

class JourneyFace extends StatelessWidget {
  const JourneyFace({super.key, required this.fighter});
  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final ranked = fighter.isChampion || fighter.rankingPosition != null;
    final steps = <(String, String, bool, bool)>[
      // label, sub, achieved, gold
      ('PRO DEBUT', '${fighter.record.totalFights} FIGHTS', true, false),
      ('CONTENDER', ranked ? 'RANKED ${fighter.rankLabel}' : 'UNRANKED',
          ranked, false),
      (
        fighter.isChampion ? 'CHAMPION' : 'THE BELT',
        fighter.isChampion
            ? fighter.weightClass.label.toUpperCase()
            : 'NEXT CHAPTER',
        fighter.isChampion,
        true
      ),
    ];
    return FaceKit.scaffold(
      aura: fighter.isChampion ? FaceKit.gold : FaceKit.brand,
      auraCenter: const Alignment(0.9, -0.7),
      auraAlpha: 0.24,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE JOURNEY', style: FaceKit.over(8, FaceKit.t3)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(fighter.name.toUpperCase(),
                style: FaceKit.anton(22)),
          ),
          const Spacer(),
          // Timeline.
          SizedBox(
            height: 14,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 2, color: FaceKit.line),
                Row(
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      _node(steps[i]),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: steps[i + 1].$3
                                ? (steps[i + 1].$4
                                    ? FaceKit.gold
                                    : FaceKit.brand)
                                : const Color(0x00000000),
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                _label(steps[i],
                    i == 0
                        ? CrossAxisAlignment.start
                        : i == steps.length - 1
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.center),
                if (i < steps.length - 1) const Spacer(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _node((String, String, bool, bool) s) {
    final color = s.$4 ? FaceKit.gold : FaceKit.brand;
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: s.$3 ? color : FaceKit.bgDeep,
        border: Border.all(color: s.$3 ? color : FaceKit.t3, width: 1.5),
        boxShadow: s.$3
            ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)]
            : null,
      ),
    );
  }

  Widget _label((String, String, bool, bool) s, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(s.$1,
            style: FaceKit.over(
                7.5, s.$3 ? (s.$4 ? FaceKit.gold : FaceKit.white) : FaceKit.t3,
                ls: 1)),
        const SizedBox(height: 1),
        Text(s.$2, style: FaceKit.meta(6.5, FaceKit.t3)),
      ],
    );
  }
}

// ── 15 · PREDICTION (4x2, SIM) ───────────────────────────────────────

class PredictionFace extends StatelessWidget {
  const PredictionFace({
    super.key,
    required this.event,
    required this.redName,
    required this.blueName,
  });
  final Event event;
  final String redName;
  final String blueName;

  @override
  Widget build(BuildContext context) {
    final redPct = simPct('pick_${event.id}_$redName', min: 38, max: 72);
    return FaceKit.scaffold(
      auraCenter: Alignment.bottomLeft,
      auraAlpha: 0.22,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_eventTag(event), style: FaceKit.over(8.5, FaceKit.t2)),
              const Spacer(),
              FaceKit.pill('COMMUNITY · SIM', fontSize: 6.5),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(FaceKit.lastName(redName),
                      style: FaceKit.anton(21)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: FaceKit.glowVs(12),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(FaceKit.lastName(blueName),
                      style: FaceKit.anton(21)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('$redPct%', style: FaceKit.over(9, FaceKit.brand)),
              const Spacer(),
              Text('${100 - redPct}%', style: FaceKit.over(9, FaceKit.t2)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: redPct,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                          FaceKit.brand,
                          Color(0xFFFF3B45),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 100 - redPct,
                    child: Container(color: const Color(0x2EFFFFFF)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('TAP TO LOCK YOUR PICK →',
              style: FaceKit.over(7.5, FaceKit.t3)),
        ],
      ),
    );
  }
}
