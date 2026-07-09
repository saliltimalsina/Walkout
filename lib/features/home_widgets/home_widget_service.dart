import 'dart:ui' show Size;

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import 'package:walkout/core/services/storage_service.dart';
import 'package:walkout/shared/data/app_dataset.dart';
import 'package:walkout/shared/models/models.dart';

import 'faces/faceoff_face.dart';

/// Bridges app data to the native home-screen widgets: resolves the subject,
/// renders faces to PNG and pushes update broadcasts.
///
/// v1 scope: Face-Off (4x4). The Living Widget engine builds on the same
/// pipeline.
class HomeWidgetService {
  const HomeWidgetService._();

  /// Android provider class names (must match the Kotlin receivers).
  static const _faceoffProvider = 'FaceoffWidgetProvider';

  /// Renders + publishes all widgets. Cheap when nothing changed — the
  /// heavy part is the offscreen PNG render (~100ms), acceptable on app
  /// foreground.
  static Future<void> refresh(StorageService storage) async {
    try {
      final dataset = await AppDataset.load();
      final favorites = storage.favoriteFighterIds;
      await _refreshFaceoff(dataset, favorites);
    } catch (_) {
      // Widget refresh must never take the app down. Next foreground retries.
    }
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

    // 4x4 cell ≈ 329x345dp; render 3x for Pixel-class density.
    await HomeWidget.renderFlutterWidget(
      FaceoffFace(
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

    await HomeWidget.saveWidgetData<String>(
        'faceoff_deeplink', 'walkout://event/${event.id}');
    await HomeWidget.updateWidget(androidName: _faceoffProvider);
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
