import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/event.dart';
import '../models/fighter.dart';
import '../models/ranking.dart';

/// Loads the bundled, scraped dataset (fighters, rankings, events) from JSON
/// assets and caches it. This is the real-data source backing every repository.
class AppDataset {
  AppDataset._(this.fighters, this.rankings, this.events)
      : fighterById = {for (final f in fighters) f.id: f};

  final List<Fighter> fighters;
  final List<DivisionRanking> rankings;
  final List<Event> events;
  final Map<String, Fighter> fighterById;

  static AppDataset? _instance;

  static Future<AppDataset> load() async {
    final cached = _instance;
    if (cached != null) return cached;

    final results = await Future.wait([
      rootBundle.loadString('assets/data/fighters.json'),
      rootBundle.loadString('assets/data/rankings.json'),
      rootBundle.loadString('assets/data/events.json'),
    ]);

    final fighters = (json.decode(results[0]) as List)
        .map((e) => Fighter.fromJson(e as Map<String, dynamic>))
        .toList();
    final rankings = (json.decode(results[1]) as List)
        .map((e) => DivisionRanking.fromJson(e as Map<String, dynamic>))
        .toList();
    final events = (json.decode(results[2]) as List)
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .toList();

    return _instance = AppDataset._(fighters, rankings, events);
  }
}
