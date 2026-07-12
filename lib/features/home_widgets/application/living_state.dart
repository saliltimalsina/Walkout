import 'package:walkout/shared/models/models.dart';

/// The Living Widget's states — one widget that transforms with the calendar.
enum LivingState {
  /// Quiet week: favorite fighter standing presence.
  corner,

  /// Fight announced, more than 7 days out: mini face-off.
  booked,

  /// D-6 … D-2: countdown + daily phase label.
  fightWeek,

  /// D-1: weigh-in day, pick pressure.
  weighInDay,

  /// D-0 from early-prelims time until result data lands.
  fightNight,

  /// First 24h after result data exists.
  result,

  /// 24–72h after result: record + ranking movement, then decay to corner.
  aftermath,

  /// No favorites and no upcoming events.
  empty,
}

/// Phase labels inside fight week, derived by convention from the main-card
/// time (`event.date`). Schedule, not live fact.
enum FightWeekPhase {
  mediaDay('MEDIA DAY'),
  openWorkouts('OPEN WORKOUTS'),
  weighIns('WEIGH-INS'),
  earlyPrelims('EARLY PRELIMS'),
  prelims('PRELIMS'),
  mainCard('MAIN CARD');

  const FightWeekPhase(this.label);
  final String label;
}

/// Everything a face needs to render, resolved once per refresh.
class LivingSnapshot {
  const LivingSnapshot({
    required this.state,
    this.fighter,
    this.opponent,
    this.event,
    this.bout,
    this.phase,
    this.won,
  });

  final LivingState state;

  /// The subject fighter (corner favorite) when one drives the widget.
  final Fighter? fighter;

  /// The subject's opponent for booked/fight-week faces.
  final Fighter? opponent;

  final Event? event;
  final Bout? bout;

  /// Only set during [LivingState.fightWeek]/[LivingState.fightNight].
  final FightWeekPhase? phase;

  /// Only set for result/aftermath.
  final bool? won;
}

/// Derived phase boundary times for an event (main card walk = event.date).
class PhaseSchedule {
  PhaseSchedule(this.mainCard);

  final DateTime mainCard;

  DateTime get fightWeekStart => _dayStart(mainCard.subtract(const Duration(days: 6)));
  DateTime get mediaDay => _dayStart(mainCard.subtract(const Duration(days: 3)));
  DateTime get openWorkouts => _dayStart(mainCard.subtract(const Duration(days: 2)));
  DateTime get weighInDay => _dayStart(mainCard.subtract(const Duration(days: 1)));
  // Shared with the app UI's live window (Event.prelimsLead) so the widgets
  // and the events screen agree on when fight night starts.
  DateTime get earlyPrelims => mainCard.subtract(Event.prelimsLead);
  DateTime get prelims => mainCard.subtract(const Duration(hours: 2));

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  FightWeekPhase phaseAt(DateTime now) {
    if (now.isAfter(mainCard)) return FightWeekPhase.mainCard;
    if (now.isAfter(prelims)) return FightWeekPhase.prelims;
    if (now.isAfter(earlyPrelims)) return FightWeekPhase.earlyPrelims;
    if (now.isAfter(weighInDay)) return FightWeekPhase.weighIns;
    if (now.isAfter(openWorkouts)) return FightWeekPhase.openWorkouts;
    return FightWeekPhase.mediaDay;
  }

  /// Upcoming boundaries after [now] — the alarm/timeline entries.
  List<DateTime> boundariesAfter(DateTime now) => [
        fightWeekStart,
        mediaDay,
        openWorkouts,
        weighInDay,
        earlyPrelims,
        prelims,
        mainCard,
      ].where((t) => t.isAfter(now)).toList();
}

/// Pure resolver: state = f(now, events, favorites). `now` is injected so the
/// dev time-travel panel and unit tests can drive every state.
class LivingStateMachine {
  const LivingStateMachine._();

