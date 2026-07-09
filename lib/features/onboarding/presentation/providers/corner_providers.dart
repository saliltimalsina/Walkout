import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/shared/models/fighter.dart';
import 'package:walkout/shared/models/weight_class.dart';
import 'package:walkout/shared/providers/data_providers.dart';

/// Curated "quick filter" lenses for the Build Your Corner picker.
enum QuickFilter {
  champions('Champions'),
  top15('Top 15'),
  trending('Trending'),
  rising('Rising Stars'),
  legends('Legends');

  const QuickFilter(this.label);
  final String label;
}

bool matchesQuickFilter(Fighter f, QuickFilter filter) {
  final ranked = f.rankingPosition != null;
  return switch (filter) {
    QuickFilter.champions => f.isChampion,
    QuickFilter.top15 => f.isChampion || (ranked && f.rankingPosition! <= 15),
    QuickFilter.trending => f.isChampion || (ranked && f.rankingPosition! <= 5),
    QuickFilter.rising => ranked && f.age > 0 && f.age <= 27,
    QuickFilter.legends => f.age >= 35 || f.record.wins >= 20,
  };
}

/// Ordered list of chosen fighter ids (max 5).
final cornerSelectionProvider =
    NotifierProvider<CornerController, List<String>>(CornerController.new);

class CornerController extends Notifier<List<String>> {
  static const int maxSize = 5;

  @override
  List<String> build() => const [];

  bool contains(String id) => state.contains(id);
  bool get isFull => state.length >= maxSize;

  void toggle(String id) {
    if (state.contains(id)) {
      state = state.where((e) => e != id).toList();
    } else if (state.length < maxSize) {
      state = [...state, id];
    }
  }

  void remove(String id) => state = state.where((e) => e != id).toList();
}

// ── Filter state ────────────────────────────────────────────────
final cornerQuickFilterProvider =
    StateProvider<QuickFilter>((ref) => QuickFilter.champions);

/// Selected weight class, or null for "All".
final cornerWeightFilterProvider = StateProvider<WeightClass?>((ref) => null);

final cornerSearchProvider = StateProvider<String>((ref) => '');

/// Fighters matching the active quick filter, weight class and search query.
final cornerFilteredProvider = Provider<AsyncValue<List<Fighter>>>((ref) {
  final async = ref.watch(fightersProvider);
  final quick = ref.watch(cornerQuickFilterProvider);
  final weight = ref.watch(cornerWeightFilterProvider);
  final query = ref.watch(cornerSearchProvider).trim().toLowerCase();

  return async.whenData((all) {
    var list = all.where((f) => matchesQuickFilter(f, quick)).toList();
    if (weight != null) {
      list = list.where((f) => f.weightClass == weight).toList();
    }
    if (query.isNotEmpty) {
      list = list
          .where((f) =>
              f.name.toLowerCase().contains(query) ||
              f.nickname.toLowerCase().contains(query))
          .toList();
    }
    // Champions first, then by rank, then name.
    list.sort((a, b) {
      if (a.isChampion != b.isChampion) return a.isChampion ? -1 : 1;
      final ra = a.rankingPosition ?? 999;
      final rb = b.rankingPosition ?? 999;
      if (ra != rb) return ra.compareTo(rb);
      return a.name.compareTo(b.name);
    });
    return list;
  });
});

/// Count per quick filter (for the "Champions (12)" labels).
final quickFilterCountsProvider = Provider<Map<QuickFilter, int>>((ref) {
  final all = ref.watch(fightersProvider).valueOrNull ?? const [];
  return {
    for (final q in QuickFilter.values)
      q: all.where((f) => matchesQuickFilter(f, q)).length,
  };
});

/// Weight classes that actually have fighters, for the pill row.
final availableWeightClassesProvider = Provider<List<WeightClass>>((ref) {
  final all = ref.watch(fightersProvider).valueOrNull ?? const [];
  final present = all.map((f) => f.weightClass).toSet();
  return WeightClass.values.where(present.contains).toList();
});
