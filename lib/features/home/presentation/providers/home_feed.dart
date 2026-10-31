import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/shared/models/fighter.dart';
import 'package:walkout/shared/providers/data_providers.dart';

/// A single "stats leader" tile (computed from the real roster).
class StatLeader {
  const StatLeader(this.label, this.value, this.name, {this.imageUrl = ''});
  final String label;
  final String value;
  final String name;
  final String imageUrl;
}

final statsLeadersProvider = Provider<List<StatLeader>>((ref) {
  final all = ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[];
  if (all.isEmpty) return const [];

  Fighter maxBy(num Function(Fighter) f) =>
      all.reduce((a, b) => f(a) >= f(b) ? a : b);

  final koKing = maxBy((f) => f.winsByKo);
  final finisher = maxBy((f) => f.winsByKo + f.winsBySub);
  final mostWins = maxBy((f) => f.record.wins);
  final striker = maxBy((f) => f.stats.strikingAccuracy);

  String last(Fighter f) => f.name.split(' ').last;

  return [
    StatLeader('Most KO/TKO', '${koKing.winsByKo}', last(koKing),
        imageUrl: koKing.imageUrl),
    StatLeader('Most Finishes',
        '${finisher.winsByKo + finisher.winsBySub}', last(finisher),
        imageUrl: finisher.imageUrl),
    StatLeader('Most Wins', '${mostWins.record.wins}', last(mostWins),
        imageUrl: mostWins.imageUrl),
    StatLeader('Top Strike Acc',
        '${striker.stats.strikingAccuracy.toStringAsFixed(0)}%', last(striker),
        imageUrl: striker.imageUrl),
  ];
});

/// A rankings "mover": who actually climbed, fell, or entered the top 15 in
/// UFC's latest rankings update.
class Mover {
  const Mover(this.fighter, this.change,
      {required this.position, this.isNew = false});
  final Fighter fighter;
  final int change; // >0 up, <0 down
  final bool isNew; // entered the top 15 this update

  /// Rank from the rankings collection, which is the authority — the copy on
  /// [Fighter] only refreshes when that doc is rewritten.
  final int position;
}

/// Real movement from the scraped rankings. Weeks with no reshuffle legitimately
/// produce an empty list, and the section hides itself rather than inventing
/// motion to fill the space.
final rankingsMoversProvider = Provider<List<Mover>>((ref) {
  final divisions = ref.watch(rankingsProvider).valueOrNull;
  final all = ref.watch(fightersProvider).valueOrNull;
  if (divisions == null || all == null) return const [];
  final byId = {for (final f in all) f.id: f};

  final movers = <Mover>[];
  for (final d in divisions) {
    for (final e in d.contenders) {
      if (e.change == 0 && !e.isNew) continue;
      final f = byId[e.fighterId];
      if (f == null) continue;
      movers.add(
          Mover(f, e.change, position: e.position, isNew: e.isNew));
    }
  }
  // Biggest swings first; new entries rank alongside a one-place climb.
  movers.sort((a, b) {
    final byMagnitude = b.change.abs().compareTo(a.change.abs());
    return byMagnitude != 0 ? byMagnitude : a.fighter.name.compareTo(b.fighter.name);
  });
  return movers.take(4).toList();
});
