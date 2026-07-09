import 'package:flutter_test/flutter_test.dart';
import 'package:walkout/shared/models/models.dart';

void main() {
  group('FightRecord', () {
    test('display formats as W-L-D', () {
      const r = FightRecord(wins: 23, losses: 1, draws: 0);
      expect(r.display, '23-1-0');
    });

    test('totalFights sums all outcomes', () {
      const r = FightRecord(wins: 10, losses: 2, draws: 1, noContests: 1);
      expect(r.totalFights, 14);
    });
  });

  group('Fighter.rankLabel', () {
    const base = Fighter(
      id: 'x',
      name: 'Test Fighter',
      weightClass: WeightClass.lightweight,
    );

    test('champion returns "C"', () {
      expect(base.copyWith(isChampion: true).rankLabel, 'C');
    });

    test('ranked returns "#n"', () {
      expect(base.copyWith(rankingPosition: 5).rankLabel, '#5');
    });

    test('unranked returns "NR"', () {
      expect(base.rankLabel, 'NR');
    });
  });

  group('WeightClass', () {
    test('fromName round-trips', () {
      expect(WeightClass.fromName('welterweight'), WeightClass.welterweight);
    });

    test('unknown name falls back to lightweight', () {
      expect(WeightClass.fromName('nope'), WeightClass.lightweight);
    });

    test('isWomens detects women divisions', () {
      expect(WeightClass.womenBantamweight.isWomens, isTrue);
      expect(WeightClass.lightweight.isWomens, isFalse);
    });
  });

  group('JSON serialization', () {
    test('Fighter survives a round trip', () {
      const fighter = Fighter(
        id: 'f1',
        name: 'Islam Makhachev',
        weightClass: WeightClass.lightweight,
        record: FightRecord(wins: 26, losses: 1),
        isChampion: true,
      );
      final json = fighter.toJson();
      final restored = Fighter.fromJson(json);
      expect(restored, fighter);
    });
  });
}
