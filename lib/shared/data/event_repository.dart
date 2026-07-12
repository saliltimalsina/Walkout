import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import 'app_dataset.dart';

/// Read access to events / fight cards, backed by [AppDataset].
class EventRepository {
  const EventRepository();

  Future<List<Event>> getAll() async {
    final events = [...(await AppDataset.load()).events]
      ..sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  /// Everything not yet ended, live events included. Status is derived from
  /// the clock ([Event.statusAt]) — the stored field goes stale between
  /// ingest runs. [now] is injectable for tests.
  Future<List<Event>> getUpcoming({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final all = await getAll();
    return all.where((e) => e.statusAt(n) != EventStatus.past).toList();
  }

  Future<List<Event>> getPast({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final all = await getAll();
    return all
        .where((e) => e.statusAt(n) == EventStatus.past)
        .toList()
        .reversed
        .toList();
  }

  /// The headline event for the home hero: the live one while a card is on,
  /// else the next upcoming.
  Future<Event?> getFeatured({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final upcoming = await getUpcoming(now: n);
    return upcoming.where((e) => e.isLiveAt(n)).firstOrNull ??
        upcoming.firstOrNull;
  }

  Future<Event> getById(String id) async {
    final event =
        (await AppDataset.load()).events.where((e) => e.id == id).firstOrNull;
    if (event == null) {
      throw StateError('Event "$id" not found');
    }
    return event;
  }
}

final eventRepositoryProvider =
    Provider<EventRepository>((ref) => const EventRepository());
