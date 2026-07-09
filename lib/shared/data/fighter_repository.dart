import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fighter.dart';
import '../models/weight_class.dart';
import 'app_dataset.dart';

/// Read access to fighters, backed by the bundled scraped dataset
/// ([AppDataset]). Swap the body for Dio calls to go live without touching UI.
class FighterRepository {
  const FighterRepository();

  Future<List<Fighter>> getAll() async => (await AppDataset.load()).fighters;

  Future<Fighter> getById(String id) async {
    final fighter = (await AppDataset.load()).fighterById[id];
    if (fighter == null) {
      throw StateError('Fighter "$id" not found');
    }
    return fighter;
  }

  Future<List<Fighter>> getByWeightClass(WeightClass weightClass) async {
    final all = (await AppDataset.load()).fighters;
    return all.where((f) => f.weightClass == weightClass).toList();
  }

  Future<List<Fighter>> getChampions() async {
    final all = (await AppDataset.load()).fighters;
    return all.where((f) => f.isChampion).toList();
  }

  Future<List<Fighter>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final all = (await AppDataset.load()).fighters;
    return all.where((f) {
      return f.name.toLowerCase().contains(q) ||
          f.nickname.toLowerCase().contains(q) ||
          f.country.toLowerCase().contains(q) ||
          f.weightClass.label.toLowerCase().contains(q);
    }).toList();
  }
}

final fighterRepositoryProvider =
    Provider<FighterRepository>((ref) => const FighterRepository());
