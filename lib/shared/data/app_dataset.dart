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
      : fighterById = {for (final f in fighters) f.id: f},
        loadedAt = DateTime.now();

  final List<Fighter> fighters;
  final List<DivisionRanking> rankings;
  final List<Event> events;
  final Map<String, Fighter> fighterById;

  /// 'firestore' or 'bundled' — useful for debugging / a dashboard badge.
  final String source;

  /// Last successful ingest run (meta/ingest.lastRunAt); null when bundled
  /// or the meta doc is absent. The gallery dev area shows this.
  final DateTime? syncedAt;

  /// When this snapshot was built, for the staleness check below.
  final DateTime loadedAt;

  /// True when this snapshot came from the bundled JSON rather than Firestore.
  bool get isBundled => source == 'bundled';

  /// Whether a re-read is worth its cost right now. A full load is ~430
  /// document reads (400 fighters + events + rankings), so an unconditional
  /// refetch on every foreground would burn the Firestore free tier in a day.
  /// Bundled snapshots always say yes — that is the offline-cold-start recovery
  /// path, and it costs nothing when the network is genuinely down.
  static bool isStale(Duration maxAge, {DateTime? now}) {
    final cached = _instance;
    if (cached == null || cached.isBundled) return true;
    return (now ?? DateTime.now()).difference(cached.loadedAt) > maxAge;
  }

  /// How long to wait on Firestore before serving bundled data. Firestore's
  /// `get()` has no deadline of its own, so without this a flaky network stalls
  /// first paint instead of degrading to bundled.
  static const Duration _remoteTimeout = Duration(seconds: 12);

  static AppDataset? _instance;

  /// Shared across concurrent callers — the home screen alone pulls four
  /// providers at once, and each would otherwise fire its own Firestore fetch.
  static Future<AppDataset>? _inFlight;

  /// Bumped by [reset]. A load that was already running when the cache was
  /// dropped must not write its now-superseded snapshot back into [_instance].
  static int _generation = 0;

  static Future<AppDataset> load() {
    final cached = _instance;
    if (cached != null) return Future.value(cached);
    final pending = _inFlight;
    if (pending != null) return pending;
    final started = _generation;
    return _inFlight = _load(started).whenComplete(() {
      if (_generation == started) _inFlight = null;
    });
  }

  static Future<AppDataset> _load(int generation) async {
    // ensureReady (not isReady): a cold start that came up before the network
    // did leaves Firebase un-initialized, and reading a stale flag would pin
    // the whole session to bundled data.
    if (await FirebaseBootstrap.ensureReady()) {
      try {
        final remote = await _loadRemote().timeout(_remoteTimeout);
        debugPrint('[dataset] source=firestore events=${remote.events.length} '
            'fighters=${remote.fighters.length} '
            'synced=${remote.syncedAt ?? 'unknown'}');
        return _cache(remote, generation);
      } catch (e) {
        debugPrint('[dataset] remote load failed, using bundled: $e');
      }
    } else {
      debugPrint('[dataset] firebase not ready, using bundled');
    }
    final bundled = await _loadBundled();
    debugPrint('[dataset] source=bundled events=${bundled.events.length}');
    return _cache(bundled, generation);
  }

  /// Publishes [dataset] as the cached snapshot unless a [reset] landed while
  /// this load was in flight — the caller still gets the data either way.
  static AppDataset _cache(AppDataset dataset, int generation) {
    if (_generation == generation) _instance = dataset;
    return dataset;
  }

  /// Drops the cache so the next [load] re-reads (used on a data-changed push
  /// and by every pull-to-refresh — without this the refresh re-reads the same
  /// cached snapshot and nothing new ever arrives).
  static void reset() {
    _generation++;
    _instance = null;
    _inFlight = null;
  }

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
    // Fighters without a bundled image (undercard athletes added by the
    // ingest) fall back to their ufc.com photo, so every screen reading
    // imageUrl shows a face instead of a blank.
    final fighters = _parseAll(results[0].docs, Fighter.fromJson)
        .map((f) => f.imageUrl.isEmpty && f.photoUrl.isNotEmpty
            ? f.copyWith(imageUrl: f.photoUrl)
            : f)
        .toList();
    final rankings = _parseAll(results[1].docs, DivisionRanking.fromJson);
    final events = _parseAll(results[2].docs, Event.fromJson);
    if (fighters.isEmpty || events.isEmpty) {
      throw StateError('firestore returned empty collections');
    }
    return AppDataset._(fighters, rankings, events, 'firestore',
        syncedAt: syncedAt);
  }

  /// Parses each doc on its own and skips the ones that don't fit the model.
  /// One half-written doc (e.g. a fighter with no name) must not throw away
  /// the whole remote dataset and drop the app back to stale bundled data.
  static List<T> _parseAll<T>(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final out = <T>[];
    for (final d in docs) {
      try {
        out.add(fromJson(_normalize(d.data())));
      } catch (e) {
        debugPrint('[dataset] skipped ${d.reference.path}: $e');
      }
    }
    return out;
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
