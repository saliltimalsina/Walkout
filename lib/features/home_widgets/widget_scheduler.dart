import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'package:walkout/shared/data/app_dataset.dart';
import 'package:walkout/shared/models/event.dart';

import 'application/living_state.dart';

/// Background render scheduling for the home-screen widgets. Two layers:
/// a 30-minute periodic net so PNGs can never go stale for long, and a single
/// one-off task re-armed at every refresh to land exactly on the next phase
/// boundary (fight week → weigh-in → fight night → live-window close → …).
/// All no-ops off Android so `flutter test` and iOS builds stay untouched.
abstract final class WidgetScheduler {
  const WidgetScheduler._();

  static const periodicTask = 'walkout.widgets.periodic';
  static const transitionTask = 'walkout.widgets.transition';

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  /// The safety net: refresh every 30 minutes even if the app never opens.
  static Future<void> registerPeriodic() async {
    if (!_supported) return;
    await Workmanager().registerPeriodicTask(
      periodicTask,
      periodicTask,
      frequency: const Duration(minutes: 30),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }

  /// Arms ONE one-off render at the soonest upcoming state boundary. Each run
  /// of the resulting task re-arms the next boundary via the refresh tail —
  /// a self-perpetuating chain, with the periodic task as fallback if a
  /// one-off is ever dropped.
  static Future<void> scheduleNextTransition(
    AppDataset dataset,
    DateTime now,
  ) async {
    if (!_supported) return;

    DateTime? next;
    void consider(DateTime t) {
      if (t.isAfter(now) && (next == null || t.isBefore(next!))) next = t;
    }

    for (final e in dataset.events) {
      // Only events near their window matter; the rest change too slowly
      // for anything but the periodic net.
      if (e.date.difference(now).abs() > const Duration(days: 8)) continue;
      PhaseSchedule(e.date).boundariesAfter(now).forEach(consider);
      consider(e.date.add(Event.liveTail)); // LIVE → ended
      consider(e.date.add(const Duration(hours: 24))); // result → aftermath
      consider(e.date.add(const Duration(hours: 72))); // aftermath → corner
    }
    if (next == null) return;

    await Workmanager().registerOneOffTask(
      transitionTask,
      transitionTask,
      // Small pad so the render lands after the boundary, not on it.
      initialDelay: next!.difference(now) + const Duration(seconds: 30),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}
