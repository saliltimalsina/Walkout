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

  Future<List<Event>> getUpcoming() async {
    final all = await getAll();
    return all.where((e) => e.status != EventStatus.past).toList();
  }

  Future<List<Event>> getPast() async {
    final all = await getAll();
    return all
        .where((e) => e.status == EventStatus.past)
        .toList()
        .reversed
        .toList();
  }

  /// The next headline event to feature on the home screen.
  Future<Event?> getFeatured() async {
    final upcoming = await getUpcoming();
    return upcoming.firstOrNull;
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
