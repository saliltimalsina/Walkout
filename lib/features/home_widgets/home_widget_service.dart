import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import 'package:walkout/core/services/storage_service.dart';
import 'package:walkout/shared/data/app_dataset.dart';
import 'package:walkout/shared/models/models.dart';

import 'application/living_state.dart';
import 'faces/faceoff_face.dart';
import 'faces/living_face.dart';
import 'widget_capture.dart';

/// Bridges app data to the native home-screen widgets: resolves the subject,
/// renders faces to PNG and pushes update broadcasts.
///
/// v1 scope: Face-Off (4x4). The Living Widget engine builds on the same
/// pipeline.
class HomeWidgetService {
  const HomeWidgetService._();

  /// Fully-qualified Android provider names (subpackage `widgets`).
  static const _faceoffProvider =
      'com.walkout.walkout.widgets.FaceoffWidgetProvider';
  static const _livingProvider =
      'com.walkout.walkout.widgets.LivingWidgetProvider';

  /// Renders + publishes all widgets. Cheap when nothing changed — the
  /// heavy part is the offscreen PNG render (~100ms), acceptable on app
  /// foreground.
  static Future<void> refresh(StorageService storage) async {
    try {
      debugPrint('[widgets] refresh start');
      final dataset = await AppDataset.load();
      final favorites = storage.favoriteFighterIds;
      final now =
          DateTime.now().add(Duration(hours: storage.widgetTimeOffsetHours));
      await _refreshFaceoff(dataset, favorites);
      await _refreshLiving(dataset, favorites, now);
      debugPrint('[widgets] refresh done');
    } catch (e, st) {
      // Widget refresh must never take the app down. Next foreground retries.
      debugPrint('[widgets] refresh FAILED: $e\n$st');
    }
  }

  // ── Living Widget ──────────────────────────────────────────────────

  static Future<void> _refreshLiving(
    AppDataset dataset,
    Set<String> favorites,
    DateTime now,
  ) async {
    final snapshot = LivingStateMachine.resolve(
      now: now,
      events: dataset.events,
      favorites: favorites,
      fighterById: dataset.fighterById,
    );
    await _warmAssets([
      snapshot.fighter?.imageUrl ?? '',
      snapshot.opponent?.imageUrl ?? '',
    ]);

    final livingPath = await WidgetCapture.toPngFile(
      child: LivingFace(snapshot: snapshot, now: now),
      key: 'living_png',
      logicalSize: const Size(329, 158),
      pixelRatio: 3,
    );
    await HomeWidget.saveWidgetData<String>('living_png', livingPath);

    // Native chronometer: show inside the final 24h before the main card
    // (fight week / weigh-in / fight night pre-card).
    final event = snapshot.event;
    final showChrono = event != null &&
        (snapshot.state == LivingState.fightWeek ||
            snapshot.state == LivingState.weighInDay) &&
        event.date.difference(now) <= const Duration(hours: 24) &&
        event.date.isAfter(now);
    // Chronometer base uses elapsedRealtime on the device; ship the target
    // wall-clock time and let native convert.
    await HomeWidget.saveWidgetData<bool>('living_show_chrono', showChrono);
    await HomeWidget.saveWidgetData<int>(
        'living_target_ms', event?.date.millisecondsSinceEpoch ?? 0);

    final deeplink = switch (snapshot.state) {
      LivingState.corner when snapshot.fighter != null =>
        'walkout://fighter/${snapshot.fighter!.id}',
      LivingState.empty => 'walkout://home',
      _ when event != null => 'walkout://event/${event.id}',
      _ => 'walkout://home',
    };
    await HomeWidget.saveWidgetData<String>('living_deeplink', deeplink);
    await HomeWidget.updateWidget(qualifiedAndroidName: _livingProvider);
  }

  // ── Face-Off ───────────────────────────────────────────────────────

