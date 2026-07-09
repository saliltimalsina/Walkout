import 'package:flutter/widgets.dart';

import 'package:walkout/shared/models/models.dart';

import '../application/living_state.dart';
import 'octagon_ring.dart';

/// The Living Widget's 4x2 face — renders every [LivingState] with one
/// adaptive composition. Rendered offscreen to PNG; countdown DIGITS inside
/// the final 24h are drawn natively (chronometer) over the bottom-right, so
/// those states leave that corner clear.
class LivingFace extends StatelessWidget {
  const LivingFace({super.key, required this.snapshot, required this.now});

  final LivingSnapshot snapshot;
  final DateTime now;

  static const _bg = Color(0xFF121214);
  static const _bgDeep = Color(0xFF08080A);
  static const _brand = Color(0xFFE50914);
  static const _gold = Color(0xFFFACC15);
  static const _green = Color(0xFF22C55E);
  static const _t2 = Color(0xFFA6A6AD);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg, _bgDeep],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.5),
                    radius: 1.2,
                    colors: [
                      _aura().withValues(alpha: 0.34),
                      const Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _body(),
            ),
          ],
        ),
      ),
    );
  }

  Color _aura() => switch (snapshot.state) {
        LivingState.result when snapshot.won == true => _gold,
        LivingState.aftermath => _gold,
        _ => _brand,
      };

  Widget _body() => switch (snapshot.state) {
        LivingState.empty => _empty(),
        LivingState.corner => _corner(),
        LivingState.booked => _booked(),
        LivingState.fightWeek || LivingState.weighInDay => _fightWeek(),
        LivingState.fightNight => _fightNight(),
        LivingState.result => _result(),
        LivingState.aftermath => _aftermath(),
      };

  // ── type ──
  TextStyle _anton(double s, {Color c = const Color(0xFFFFFFFF)}) => TextStyle(
        fontFamily: 'Anton',
        fontSize: s,
        color: c,
        height: 1.0,
        letterSpacing: 0.5,
      );
  TextStyle _over(double s, Color c, {double ls = 2}) => TextStyle(
        fontFamily: 'Inter',
        fontSize: s,
        fontWeight: FontWeight.w800,
        letterSpacing: ls,
        color: c,
      );
  TextStyle _meta(double s, Color c) => TextStyle(
        fontFamily: 'Inter',
        fontSize: s,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: c,
      );

  static String _last(String? n) {
    if (n == null || n.isEmpty) return '';
    return n.trim().split(RegExp(r'\s+')).last.toUpperCase();
  }

  Widget _glowVs(double size) => Text(
        'VS',
        style: TextStyle(
          fontFamily: 'Anton',
          fontSize: size,
          color: _brand,
          shadows: const [
            Shadow(color: _brand, blurRadius: 16),
            Shadow(color: Color(0x80E50914), blurRadius: 32),
          ],
        ),
      );

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  String _date(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  int _days(DateTime d) => d.difference(now).inDays;

  /// A right-anchored portrait that fades into the bg via a gradient overlay.
  Widget _portrait(Fighter? f, {double widthFactor = 0.44, bool left = false}) {
    if (f == null || f.imageUrl.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        heightFactor: 1.35,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              f.imageUrl,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.72),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: left ? Alignment.centerLeft : Alignment.centerRight,
                  end: left ? Alignment.centerRight : Alignment.centerLeft,
                  colors: const [Color(0x00000000), _bgDeep],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── faces ──

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('WALKOUT', style: _anton(28, c: _brand)),
            const SizedBox(height: 8),
            Text('BUILD YOUR CORNER', style: _over(11, _t2)),
          ],
        ),
      );

  Widget _corner() {
    final f = snapshot.fighter!;
    final next = snapshot.event;
    return Stack(
      children: [
        _portrait(f),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (f.isChampion) ...[
                Text('CHAMPION', style: _over(10, _gold, ls: 2.5)),
              ] else
                Text(
                  f.rankingPosition != null
                      ? '#${f.rankingPosition}  ${f.weightClass.label.toUpperCase()}'
                      : f.weightClass.label.toUpperCase(),
                  style: _over(10, _brand, ls: 2),
                ),
            ]),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(f.name.toUpperCase(), maxLines: 1, style: _anton(34)),
            ),
            const SizedBox(height: 8),
            Text(
              next != null
                  ? 'NEXT · ${(next.eventType.isEmpty ? next.name : next.eventType).toUpperCase()} · ${_date(next.date)}'
                  : f.record.display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _meta(12, _t2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _booked() {
    final e = snapshot.event!;
    final d = _days(e.date);
    return Stack(
      children: [
        _portrait(snapshot.fighter, widthFactor: 0.34, left: true),
        _portrait(snapshot.opponent, widthFactor: 0.34),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (e.eventType.isEmpty ? e.name : e.eventType).toUpperCase(),
              style: _over(10, _brand, ls: 2.5),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_last(snapshot.fighter?.name), style: _anton(26)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _glowVs(15),
                  ),
                  Text(_last(snapshot.opponent?.name), style: _anton(26)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _pill('${_date(e.date)}  ·  ${d <= 0 ? "TODAY" : "$d DAYS"}', _t2),
          ],
        ),
      ],
    );
  }

  Widget _fightWeek() {
    final e = snapshot.event!;
    final sched = PhaseSchedule(e.date);
    final total = e.date.difference(sched.fightWeekStart).inMinutes;
    final gone = now.difference(sched.fightWeekStart).inMinutes;
    final pct = ringProgress(total <= 0 ? 0 : gone / total);
    final d = _days(e.date);

    return Row(
      children: [
        OctagonRing(
          progress: pct,
          size: 108,
          fill: _brand,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(d <= 0 ? '0' : '$d', style: _anton(34)),
              Text(d == 1 ? 'DAY' : 'DAYS', style: _over(9, _t2, ls: 2)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.state == LivingState.weighInDay
                    ? 'WEIGH-IN DAY'
                    : 'FIGHT WEEK',
                style: _over(10, _brand, ls: 2.5),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_last(snapshot.fighter?.name)} VS ${_last(snapshot.opponent?.name)}',
                  maxLines: 1,
                  style: _anton(22),
                ),
              ),
              const SizedBox(height: 8),
              _pill('TODAY · ${snapshot.phase?.label ?? ""}', _t2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fightNight() {
    final e = snapshot.event!;
    final order = [...e.mainCard];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [
          _dot(_brand),
          const SizedBox(width: 6),
          Text('LIVE · CARD IN PROGRESS', style: _over(10, _brand, ls: 2)),
        ]),
        const SizedBox(height: 8),
        for (final b in order.take(2).toList().reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_last(b.redName)} VS ${_last(b.blueName)}',
                      style: _anton(18)),
                  if (b.isMainEvent)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('MAIN', style: _over(9, _gold, ls: 1.5)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _result() {
    final won = snapshot.won == true;
    final f = snapshot.fighter!;
    final b = snapshot.bout!;
    return Stack(
      children: [
        _portrait(f),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              color: won ? _green : _brand,
              child: Text(won ? 'WIN' : 'LOSS',
                  style: _over(11, const Color(0xFF0A0A0A), ls: 1.5)),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_last(f.name), maxLines: 1, style: _anton(30)),
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (b.method.isNotEmpty) b.method.toUpperCase(),
                if (b.finishRound.isNotEmpty) b.finishRound,
              ].join(' · '),
              style: _over(10, won ? _green : _t2, ls: 1.5),
            ),
            const SizedBox(height: 3),
            Text(
              'NOW ${f.record.display}${f.isChampion ? "  ·  STILL CHAMPION" : ""}',
              style: _meta(12, _t2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _aftermath() {
    final f = snapshot.fighter!;
    return Stack(
      children: [
        _portrait(f),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THE DAY AFTER', style: _over(10, _gold, ls: 2.5)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_last(f.name), maxLines: 1, style: _anton(30)),
            ),
            const SizedBox(height: 6),
            Text(
              '${f.record.display}${f.isChampion ? "  ·  CHAMPION" : f.rankingPosition != null ? "  ·  #${f.rankingPosition}" : ""}',
              style: _meta(12.5, _t2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pill(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A2C)),
        ),
        child: Text(text, style: _over(10, c, ls: 1.2)),
      );

  Widget _dot(Color c) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c, blurRadius: 10)],
        ),
      );

}
