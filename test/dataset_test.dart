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
}
