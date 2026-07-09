import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import 'package:walkout/core/services/storage_service.dart';
import 'package:walkout/shared/data/app_dataset.dart';

import 'application/living_state.dart';
import 'face_registry.dart';
import 'faces/living_face.dart';
import 'widget_capture.dart';

/// Bridges app data to the native home-screen widgets: resolves subjects,
/// renders every face on the board to PNG and pushes update broadcasts.
class HomeWidgetService {
  const HomeWidgetService._();

  /// Fully-qualified Android provider names (subpackage `widgets`).
  static const _providerPkg = 'com.walkout.walkout.widgets';
  static const _livingProvider = '$_providerPkg.LivingWidgetProvider';

  /// Renders + publishes all widgets. Cheap when nothing changed — the
  /// heavy part is the offscreen PNG render (~100ms), acceptable on app
  /// foreground.
  static Future<void> refresh(StorageService storage) async {
    try {
      final dataset = await AppDataset.load();
      final favorites = storage.favoriteFighterIds;
      final now =
          DateTime.now().add(Duration(hours: storage.widgetTimeOffsetHours));
      await _refreshLiving(dataset, favorites, now);
      await _refreshBoard(dataset, favorites, now);
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

  // ── The board: every concept face ──────────────────────────────────

  static Future<void> _refreshBoard(
    AppDataset dataset,
    Set<String> favorites,
    DateTime now,
  ) async {
    final specs = FaceRegistry.build(
      dataset: dataset,
      favorites: favorites,
      now: now,
    );
    for (final spec in specs) {
      try {
        await _warmAssets(spec.assets);
        final path = await WidgetCapture.toPngFile(
          child: spec.face,
          key: '${spec.key}_png',
          logicalSize: spec.size,
          pixelRatio: 3,
        );
        await HomeWidget.saveWidgetData<String>('${spec.key}_png', path);
        await HomeWidget.saveWidgetData<String>(
            '${spec.key}_deeplink', spec.deeplink);
        await HomeWidget.updateWidget(
            qualifiedAndroidName: '$_providerPkg.${spec.providerClass}');
      } catch (e) {
        // One bad face must not sink the rest of the board.
        debugPrint('[widgets] ${spec.key} FAILED: $e');
      }
    }
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
