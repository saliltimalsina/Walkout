import 'package:flutter/widgets.dart';

import 'package:walkout/shared/data/app_dataset.dart';
import 'package:walkout/shared/models/models.dart';

import 'faces/concept_faces.dart';
import 'faces/faceoff_face.dart';
import 'faces/feed_faces.dart';

/// One renderable home-screen widget face: what to draw, at which logical
/// size, where a tap lands, and which assets must be warm before capture.
class FaceSpec {
  const FaceSpec({
    required this.key,
    required this.providerClass,
    required this.size,
    required this.deeplink,
    required this.face,
    this.assets = const [],
  });

  final String key; // prefs prefix: <key>_png / <key>_deeplink
  final String providerClass; // e.g. 'FightClockWidgetProvider'
  final Size size;
  final String deeplink;
  final Widget face;
  final List<String> assets;
}

/// Resolves dataset + favorites into the full board of widget faces.
/// Every face degrades honestly: missing data falls back to roster-wide
/// subjects (champions, featured event) rather than invented numbers.
abstract final class FaceRegistry {
  static const four2 = Size(329, 158);
  static const two2 = Size(158, 158);

  static List<FaceSpec> build({
    required AppDataset dataset,
    required Set<String> favorites,
    required DateTime now,
  }) {
    final byId = dataset.fighterById;
    final events = [...dataset.events]
      ..sort((a, b) => a.date.compareTo(b.date));
    final upcoming = events
        .where((e) => e.status != EventStatus.past && e.date.isAfter(now))
        .toList();
    final nextEvent = upcoming.firstWhere(
      (e) => e.mainEvent != null,
      orElse: () => upcoming.isEmpty ? events.last : upcoming.first,
    );

    // ── subjects ──
    final favs = favorites
        .map((id) => byId[id])
        .whereType<Fighter>()
        .toList()
      ..sort((a, b) =>
          (b.imageUrl.isEmpty ? 0 : 1) - (a.imageUrl.isEmpty ? 0 : 1));
    final champions =
        dataset.fighters.where((f) => f.isChampion && f.imageUrl.isNotEmpty);
    final hero = favs.firstOrNull ??
        champions.firstOrNull ??
        dataset.fighters.first;
    final champ = hero.isChampion
        ? hero
        : dataset.fighters
                .where((f) =>
                    f.isChampion && f.weightClass == hero.weightClass)
                .firstOrNull ??
            champions.firstOrNull ??
            hero;

    // Main-event bout with the richest roster data for tape/faceoff/pick.
    (Event, Bout, Fighter?, Fighter?) pickBout() {
      for (final e in upcoming) {
        for (final b in [...e.mainCard, ...e.prelims]) {
          if (favorites.contains(b.redCornerId) ||
              favorites.contains(b.blueCornerId)) {
            return (e, b, byId[b.redCornerId], byId[b.blueCornerId]);
          }
        }
      }
      for (final e in upcoming) {
        final m = e.mainEvent;
        if (m != null && byId[m.redCornerId] != null && byId[m.blueCornerId] != null) {
          return (e, m, byId[m.redCornerId], byId[m.blueCornerId]);
        }
      }
      final m = nextEvent.mainEvent ?? nextEvent.prelims.first;
      return (nextEvent, m, byId[m.redCornerId], byId[m.blueCornerId]);
    }

    final (boutEvent, bout, red, blue) = pickBout();
    final redName = red?.name ?? bout.redName;
    final blueName = blue?.name ?? bout.blueName;

    // Next-event main-event corners for the Fight Clock poster.
    final nextMain = nextEvent.mainEvent;
    final nextRed = nextMain != null ? byId[nextMain.redCornerId] : null;
    final nextBlue = nextMain != null ? byId[nextMain.blueCornerId] : null;

    // Real fight history from the bundled past events, newest first.
    List<String> historyOf(String fighterId) {
      final out = <String>[];
      for (final e in events.reversed) {
        if (e.status != EventStatus.past) continue;
        for (final b in [...e.mainCard, ...e.prelims]) {
          if (b.winnerId == null) continue;
          if (b.redCornerId == fighterId || b.blueCornerId == fighterId) {
            out.add(b.winnerId == fighterId ? 'W' : 'L');
          }
        }
      }
      return out;
    }

    // The bundled dataset only carries history for fighters on recent
    // cards; form faces follow the history, not the other way round.
    Fighter formSubject = hero;
    var formHistory = historyOf(hero.id);
    if (formHistory.isEmpty) {
      for (final f in [...favs, ...champions, ...dataset.fighters]) {
        final h = historyOf(f.id);
        if (h.isNotEmpty) {
          formSubject = f;
          formHistory = h;
          break;
        }
      }
    }
    var streak = 0;
    for (final r in formHistory) {
      if (r != 'W') break;
      streak++;
    }

    // Corner rail: favorites first, padded to four with champions so the
    // rail never renders one stretched tile.
    final cornerFighters = [
      ...favs,
      for (final c in champions)
        if (!favs.any((f) => f.id == c.id)) c,
    ].take(4).toList();
    String cornerSub(Fighter f) {
      for (final e in upcoming) {
        for (final b in [...e.mainCard, ...e.prelims]) {
          if (b.redCornerId == f.id || b.blueCornerId == f.id) {
            return (e.eventType.isNotEmpty ? e.eventType : e.name)
                .toUpperCase();
          }
        }
      }
      return f.record.display;
    }

    // Ladder for the hero's division.
    final ranking = dataset.rankings
            .where((r) => r.weightClass == hero.weightClass)
            .firstOrNull ??
        dataset.rankings.firstOrNull;
    final ladderRows = <LadderRow>[
      if (ranking != null && byId[ranking.championId] != null)
        LadderRow(
            rank: 'C', name: byId[ranking.championId]!.name, change: 0),
      if (ranking != null)
        for (final c in ranking.contenders.take(4))
          if (byId[c.fighterId] != null)
            LadderRow(
              rank: '${c.position}',
              name: byId[c.fighterId]!.name,
              change: c.change,
            ),
    ];

    String eventLink(Event e) => 'walkout://event/${e.id}';
    final heroLink = 'walkout://fighter/${hero.id}';

    String tagOf(Event e) =>
        (e.eventType.isNotEmpty ? e.eventType : e.name).toUpperCase();
    String lastNameOf(String n) => n.trim().split(RegExp(r'\s+')).last;

    // News — mirrors the in-app "Latest Stories": featured event + champions.
    final champsList = champions.toList();
    final newsItems = <NewsItem>[
      NewsItem(
        image: nextEvent.heroImage,
        title: '${nextEvent.subtitle} faceoffs: intensity at its peak',
        time: '3h ago',
      ),
      if (champsList.isNotEmpty)
        NewsItem(
          image: champsList[0].photo,
          title: "Behind the scenes of ${lastNameOf(champsList[0].name)}'s camp",
          time: '5h ago',
        ),
      if (champsList.length > 1)
        NewsItem(
          image: champsList[1].photo,
          title: '${lastNameOf(champsList[1].name)} in the spotlight',
          time: '7h ago',
        ),
    ];

    // Upcoming fight cards, soonest first.
    final upcomingItems = [
      for (final e in upcoming.take(3))
        UpcomingItem(
          tag: tagOf(e),
          subtitle: e.subtitle,
          date: e.date,
          daysAway: e.date.difference(now).inDays,
        ),
    ];

    // Fight-week schedule — typical UFC cadence derived from the event date.
    String clock(DateTime d) {
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
    }

    final mainCardAt = nextEvent.date;
    final prelimsAt = mainCardAt.subtract(const Duration(hours: 2));
    final weighInAt = DateTime(
      mainCardAt.year,
      mainCardAt.month,
      mainCardAt.day,
      18,
    ).subtract(const Duration(days: 1));
    final fightWeekSessions = [
      ScheduleSession(
          label: 'CEREMONIAL WEIGH-IN', time: clock(weighInAt), at: weighInAt),
      ScheduleSession(label: 'PRELIMS', time: clock(prelimsAt), at: prelimsAt),
      ScheduleSession(
          label: 'MAIN CARD', time: clock(mainCardAt), at: mainCardAt),
    ];

    return [
      FaceSpec(
        key: 'fight_clock',
        providerClass: 'FightClockWidgetProvider',
        size: four2,
        deeplink: eventLink(nextEvent),
        face: FightClockFace(
            event: nextEvent, now: now, red: nextRed, blue: nextBlue),
        assets: [nextRed?.photo ?? '', nextBlue?.photo ?? ''],
      ),
      FaceSpec(
        key: 'corner',
        providerClass: 'CornerWidgetProvider',
        size: four2,
        deeplink: 'walkout://home',
        face: CornerFace(
          title: favs.isNotEmpty ? 'YOUR CORNER' : 'THE CHAMPIONS',
          entries: [
            for (final f in cornerFighters.take(4))
              CornerEntry(fighter: f, sub: cornerSub(f)),
          ],
        ),
        assets: [for (final f in cornerFighters.take(4)) f.photo],
      ),
      FaceSpec(
        key: 'octagon_count',
        providerClass: 'OctagonCountWidgetProvider',
        size: two2,
        deeplink: eventLink(nextEvent),
        face: OctagonCountFace(event: nextEvent, now: now),
      ),
      FaceSpec(
        key: 'faceoff',
        providerClass: 'FaceoffWidgetProvider',
        size: four2,
        deeplink: eventLink(boutEvent),
        face: FaceoffFace(event: boutEvent, bout: bout, red: red, blue: blue),
        assets: [red?.photo ?? '', blue?.photo ?? ''],
      ),
      FaceSpec(
        key: 'last5',
        providerClass: 'Last5WidgetProvider',
        size: two2,
        deeplink: 'walkout://fighter/${formSubject.id}',
        face: Last5Face(fighter: formSubject, results: formHistory),
      ),
      FaceSpec(
        key: 'tape',
        providerClass: 'TapeWidgetProvider',
        size: four2,
        deeplink: eventLink(boutEvent),
        face: (red != null && blue != null)
            ? TapeFace(red: red, blue: blue)
            : FightClockFace(event: boutEvent, now: now),
        assets: [red?.photo ?? '', blue?.photo ?? ''],
      ),
      FaceSpec(
        key: 'belts',
        providerClass: 'BeltsWidgetProvider',
        size: two2,
        deeplink: 'walkout://fighter/${champ.id}',
        face: BeltsFace(champ: champ),
        assets: [champ.photo],
      ),
      FaceSpec(
        key: 'momentum',
        providerClass: 'MomentumWidgetProvider',
        size: two2,
        deeplink: 'walkout://fighter/${formSubject.id}',
        face: MomentumFace(fighter: formSubject, streak: streak),
      ),
      if (ladderRows.isNotEmpty)
        FaceSpec(
          key: 'ladder',
          providerClass: 'LadderWidgetProvider',
          size: four2,
          deeplink: 'walkout://home',
          face: LadderFace(
            division: hero.weightClass.label,
            rows: ladderRows,
          ),
        ),
      FaceSpec(
        key: 'ticket',
        providerClass: 'TicketWidgetProvider',
        size: two2,
        deeplink: eventLink(nextEvent),
        face: TicketFace(event: nextEvent),
      ),
      FaceSpec(
        key: 'hype',
        providerClass: 'HypeWidgetProvider',
        size: two2,
        deeplink: eventLink(nextEvent),
        face: HypeFace(event: nextEvent),
      ),
      FaceSpec(
        key: 'finish_dna',
        providerClass: 'FinishDnaWidgetProvider',
        size: two2,
        deeplink: heroLink,
        face: FinishDnaFace(fighter: hero),
      ),
      FaceSpec(
        key: 'radar',
        providerClass: 'RadarWidgetProvider',
        size: two2,
        deeplink: heroLink,
        face: RadarFace(fighter: hero),
      ),
      FaceSpec(
        key: 'journey',
        providerClass: 'JourneyWidgetProvider',
        size: four2,
        deeplink: heroLink,
        face: JourneyFace(fighter: hero),
      ),
      FaceSpec(
        key: 'prediction',
        providerClass: 'PredictionWidgetProvider',
        size: four2,
        deeplink: 'walkout://pickem',
        face: PredictionFace(
          event: boutEvent,
          redName: redName,
          blueName: blueName,
        ),
      ),
      FaceSpec(
        key: 'news',
        providerClass: 'NewsWidgetProvider',
        size: four2,
        deeplink: 'walkout://home',
        face: NewsFace(items: newsItems),
        assets: [
          nextEvent.heroImage,
          for (final c in champsList.take(2)) c.photo,
        ],
      ),
      FaceSpec(
        key: 'upcoming',
        providerClass: 'UpcomingWidgetProvider',
        size: four2,
        deeplink: 'walkout://events',
        face: UpcomingFace(items: upcomingItems),
      ),
      FaceSpec(
        key: 'fightweek',
        providerClass: 'FightWeekWidgetProvider',
        size: four2,
        deeplink: eventLink(nextEvent),
        face: FightWeekScheduleFace(
          eventTag: tagOf(nextEvent),
          sessions: fightWeekSessions,
          now: now,
        ),
      ),
    ];
  }