  static LivingSnapshot resolve({
    required DateTime now,
    required List<Event> events,
    required Set<String> favorites,
    required Map<String, Fighter> fighterById,
  }) {
    final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));

    // Subject: favorite with the soonest bout (upcoming first, then recent past
    // for result/aftermath windows).
    final booking = _findBooking(sorted, favorites, now);

    if (booking != null) {
      final (event, bout, favId) = booking;
      final fighter = fighterById[favId];
      final oppId =
          bout.redCornerId == favId ? bout.blueCornerId : bout.redCornerId;
      final opponent = fighterById[oppId];
      final schedule = PhaseSchedule(event.date);

      final resultKnown = bout.winnerId != null;
      if (resultKnown && now.isAfter(event.date)) {
        final since = now.difference(event.date);
        final won = bout.winnerId == favId;
        if (since <= const Duration(hours: 24)) {
          return LivingSnapshot(
            state: LivingState.result,
            fighter: fighter,
            opponent: opponent,
            event: event,
            bout: bout,
            won: won,
          );
        }
        if (since <= const Duration(hours: 72)) {
          return LivingSnapshot(
            state: LivingState.aftermath,
            fighter: fighter,
            opponent: opponent,
            event: event,
            bout: bout,
            won: won,
          );
        }
        // Older than 72h → falls through to corner below.
      } else if (now.isAfter(schedule.earlyPrelims) &&
          now.isBefore(event.date.add(const Duration(hours: 24)))) {
        return LivingSnapshot(
          state: LivingState.fightNight,
          fighter: fighter,
          opponent: opponent,
          event: event,
          bout: bout,
          phase: schedule.phaseAt(now),
        );
      } else if (now.isAfter(schedule.weighInDay) &&
          now.isBefore(schedule.earlyPrelims)) {
        return LivingSnapshot(
          state: LivingState.weighInDay,
          fighter: fighter,
          opponent: opponent,
          event: event,
          bout: bout,
          phase: FightWeekPhase.weighIns,
        );
      } else if (now.isAfter(schedule.fightWeekStart) &&
          now.isBefore(schedule.weighInDay)) {
        return LivingSnapshot(
          state: LivingState.fightWeek,
          fighter: fighter,
          opponent: opponent,
          event: event,
          bout: bout,
          phase: schedule.phaseAt(now),
        );
      } else if (now.isBefore(schedule.fightWeekStart)) {
        return LivingSnapshot(
          state: LivingState.booked,
          fighter: fighter,
          opponent: opponent,
          event: event,
          bout: bout,
        );
      }
    }

    // No live booking: corner presence with the first favorite, else featured.
    final firstFav =
        favorites.map((id) => fighterById[id]).whereType<Fighter>().firstOrNull;
    if (firstFav != null) {
      final next = _nextBookingFor(sorted, firstFav.id, now);
      return LivingSnapshot(
        state: LivingState.corner,
        fighter: firstFav,
        event: next?.$1,
        bout: next?.$2,
      );
    }

    final featured =
        sorted.where((e) => e.date.isAfter(now)).firstOrNull;
    final main = featured?.mainEvent;
    if (featured != null && main != null) {
      return LivingSnapshot(
        state: LivingState.booked,
        fighter: fighterById[main.redCornerId],
        opponent: fighterById[main.blueCornerId],
        event: featured,
        bout: main,
      );
    }

    return const LivingSnapshot(state: LivingState.empty);
  }

  /// Favorite booking whose window (booked → aftermath) contains or follows
  /// [now]; the soonest such wins.
  static (Event, Bout, String)? _findBooking(
    List<Event> sorted,
    Set<String> favorites,
    DateTime now,
  ) {
    (Event, Bout, String)? best;
    for (final e in sorted) {
      // Ignore events whose aftermath window has fully passed.
      if (e.date.add(const Duration(hours: 72)).isBefore(now)) continue;
      for (final b in [...e.mainCard, ...e.prelims]) {
        final fav = favorites.contains(b.redCornerId)
            ? b.redCornerId
            : favorites.contains(b.blueCornerId)
                ? b.blueCornerId
                : null;
        if (fav == null) continue;
        if (best == null || e.date.isBefore(best.$1.date)) {
          best = (e, b, fav);
        }
      }
    }
    return best;
  }

  static (Event, Bout)? _nextBookingFor(
    List<Event> sorted,
    String fighterId,
    DateTime now,
  ) {
    for (final e in sorted) {
      if (e.date.isBefore(now)) continue;
      for (final b in [...e.mainCard, ...e.prelims]) {
        if (b.redCornerId == fighterId || b.blueCornerId == fighterId) {
          return (e, b);
        }
      }
    }
    return null;
  }
}
