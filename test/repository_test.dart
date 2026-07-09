import 'package:flutter_test/flutter_test.dart';
import 'package:walkout/shared/data/event_repository.dart';
import 'package:walkout/shared/data/fighter_repository.dart';
import 'package:walkout/shared/data/ranking_repository.dart';
import 'package:walkout/shared/models/event.dart';
import 'package:walkout/shared/models/weight_class.dart';

void main() {
  // Repositories read bundled JSON assets, which requires the test binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FighterRepository', () {
    const repo = FighterRepository();

    test('getAll returns the scraped roster', () async {
      final fighters = await repo.getAll();
      expect(fighters.length, greaterThan(150));
    });

    test('getById returns the requested fighter', () async {
      final fighter = await repo.getById('islam-makhachev');
      expect(fighter.name, 'Islam Makhachev');
    });

    test('getById throws for unknown id', () {
      expect(repo.getById('nope'), throwsA(isA<StateError>()));
    });

    test('getChampions only returns champions', () async {
      final champs = await repo.getChampions();
      expect(champs, isNotEmpty);
      expect(champs.every((f) => f.isChampion), isTrue);
    });

    test('getByWeightClass filters by division', () async {
      final lw = await repo.getByWeightClass(WeightClass.lightweight);
      expect(lw, isNotEmpty);
      expect(lw.every((f) => f.weightClass == WeightClass.lightweight), isTrue);
    });

    test('search matches by name (case-insensitive)', () async {
      final results = await repo.search('MAKHA');
      expect(results.any((f) => f.id == 'islam-makhachev'), isTrue);
    });

    test('search returns empty for blank query', () async {
      expect(await repo.search('   '), isEmpty);
    });
  });

  group('EventRepository', () {
    const repo = EventRepository();

    test('getUpcoming excludes past events', () async {
      final upcoming = await repo.getUpcoming();
      expect(upcoming.every((e) => e.status != EventStatus.past), isTrue);
    });

    test('getPast returns only past events', () async {
      final past = await repo.getPast();
      expect(past.every((e) => e.status == EventStatus.past), isTrue);
    });

    test('getFeatured returns the next upcoming event', () async {
      final featured = await repo.getFeatured();
      expect(featured, isNotNull);
      expect(featured!.status, isNot(EventStatus.past));
    });
  });

  group('RankingRepository', () {
    const repo = RankingRepository();

    test('getAll returns divisions with a champion', () async {
      final rankings = await repo.getAll();
      expect(rankings, isNotEmpty);
      expect(rankings.every((d) => d.championId.isNotEmpty), isTrue);
    });
  });
}
