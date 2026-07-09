import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/shared/models/fighter.dart';
import 'package:walkout/shared/providers/data_providers.dart';
import 'package:walkout/shared/providers/favorites_controller.dart';

/// Fighters offered on the notifications step: the user's corner first, then
/// champions / top-ranked, capped to a tidy grid.
final notifyCandidatesProvider = Provider<List<Fighter>>((ref) {
  final all = ref.watch(fightersProvider).valueOrNull ?? const <Fighter>[];
  final favs = ref.watch(favoritesProvider);
  final byId = {for (final f in all) f.id: f};

  final ordered = <Fighter>[];
  final seen = <String>{};
  void add(Fighter f) {
    if (seen.add(f.id)) ordered.add(f);
  }

  for (final id in favs) {
    final f = byId[id];
    if (f != null) add(f);
  }
  final rest = [...all]..sort((a, b) {
      if (a.isChampion != b.isChampion) return a.isChampion ? -1 : 1;
      return (a.rankingPosition ?? 999).compareTo(b.rankingPosition ?? 999);
    });
  for (final f in rest) {
    add(f);
    if (ordered.length >= 9) break;
  }
  return ordered.take(9).toList();
});

/// Fighter ids the user wants alerts for. Seeded from their corner.
final notifyFightersProvider =
    NotifierProvider<NotifyController, Set<String>>(NotifyController.new);

class NotifyController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {...ref.read(favoritesProvider)};

  void toggle(String id) {
    final next = {...state};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = next;
  }
}

final notifyPpvProvider = StateProvider<bool>((ref) => true);
final notifyFightNightsProvider = StateProvider<bool>((ref) => true);