  /// Fighter-subject widget keys the user can point at any fighter via the
  /// Android widget-config screen.
  static const configurableKeys = {
    'belts',
    'momentum',
    'finish_dna',
    'radar',
    'last5',
    'journey',
  };

  /// Face key → Android provider class, for the configurable widgets.
  static const configurableProviders = {
    'belts': 'BeltsWidgetProvider',
    'momentum': 'MomentumWidgetProvider',
    'finish_dna': 'FinishDnaWidgetProvider',
    'radar': 'RadarWidgetProvider',
    'last5': 'Last5WidgetProvider',
    'journey': 'JourneyWidgetProvider',
  };

  /// Builds a single configurable face for [key] pointed at [fighter]. Returns
  /// null for unknown keys. Used to render per-widget-instance PNGs.
  static ({Widget face, List<String> assets, String deeplink, Size size})?
      configurableFace({
    required String key,
    required Fighter fighter,
    required AppDataset dataset,
    required DateTime now,
  }) {
    final events = [...dataset.events]
      ..sort((a, b) => a.date.compareTo(b.date));
    List<String> historyOf(String fighterId) {
      final out = <String>[];
      for (final e in events.reversed) {
        if (e.status != EventStatus.past) continue;
        for (final b in [...e.mainCard, ...e.prelims]) {
          if (b.winnerId == null) continue;
          if (b.redCornerId == fighterId || b.blueCornerId == fighterId) {
            out.add(b.winnerId == fighterId ? 'W' : 'L');
          }
        }
      }
      return out;
    }

    final hist = historyOf(fighter.id);
    var streak = 0;
    for (final r in hist) {
      if (r != 'W') break;
      streak++;
    }
    final link = 'walkout://fighter/${fighter.id}';

    switch (key) {
      case 'belts':
        return (
          face: BeltsFace(champ: fighter),
          assets: [fighter.photo],
          deeplink: link,
          size: two2,
        );
      case 'momentum':
        return (
          face: MomentumFace(fighter: fighter, streak: streak),
          assets: const <String>[],
          deeplink: link,
          size: two2,
        );
      case 'finish_dna':
        return (
          face: FinishDnaFace(fighter: fighter),
          assets: const <String>[],
          deeplink: link,
          size: two2,
        );
      case 'radar':
        return (
          face: RadarFace(fighter: fighter),
          assets: const <String>[],
          deeplink: link,
          size: two2,
        );
      case 'last5':
        return (
          face: Last5Face(fighter: fighter, results: hist),
          assets: const <String>[],
          deeplink: link,
          size: two2,
        );
      case 'journey':
        return (
          face: JourneyFace(fighter: fighter),
          assets: const <String>[],
          deeplink: link,
          size: four2,
        );
      default:
        return null;
    }
  }
}
