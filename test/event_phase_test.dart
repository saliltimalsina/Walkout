import 'package:flutter_test/flutter_test.dart';
import 'package:walkout/shared/models/bout.dart';
import 'package:walkout/shared/models/event.dart';

/// The live window is the contract the whole app hangs off:
///   upcoming ─(date−4h)─ prelims ─(date)─ mainCard ─(date+6h | winner)─ ended
void main() {
  final date = DateTime(2026, 7, 12, 22); // arbitrary local instant

  Event event({String? winnerId}) => Event(
        id: 'e1',
        name: 'UFC Test',
        date: date,
        mainCard: [
          Bout(
            id: 'b1',
            redCornerId: 'red',
            blueCornerId: 'blue',
            isMainEvent: true,
            winnerId: winnerId,
          ),
        ],
      );

  group('Event.phaseAt boundaries', () {
    final e = event();

    test('before prelims lead → upcoming', () {
      expect(e.phaseAt(date.subtract(const Duration(hours: 4, seconds: 1))),
          EventPhase.upcoming);
    });

    test('exactly at date−4h → prelims', () {
      expect(e.phaseAt(date.subtract(const Duration(hours: 4))),
          EventPhase.prelims);
    });

    test('just before the walk → prelims', () {
      expect(e.phaseAt(date.subtract(const Duration(seconds: 1))),
          EventPhase.prelims);
    });

    test('exactly at date → mainCard', () {
      expect(e.phaseAt(date), EventPhase.mainCard);
    });

    test('just inside the live tail → mainCard', () {
      expect(e.phaseAt(date.add(const Duration(hours: 6, seconds: -1))),
          EventPhase.mainCard);
    });

    test('at date+6h → ended (LIVE must die)', () {
      expect(e.phaseAt(date.add(const Duration(hours: 6))), EventPhase.ended);
    });

    test('isLiveAt spans prelims through mainCard only', () {
      expect(e.isLiveAt(date.subtract(const Duration(hours: 5))), isFalse);
      expect(e.isLiveAt(date.subtract(const Duration(hours: 1))), isTrue);
      expect(e.isLiveAt(date.add(const Duration(hours: 1))), isTrue);
      expect(e.isLiveAt(date.add(const Duration(hours: 7))), isFalse);
    });

    test('statusAt maps phases onto the legacy enum', () {
      expect(e.statusAt(date.subtract(const Duration(days: 1))),
          EventStatus.upcoming);
      expect(e.statusAt(date), EventStatus.live);
      expect(e.statusAt(date.add(const Duration(days: 1))), EventStatus.past);
    });
  });

  group('result data ends the event early', () {
    test('winnerId after the walk → ended inside the live tail', () {
      final e = event(winnerId: 'red');
      expect(e.phaseAt(date.add(const Duration(hours: 1))), EventPhase.ended);
    });

    test('winnerId does not affect pre-fight phases', () {
      final e = event(winnerId: 'red');
      expect(e.phaseAt(date.subtract(const Duration(hours: 1))),
          EventPhase.prelims);
      expect(e.phaseAt(date.subtract(const Duration(days: 1))),
          EventPhase.upcoming);
    });
  });

  group('UTC date parse shim', () {
    test('naive string is reinterpreted as UTC', () {
      final naive = _fromDate('2026-07-12T01:00:00.000');
      final zoned = _fromDate('2026-07-12T01:00:00.000Z');
      expect(naive.date.isAtSameMomentAs(zoned.date), isTrue);
    });

    test('parsed date is local for display call sites', () {
      final e = _fromDate('2026-07-12T01:00:00.000Z');
      expect(e.date.isUtc, isFalse);
    });

    test('toJson round-trips the same instant with a Z', () {
      final e = _fromDate('2026-07-12T01:00:00.000');
      final encoded = e.toJson()['date'] as String;
      expect(encoded.endsWith('Z'), isTrue);
      expect(Event.fromJson(e.toJson()).date.isAtSameMomentAs(e.date), isTrue);
    });
  });
}

Event _fromDate(String iso) => Event.fromJson({
      'id': 'e1',
      'name': 'UFC Test',
      'date': iso,
    });
