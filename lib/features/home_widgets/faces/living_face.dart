import 'package:flutter/material.dart';

import 'package:walkout/shared/models/models.dart';

import '../application/living_state.dart';

/// The Living Widget's 4x2 face — renders every [LivingState] with one
/// adaptive composition. Rendered offscreen to PNG; countdown DIGITS inside
/// the final 24h are drawn natively by the Android layout (chronometer), so
/// this face leaves the bottom-right corner clear in those states.
class LivingFace extends StatelessWidget {
  const LivingFace({super.key, required this.snapshot, required this.now});

  final LivingSnapshot snapshot;
  final DateTime now;

  static const _bg = Color(0xFF101012);
  static const _bgDeep = Color(0xFF0B0B0D);
  static const _brand = Color(0xFFD20A0A);
  static const _gold = Color(0xFFFACC15);
  static const _green = Color(0xFF22C55E);
  static const _textSecondary = Color(0xFF9E9EA3);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bg, _bgDeep],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Brand aura.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.75, -0.4),
                    radius: 1.1,
                    colors: [
                      _auraColor().withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            ..._body(),
          ],
        ),
      ),
    );
  }

  Color _auraColor() => switch (snapshot.state) {
        LivingState.result when snapshot.won == true => _gold,
        LivingState.result => _brand,
        LivingState.aftermath => _gold,
        _ => _brand,
      };

  List<Widget> _body() => switch (snapshot.state) {
        LivingState.empty => _empty(),
        LivingState.corner => _corner(),
        LivingState.booked => _booked(),
        LivingState.fightWeek ||
        LivingState.weighInDay =>
          _fightWeek(),
        LivingState.fightNight => _fightNight(),
        LivingState.result => _result(),
        LivingState.aftermath => _aftermath(),
      };

  // ── shared bits ────────────────────────────────────────────────────

  Widget _portrait(Fighter? f, {Alignment align = Alignment.centerRight}) {
    if (f == null || f.imageUrl.isEmpty) return const SizedBox.shrink();
    final onLeft = align == Alignment.centerLeft;
    // Gradient-overlay fade into the bg (not a ShaderMask) so the offscreen
    // render is paint-ready synchronously.
    return Align(
      alignment: align,
      child: FractionallySizedBox(
        widthFactor: 0.42,
        heightFactor: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              f.imageUrl,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.8),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: onLeft ? Alignment.centerLeft : Alignment.centerRight,
                  end: onLeft ? Alignment.centerRight : Alignment.centerLeft,
                  colors: const [Colors.transparent, _bgDeep],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _anton => const TextStyle(
        fontFamily: 'Anton',
        color: Colors.white,
        height: 1.04,
        letterSpacing: 0.5,
      );

  TextStyle get _inter => const TextStyle(
        fontFamily: 'Inter',
        color: _textSecondary,
        fontWeight: FontWeight.w600,
      );

  TextStyle _overline(Color color) => TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: color,
      );

  static String _last(String? name) {
    if (name == null || name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.last.toUpperCase();
  }

  String _daysLabel(DateTime target) {
    final d = target.difference(now).inDays;
    return d <= 0 ? 'TODAY' : d == 1 ? '1 DAY' : '$d DAYS';
  }

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  String _date(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  Widget _leftColumn(List<Widget> children) => Positioned(
        left: 18,
        top: 14,
        bottom: 14,
        right: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );

  // ── faces ──────────────────────────────────────────────────────────

  List<Widget> _empty() => [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('WALKOUT',
                  style: _anton.copyWith(fontSize: 26, color: _brand)),
              const SizedBox(height: 6),
              Text('OPEN TO BUILD YOUR CORNER',
                  style: _overline(_textSecondary)),
            ],
          ),
        ),
      ];

  List<Widget> _corner() {
    final f = snapshot.fighter!;
    final next = snapshot.event;
    return [
      _portrait(f),
      _leftColumn([
        Row(
          children: [
            if (f.isChampion) ...[
              Text('C', style: _anton.copyWith(fontSize: 15, color: _gold)),
              const SizedBox(width: 6),
            ],
            Text(
              f.weightClass.label.toUpperCase(),
              style: _overline(_brand),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(f.name.toUpperCase(),
              maxLines: 1, style: _anton.copyWith(fontSize: 30)),
        ),
        const SizedBox(height: 4),
        Text(
          next != null
              ? 'NEXT: ${(next.eventType.isEmpty ? next.name : next.eventType).toUpperCase()} · ${_date(next.date)}'
              : f.record.display,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _inter.copyWith(fontSize: 12),
        ),
      ]),
    ];
  }

  List<Widget> _booked() {
    final e = snapshot.event!;
    return [
      _portrait(snapshot.fighter,
          align: Alignment.centerLeft),
      _portrait(snapshot.opponent),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: _last(snapshot.fighter?.name)),
                  TextSpan(
                    text: '  VS  ',
                    style: TextStyle(
                      fontSize: 14,
                      color: _brand,
                      shadows: const [Shadow(color: _brand, blurRadius: 14)],
                    ),
                  ),
                  TextSpan(text: _last(snapshot.opponent?.name)),
                ]),
                maxLines: 1,
                style: _anton.copyWith(fontSize: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(e.eventType.isEmpty ? e.name : e.eventType).toUpperCase()} · ${_date(e.date)} · ${_daysLabel(e.date)}',
              style: _overline(Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _fightWeek() {
    final e = snapshot.event!;
    final total = e.date.difference(PhaseSchedule(e.date).fightWeekStart);
    final gone = now.difference(PhaseSchedule(e.date).fightWeekStart);
    final pct = (gone.inMinutes / total.inMinutes).clamp(0.0, 1.0);

    return [
      _portrait(snapshot.fighter),
      _leftColumn([
        Text(
          snapshot.state == LivingState.weighInDay
              ? 'WEIGH-IN DAY'
              : 'FIGHT WEEK',
          style: _overline(_brand),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${_last(snapshot.fighter?.name)} VS ${_last(snapshot.opponent?.name)}',
            maxLines: 1,
            style: _anton.copyWith(fontSize: 22),
          ),
        ),
        const SizedBox(height: 6),
        // Octagon-ish progress: red filling bar (ring simplified for 4x2).
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 150,
            height: 5,
            child: Stack(children: [
              Container(color: const Color(0xFF2A2A2C)),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(color: _brand),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'TODAY: ${snapshot.phase?.label ?? ''} · ${_daysLabel(e.date)}',
          style: _inter.copyWith(fontSize: 11.5),
        ),
        // Bottom-right left clear for the native chronometer inside 24h.
      ]),
    ];
  }

  List<Widget> _fightNight() {
    final e = snapshot.event!;
    final order = [...e.mainCard];
    return [
      _leftColumn([
        Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _brand,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _brand, blurRadius: 10)],
            ),
          ),
          const SizedBox(width: 6),
          Text('LIVE · CARD IN PROGRESS', style: _overline(_brand)),
        ]),
        const SizedBox(height: 6),
        for (final b in order.take(2).toList().reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${b.isMainEvent ? "▸ " : "  "}${_last(b.redName)} VS ${_last(b.blueName)}'
                '${b.isMainEvent ? "  · MAIN EVENT" : ""}',
                maxLines: 1,
                style: _anton.copyWith(fontSize: 17),
              ),
            ),
          ),
        const SizedBox(height: 2),
        Text(
          (e.eventType.isEmpty ? e.name : e.eventType).toUpperCase(),
          style: _inter.copyWith(fontSize: 11.5),
        ),
      ]),
    ];
  }

  List<Widget> _result() {
    final won = snapshot.won == true;
    final f = snapshot.fighter!;
    final b = snapshot.bout!;
    return [
      _portrait(f),
      _leftColumn([
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: won ? _green : _brand,
          child: Text(
            won ? 'W' : 'L',
            style: _anton.copyWith(fontSize: 18, color: Colors.black),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_last(f.name),
              maxLines: 1, style: _anton.copyWith(fontSize: 28)),
        ),
        const SizedBox(height: 4),
        Text(
          '${won ? "WINS" : "LOSES"}'
          '${b.method.isEmpty ? "" : " · ${b.method.toUpperCase()}"}'
          '${b.finishRound.isEmpty ? "" : " ${b.finishRound}"}',
          style: _overline(won ? _green : _brand),
        ),
        const SizedBox(height: 2),
        Text('NOW ${f.record.display}'
            '${f.isChampion ? "  ·  STILL CHAMPION" : ""}',
            style: _inter.copyWith(fontSize: 12)),
      ]),
    ];
  }

  List<Widget> _aftermath() {
    final f = snapshot.fighter!;
    return [
      _portrait(f),
      _leftColumn([
        Text('THE DAY AFTER', style: _overline(_gold)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_last(f.name),
              maxLines: 1, style: _anton.copyWith(fontSize: 28)),
        ),
        const SizedBox(height: 4),
        Text(
          '${f.record.display}'
          '${f.isChampion ? "  ·  C" : f.rankingPosition != null ? "  ·  #${f.rankingPosition}" : ""}',
          style: _inter.copyWith(fontSize: 12.5),
        ),
      ]),
    ];
  }
}
