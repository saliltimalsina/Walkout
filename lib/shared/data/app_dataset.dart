import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/services/firebase_bootstrap.dart';
import '../models/event.dart';
import '../models/fighter.dart';
import '../models/ranking.dart';

/// Loads the dataset (fighters, rankings, events) and caches it. Source is
/// Firestore when the backend is live, else the bundled scraped JSON. Firestore
/// failures fall back to bundled so the app is never dataless.
class AppDataset {
  AppDataset._(this.fighters, this.rankings, this.events, this.source,
      {this.syncedAt})
      : fighterById = {for (final f in fighters) f.id: f};

  final List<Fighter> fighters;
  final List<DivisionRanking> rankings;
  final List<Event> events;
  final Map<String, Fighter> fighterById;

  /// 'firestore' or 'bundled' — useful for debugging / a dashboard badge.
  final String source;

  /// Last successful ingest run (meta/ingest.lastRunAt); null when bundled
  /// or the meta doc is absent. The gallery dev area shows this.
  final DateTime? syncedAt;

  static AppDataset? _instance;

  static Future<AppDataset> load() async {
    final cached = _instance;
    if (cached != null) return cached;

    if (FirebaseBootstrap.isReady) {
      try {
        final remote = await _loadRemote();
        debugPrint(
            '[dataset] source=firestore synced=${remote.syncedAt ?? 'unknown'}');
        return _instance = remote;
      } catch (e) {
        debugPrint('[dataset] remote load failed, using bundled: $e');
      }
    }
    debugPrint('[dataset] source=bundled');
    return _instance = await _loadBundled();
  }

  /// Drops the cache so the next [load] re-reads (used on a data-changed push).
  static void reset() => _instance = null;

  static Future<AppDataset> _loadBundled() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/data/fighters.json'),
      rootBundle.loadString('assets/data/rankings.json'),
      rootBundle.loadString('assets/data/events.json'),
    ]);
    return AppDataset._(
      (json.decode(results[0]) as List)
          .map((e) => Fighter.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json.decode(results[1]) as List)
          .map((e) => DivisionRanking.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json.decode(results[2]) as List)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      'bundled',
    );
  }

  static Future<AppDataset> _loadRemote() async {
    final db = FirebaseFirestore.instance;
    final results = await Future.wait([
      db.collection('fighters').get(),
      db.collection('rankings').get(),
      db.collection('events').get(),
    ]);
    // Freshness signal only — tolerate the meta doc being absent.
    DateTime? syncedAt;
    try {
      final meta = await db.collection('meta').doc('ingest').get();
      final ts = meta.data()?['lastRunAt'];
      if (ts is Timestamp) syncedAt = ts.toDate();
    } catch (_) {}
    // Docs are stored in the same shape as the bundled JSON, so fromJson maps
    // straight across (seed script guarantees this contract).
    final fighters = results[0]
        .docs
        .map((d) => Fighter.fromJson(_normalize(d.data())))
        .toList();
    final rankings = results[1]
        .docs
        .map((d) => DivisionRanking.fromJson(_normalize(d.data())))
        .toList();
    final events = results[2]
        .docs
        .map((d) => Event.fromJson(_normalize(d.data())))
        .toList();
    if (fighters.isEmpty || events.isEmpty) {
      throw StateError('firestore returned empty collections');
    }
    return AppDataset._(fighters, rankings, events, 'firestore',
        syncedAt: syncedAt);
  }

  /// Firestore hands back `Timestamp` for date fields; the models expect ISO
  /// strings. Coerce any Timestamp to UTC ISO-8601 (with the `Z`) so the same
  /// instant round-trips regardless of device timezone.
  static Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((k, v) {
      out[k] = v is Timestamp ? v.toDate().toUtc().toIso8601String() : v;
    });
    return out;
  }
}
