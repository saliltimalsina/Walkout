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

/// A rankings "mover" (synthesized movement for the feed, over the real roster).
class Mover {
  const Mover(this.fighter, this.change);
  final Fighter fighter;
  final int change; // >0 up, <0 down, 0 new
}

final rankingsMoversProvider = Provider<List<Mover>>((ref) {
  final all = ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[];
  final ranked = all
      .where((f) => f.rankingPosition != null && f.rankingPosition! <= 15)
      .toList()
    ..sort((a, b) => a.rankingPosition!.compareTo(b.rankingPosition!));
  if (ranked.isEmpty) return const [];
  // Deterministic, varied movement for a lively feed.
  const deltas = [2, -1, 3, 0, 1, -2];
  final picks = <Mover>[];
  for (var i = 0; i < ranked.length && picks.length < 4; i += 3) {
    picks.add(Mover(ranked[i], deltas[i % deltas.length]));
  }
  return picks;
});
