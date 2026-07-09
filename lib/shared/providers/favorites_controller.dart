import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../data/mock_data.dart';

/// Cross-cutting favorites state (favorited fighter ids), persisted to local
/// storage. Consumed by fighter detail (toggle) and profile (list).
final favoritesProvider =
    NotifierProvider<FavoritesController, Set<String>>(FavoritesController.new);

class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final stored = ref.read(storageServiceProvider).favoriteFighterIds;
    // Seed with the mock user's favorites the first time the app runs.
    if (stored.isEmpty) {
      return {...MockData.currentUser.favoriteFighterIds};
    }
    return stored;
  }

  bool isFavorite(String fighterId) => state.contains(fighterId);

  Future<void> toggle(String fighterId) async {
    final next = {...state};
    if (next.contains(fighterId)) {
      next.remove(fighterId);
    } else {
      next.add(fighterId);
    }
    state = next;
    await ref.read(storageServiceProvider).toggleFavorite(fighterId);
  }

  /// Adds several fighters at once (e.g. the corner chosen during onboarding).
  Future<void> addAll(Iterable<String> ids) async {
    final storage = ref.read(storageServiceProvider);
    final next = {...state};
    for (final id in ids) {
      if (!next.contains(id)) {
        next.add(id);
        await storage.toggleFavorite(id);
      }
    }
    state = next;
  }
}