  static Future<void> _refreshFaceoff(
    AppDataset dataset,
    Set<String> favorites,
  ) async {
    final subject = _resolveFaceoffSubject(dataset, favorites);
    if (subject == null) return;
    final (event, bout, resultLabel) = subject;

    final byId = {for (final f in dataset.fighters) f.id: f};
    await _warmAssets([
      byId[bout.redCornerId]?.imageUrl ?? '',
      byId[bout.blueCornerId]?.imageUrl ?? '',
    ]);

    // 4x4 cell ≈ 329x345dp; render 3x for Pixel-class density.
    final path = await WidgetCapture.toPngFile(
      child: FaceoffFace(
        event: event,
        bout: bout,
        red: byId[bout.redCornerId],
        blue: byId[bout.blueCornerId],
        result: resultLabel,
      ),
      key: 'faceoff_png',
      logicalSize: const Size(333, 347),
      pixelRatio: 3,
    );

    await HomeWidget.saveWidgetData<String>('faceoff_png', path);
    await HomeWidget.saveWidgetData<String>(
        'faceoff_deeplink', 'walkout://event/${event.id}');
    await HomeWidget.updateWidget(qualifiedAndroidName: _faceoffProvider);
  }

  /// Subject: a corner fighter's upcoming bout when one exists (the poster
  /// should be personal), else the featured event's main event, else the most
  /// recent past main event with a FINAL ribbon.
  static (Event, Bout, String?)? _resolveFaceoffSubject(
    AppDataset dataset,
    Set<String> favorites,
  ) {
    final events = [...dataset.events]..sort((a, b) => a.date.compareTo(b.date));
    final upcoming =
        events.where((e) => e.status != EventStatus.past).toList();

    // Corner fighter's soonest bout.
    for (final e in upcoming) {
      for (final b in [...e.mainCard, ...e.prelims]) {
        if (favorites.contains(b.redCornerId) ||
            favorites.contains(b.blueCornerId)) {
          return (e, b, null);
        }
      }
    }
    // Featured event main event.
    final featured = upcoming.firstOrNull;
    final featuredMain = featured?.mainEvent;
    if (featured != null && featuredMain != null) {
      return (featured, featuredMain, null);
    }
    // Fallback: last past main event with result ribbon.
    final past = events.where((e) => e.status == EventStatus.past).lastOrNull;
    final pastMain = past?.mainEvent;
    if (past != null && pastMain != null) {
      final method =
          pastMain.method.isEmpty ? '' : ' · ${pastMain.method.toUpperCase()}';
      return (past, pastMain, 'FINAL$method');
    }
    return null;
  }

  // ── Asset pre-warming ──────────────────────────────────────────────

  /// renderFlutterWidget captures synchronously; async `Image.asset` loads
  /// wouldn't be painted yet (`!debugNeedsPaint` assertion). Resolving the
  /// asset images to completion here populates the global image cache so the
  /// faces paint their portraits synchronously during capture.
  static Future<void> _warmAssets(Iterable<String> assetPaths) async {
    final futures = <Future<void>>[];
    for (final path in assetPaths) {
      if (path.isEmpty) continue;
      final provider = AssetImage(path);
      final completer = Completer<void>();
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, __) {
          if (!completer.isCompleted) completer.complete();
          stream.removeListener(listener);
        },
        onError: (_, __) {
          if (!completer.isCompleted) completer.complete();
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      futures.add(completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      ));
    }
    await Future.wait(futures);
  }

  // ── Launch / deep links ────────────────────────────────────────────

  /// Converts a widget-launch URI (walkout://event/e_330) to an app route.
  static String? routeFromUri(Uri? uri) {
    if (uri == null) return null;
    final segs = uri.pathSegments;
    switch (uri.host) {
      case 'event':
        return segs.isEmpty ? '/events' : '/event/${segs.first}';
      case 'fighter':
        return segs.isEmpty ? '/home' : '/fighter/${segs.first}';
      case 'pickem':
        return '/pickem';
      default:
        return '/home';
    }
  }
}
