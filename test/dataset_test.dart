import 'package:flutter_test/flutter_test.dart';
import 'package:walkout/shared/data/app_dataset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled dataset loads and parses', () async {
    final ds = await AppDataset.load();

    expect(ds.fighters.length, greaterThan(150));
    expect(ds.rankings, isNotEmpty);
    expect(ds.events, isNotEmpty);

    final izzy = ds.fighterById['israel-adesanya'];
    expect(izzy, isNotNull);
    expect(izzy!.record.wins, 24);
    expect(izzy.winsByKo, 16);
    expect(izzy.imageUrl, startsWith('assets/fighters/'));

    // Every division ranking should point at a real champion.
    for (final d in ds.rankings) {
      expect(ds.fighterById[d.championId], isNotNull,
          reason: 'missing champion ${d.championId}');
    }
  });

  test('concurrent loads share one fetch', () async {
    AppDataset.reset();
    // The home screen alone pulls four providers at once; each used to fire its
    // own full fetch (~430 Firestore reads a piece).
    final loads = await Future.wait([
      AppDataset.load(),
      AppDataset.load(),
      AppDataset.load(),
      AppDataset.load(),
      AppDataset.load(),
    ]);
    for (final ds in loads) {
      expect(ds, same(loads.first));
    }
  });

  test('load caches, reset forces a re-read', () async {
    AppDataset.reset();
    final first = await AppDataset.load();
    expect(await AppDataset.load(), same(first),
        reason: 'a warm load must not re-fetch');

    AppDataset.reset();
    // Pull-to-refresh has to get a genuinely new snapshot — the old code
    // returned the cached singleton, so a refresh never fetched anything.
    expect(await AppDataset.load(), isNot(same(first)));
  });

  test('isStale reports bundled snapshots and aged ones', () async {
    AppDataset.reset();
    expect(AppDataset.isStale(const Duration(minutes: 15)), isTrue,
        reason: 'nothing cached yet');

    final ds = await AppDataset.load();
    // No Firebase in the test host, so this is the bundled fallback — which
    // must always invite a retry, however fresh it is.
    expect(ds.isBundled, isTrue);
    expect(AppDataset.isStale(const Duration(minutes: 15)), isTrue);

    // Age-based staleness, measured against a fixed 'now' rather than sleeping.
    expect(
      AppDataset.isStale(const Duration(minutes: 15),
          now: ds.loadedAt.add(const Duration(minutes: 16))),
      isTrue,
    );
  });
}
