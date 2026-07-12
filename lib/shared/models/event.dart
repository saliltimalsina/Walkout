// freezed applies constructor-param @JsonKey to the generated field.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'bout.dart';

part 'event.freezed.dart';
part 'event.g.dart';

enum EventStatus { upcoming, live, past }

/// Where an event sits in its own timeline, derived from the clock — the
/// single source of truth for "is this live". The stored [Event.status] is a
/// pipeline hint only and goes stale between ingest runs.
enum EventPhase { upcoming, prelims, mainCard, ended }

/// Scraper/ingest dates are UTC wall-clock; historical data omits the 'Z'.
/// Reinterpret naive strings as UTC, then convert to local so every display
/// call site (`date.day`, `.timeLabel`, …) shows the viewer's wall time.
DateTime _eventDateFromJson(String v) {
  var d = DateTime.parse(v);
  if (!d.isUtc) {
    d = DateTime.utc(
        d.year, d.month, d.day, d.hour, d.minute, d.second, d.millisecond);
  }
  return d.toLocal();
}

String _eventDateToJson(DateTime d) => d.toUtc().toIso8601String();

@freezed
abstract class Event with _$Event {
  const Event._();

  const factory Event({
    required String id,
    required String name,
    @Default('') String subtitle, // e.g. "Jones vs Aspinall"
    @JsonKey(fromJson: _eventDateFromJson, toJson: _eventDateToJson)
    required DateTime date,
    @Default('') String venue,
    @Default('') String location,
    @Default('') String posterUrl,

    /// Full-bleed cover/hero image (bundled asset path) for the home hero.
    @Default('') String heroImage,

    /// Headline label, e.g. "UFC Fight Night" or "UFC 328".
    @Default('') String eventType,

    /// Pipeline hint written by ingest/seed. Do NOT use for logic — it only
    /// updates when data is republished. Use [statusAt]/[isLiveAt] instead.
    @Default(EventStatus.upcoming) EventStatus status,
    @Default(<Bout>[]) List<Bout> mainCard,
    @Default(<Bout>[]) List<Bout> prelims,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Bout? get mainEvent =>
      mainCard.where((b) => b.isMainEvent).firstOrNull ?? mainCard.firstOrNull;

  int get totalBouts => mainCard.length + prelims.length;

  /// Prelims start this long before the main-card walk ([date]). Matches
  /// `PhaseSchedule.earlyPrelims` so app UI and widgets agree on fight night.
  static const prelimsLead = Duration(hours: 4);

  /// LIVE dies this long after the main-card walk unless the main-event
  /// result lands first. Worst-case 5-bout card is ~3.5h; 6h adds margin.
  static const liveTail = Duration(hours: 6);

  /// Time-derived phase: upcoming → prelims → mainCard → ended. Result data
  /// ([mainEvent].winnerId) ends the event early when it arrives.
  EventPhase phaseAt(DateTime now) {
    if (mainEvent?.winnerId != null && now.isAfter(date)) {
      return EventPhase.ended;
    }
    if (now.isBefore(date.subtract(prelimsLead))) return EventPhase.upcoming;
    if (now.isBefore(date)) return EventPhase.prelims;
    if (now.isBefore(date.add(liveTail))) return EventPhase.mainCard;
    return EventPhase.ended;
  }

  bool isLiveAt(DateTime now) {
    final p = phaseAt(now);
    return p == EventPhase.prelims || p == EventPhase.mainCard;
  }

  /// Time-derived status — what the stored [status] should be right now.
  EventStatus statusAt(DateTime now) => switch (phaseAt(now)) {
        EventPhase.upcoming => EventStatus.upcoming,
        EventPhase.ended => EventStatus.past,
        _ => EventStatus.live,
      };

  /// The bout most likely in the cage right now: while the event is live,
  /// the first bout in run order (prelims bottom-up, then main card
  /// bottom-up) that has no result yet. Null outside the live window.
  Bout? liveBoutAt(DateTime now) {
    if (!isLiveAt(now)) return null;
    for (final b in [...prelims.reversed, ...mainCard.reversed]) {
      if (b.winnerId == null) return b;
    }
    return null;
  }
}
