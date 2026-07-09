import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ranking.dart';
import 'app_dataset.dart';

/// Read access to divisional rankings, backed by [AppDataset].
class RankingRepository {
  const RankingRepository();

  Future<List<DivisionRanking>> getAll() async =>
      (await AppDataset.load()).rankings;
}

final rankingRepositoryProvider =
    Provider<RankingRepository>((ref) => const RankingRepository());
