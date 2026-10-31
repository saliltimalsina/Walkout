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

    test('getUpcoming excludes ended events (time-derived)', () async {
      final now = DateTime.now();
      final upcoming = await repo.getUpcoming(now: now);
      expect(upcoming.every((e) => e.statusAt(now) != EventStatus.past),
          isTrue);
    });

    test('getPast returns only ended events (time-derived)', () async {
      final now = DateTime.now();
      final past = await repo.getPast(now: now);
      expect(
          past.every((e) => e.statusAt(now) == EventStatus.past), isTrue);
    });

    test('upcoming + past partition all events', () async {
      final now = DateTime.now();
      final all = await repo.getAll();
      final upcoming = await repo.getUpcoming(now: now);
      final past = await repo.getPast(now: now);
      expect(upcoming.length + past.length, all.length);
    });

    test('getFeatured returns a non-ended event, live preferred', () async {
      // Pin "now" before the earliest bundled event — the real clock passes
      // every bundled event eventually and the featured slot goes empty.
      final all = await repo.getAll();
      final now = all.first.date.subtract(const Duration(days: 1));
      final featured = await repo.getFeatured(now: now);
      expect(featured, isNotNull);
      expect(featured!.statusAt(now), isNot(EventStatus.past));
      final upcoming = await repo.getUpcoming(now: now);
      final liveOnes = upcoming.where((e) => e.isLiveAt(now));
      if (liveOnes.isNotEmpty) {
        expect(featured.id, liveOnes.first.id);
      }
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
