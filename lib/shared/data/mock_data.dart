import '../models/bout.dart';
import '../models/event.dart';
import '../models/fight_record.dart';
import '../models/fighter.dart';
import '../models/fighter_stats.dart';
import '../models/notification_item.dart';
import '../models/ranking.dart';
import '../models/user_profile.dart';
import '../models/weight_class.dart';

/// In-memory dataset backing the repository layer while [AppConstants.useMockData]
/// is true. Fighters are referenced by id from events and rankings.
///
/// Images are intentionally left blank so the UI renders initials/gradient
/// fallbacks and the app looks complete fully offline.
abstract final class MockData {
  const MockData._();

  static final List<Fighter> fighters = [
    // ── Lightweight ─────────────────────────────────────────────
    const Fighter(
      id: 'f_makhachev',
      name: 'Islam Makhachev',
      nickname: '',
      weightClass: WeightClass.lightweight,
      country: 'Russia',
      flag: '🇷🇺',
      record: FightRecord(wins: 26, losses: 1),
      isChampion: true,
      heightCm: 178,
      reachCm: 178,
      age: 33,
      stance: 'Southpaw',
      winsByKo: 5,
      winsBySub: 11,
      winsByDec: 10,
      stats: FighterStats(
        sigStrikesPerMin: 3.9,
        strikingAccuracy: 60,
        sigStrikesAbsorbedPerMin: 1.6,
        strikingDefense: 60,
        takedownAvg: 3.6,
        takedownAccuracy: 61,
        takedownDefense: 89,
        submissionAvg: 1.1,
      ),
      bio:
          'Dagestani grappling phenom and one of the most dominant lightweight '
          'champions in history, known for suffocating top control and slick submissions.',
    ),
    const Fighter(
      id: 'f_oliveira',
      name: 'Charles Oliveira',
      nickname: 'do Bronx',
      weightClass: WeightClass.lightweight,
      country: 'Brazil',
      flag: '🇧🇷',
      record: FightRecord(wins: 35, losses: 10, noContests: 1),
      rankingPosition: 1,
      heightCm: 178,
      reachCm: 187,
      age: 35,
      stance: 'Orthodox',
      winsByKo: 10,
      winsBySub: 21,
      winsByDec: 4,
      stats: FighterStats(
        sigStrikesPerMin: 3.5,
        strikingAccuracy: 54,
        sigStrikesAbsorbedPerMin: 3.9,
        strikingDefense: 52,
        takedownAvg: 2.0,
        takedownAccuracy: 40,
        takedownDefense: 51,
        submissionAvg: 2.9,
      ),
      bio:
          'The UFC\'s all-time submission and finish leader, an ever-dangerous '
          'finisher who can end a fight from anywhere.',
    ),
    const Fighter(
      id: 'f_gaethje',
      name: 'Justin Gaethje',
      nickname: 'The Highlight',
      weightClass: WeightClass.lightweight,
      country: 'United States',
      flag: '🇺🇸',
      record: FightRecord(wins: 25, losses: 5),
      rankingPosition: 2,
      heightCm: 180,
      reachCm: 178,
      age: 36,
      stance: 'Orthodox',
      winsByKo: 20,
      winsBySub: 0,
      winsByDec: 5,
      stats: FighterStats(
        sigStrikesPerMin: 6.4,
        strikingAccuracy: 57,
        sigStrikesAbsorbedPerMin: 6.0,
        strikingDefense: 58,
        takedownAvg: 0.9,
        takedownAccuracy: 60,
        takedownDefense: 82,
        submissionAvg: 0.1,
      ),
      bio:
          'A relentless pressure striker whose leg kicks and knockout power make '
          'every fight a candidate for Fight of the Night.',
    ),
    const Fighter(
      id: 'f_tsarukyan',
      name: 'Arman Tsarukyan',
      nickname: 'Ahalkalakets',
      weightClass: WeightClass.lightweight,
      country: 'Armenia',
      flag: '🇦🇲',
      record: FightRecord(wins: 22, losses: 3),
      rankingPosition: 3,
      heightCm: 173,
      reachCm: 180,
      age: 28,
      stance: 'Orthodox',
      winsByKo: 6,
      winsBySub: 6,
      winsByDec: 10,
      stats: FighterStats(
        sigStrikesPerMin: 4.7,
        strikingAccuracy: 51,
        sigStrikesAbsorbedPerMin: 3.1,
        strikingDefense: 57,
        takedownAvg: 3.9,
        takedownAccuracy: 45,
        takedownDefense: 76,
        submissionAvg: 0.9,
      ),
      bio:
          'A complete lightweight with elite wrestling and improving hands, '
          'considered the top contender in a stacked division.',
    ),

    // ── Welterweight ────────────────────────────────────────────
    const Fighter(
      id: 'f_dellamaddalena',
      name: 'Jack Della Maddalena',
      nickname: 'JDM',
      weightClass: WeightClass.welterweight,
      country: 'Australia',
      flag: '🇦🇺',
      record: FightRecord(wins: 18, losses: 2),
      isChampion: true,
      heightCm: 180,
      reachCm: 185,
      age: 28,
      stance: 'Orthodox',
      winsByKo: 12,
      winsBySub: 3,
      winsByDec: 3,
      stats: FighterStats(
        sigStrikesPerMin: 6.1,
        strikingAccuracy: 51,
        sigStrikesAbsorbedPerMin: 4.9,
        strikingDefense: 53,
        takedownAvg: 0.4,
        takedownAccuracy: 33,
        takedownDefense: 66,
        submissionAvg: 0.3,
      ),
      bio:
          'A slick boxer with fight-ending power in both hands and an iron chin, '
          'JDM climbed the welterweight ranks on a long win streak.',
    ),
    const Fighter(
      id: 'f_muhammad',
      name: 'Belal Muhammad',
      nickname: 'Remember the Name',
      weightClass: WeightClass.welterweight,
      country: 'United States',
      flag: '🇺🇸',
      record: FightRecord(wins: 24, losses: 4, noContests: 1),
      rankingPosition: 1,
      heightCm: 180,
      reachCm: 183,
      age: 37,
      stance: 'Orthodox',
      winsByKo: 5,
      winsBySub: 2,
      winsByDec: 17,
      stats: FighterStats(
        sigStrikesPerMin: 4.3,
        strikingAccuracy: 47,
        sigStrikesAbsorbedPerMin: 3.0,
        strikingDefense: 58,
        takedownAvg: 2.6,
        takedownAccuracy: 41,
        takedownDefense: 74,
        submissionAvg: 0.4,
      ),
      bio:
          'A high-volume, high-pace pressure fighter whose cardio and wrestling '
          'grind opponents down over five rounds.',
    ),
    const Fighter(
      id: 'f_brady',
      name: 'Sean Brady',
      nickname: '',
      weightClass: WeightClass.welterweight,
      country: 'United States',
      flag: '🇺🇸',
      record: FightRecord(wins: 18, losses: 1),
      rankingPosition: 2,
      heightCm: 178,
      reachCm: 183,
      age: 32,
      stance: 'Orthodox',
      winsByKo: 4,
      winsBySub: 6,
      winsByDec: 8,
      stats: FighterStats(
        sigStrikesPerMin: 3.7,
        strikingAccuracy: 49,
        sigStrikesAbsorbedPerMin: 2.8,
        strikingDefense: 55,
        takedownAvg: 3.2,
        takedownAccuracy: 44,
        takedownDefense: 80,
        submissionAvg: 1.3,
      ),
      bio:
          'A grappling-heavy pressure fighter with a smothering top game and '
          'relentless chain wrestling.',
    ),

    // ── Middleweight ────────────────────────────────────────────
    const Fighter(
      id: 'f_dupessa',
      name: 'Dricus du Plessis',
      nickname: 'Stillknocks',
      weightClass: WeightClass.middleweight,
      country: 'South Africa',
      flag: '🇿🇦',
      record: FightRecord(wins: 23, losses: 2),
      isChampion: true,
      heightCm: 185,
      reachCm: 193,
      age: 31,
      stance: 'Orthodox',
      winsByKo: 12,
      winsBySub: 8,
      winsByDec: 3,
      stats: FighterStats(
        sigStrikesPerMin: 5.5,
        strikingAccuracy: 45,
        sigStrikesAbsorbedPerMin: 4.2,
        strikingDefense: 52,
        takedownAvg: 2.4,
        takedownAccuracy: 40,
        takedownDefense: 70,
        submissionAvg: 1.0,
      ),
      bio:
          'An unorthodox, unpredictable pressure fighter with a granite chin and '
          'a knack for finding finishes from awkward angles.',
    ),
    const Fighter(
      id: 'f_chimaev',
      name: 'Khamzat Chimaev',
      nickname: 'Borz',
      weightClass: WeightClass.middleweight,
      country: 'UAE',
      flag: '🇦🇪',
      record: FightRecord(wins: 14, losses: 0),
      rankingPosition: 1,
      heightCm: 188,
      reachCm: 190,
      age: 31,
      stance: 'Orthodox',
      winsByKo: 5,
      winsBySub: 6,
      winsByDec: 3,
      stats: FighterStats(
        sigStrikesPerMin: 4.8,
        strikingAccuracy: 62,
        sigStrikesAbsorbedPerMin: 1.2,
        strikingDefense: 64,
        takedownAvg: 6.1,
        takedownAccuracy: 56,
        takedownDefense: 85,
        submissionAvg: 1.4,
      ),
      bio:
          'An undefeated wrestling juggernaut who overwhelms opponents with '
          'pressure, pace, and suffocating top control.',
    ),

    // ── Heavyweight ─────────────────────────────────────────────
    const Fighter(
      id: 'f_aspinall',
      name: 'Tom Aspinall',
      nickname: '',
      weightClass: WeightClass.heavyweight,
      country: 'England',
      flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      record: FightRecord(wins: 15, losses: 3),
      isChampion: true,
      heightCm: 196,
      reachCm: 198,
      age: 32,
      stance: 'Orthodox',
      winsByKo: 9,
      winsBySub: 5,
      winsByDec: 1,
      stats: FighterStats(
        sigStrikesPerMin: 6.9,
        strikingAccuracy: 63,
        sigStrikesAbsorbedPerMin: 3.5,
        strikingDefense: 55,
        takedownAvg: 1.8,
        takedownAccuracy: 50,
        takedownDefense: 66,
        submissionAvg: 1.7,
      ),
      bio:
          'The fastest heavyweight in the division — rare speed, footwork, and '
          'grappling for a big man, with legitimate finishing power.',
    ),
    const Fighter(
      id: 'f_pereira',
      name: 'Alex Pereira',
      nickname: 'Poatan',
      weightClass: WeightClass.lightHeavyweight,
      country: 'Brazil',
      flag: '🇧🇷',
      record: FightRecord(wins: 12, losses: 3),
      isChampion: true,
      heightCm: 193,
      reachCm: 200,
      age: 37,
      stance: 'Orthodox',
      winsByKo: 9,
      winsBySub: 1,
      winsByDec: 2,
      stats: FighterStats(
        sigStrikesPerMin: 4.8,
        strikingAccuracy: 60,
        sigStrikesAbsorbedPerMin: 4.0,
        strikingDefense: 57,
        takedownAvg: 0.2,
        takedownAccuracy: 25,
        takedownDefense: 60,
        submissionAvg: 0.1,
      ),
      bio:
          'A former two-division kickboxing champion whose left hook and calf '
          'kicks have made him one of the most feared strikers in MMA.',
    ),
    const Fighter(
      id: 'f_ankalaev',
      name: 'Magomed Ankalaev',
      nickname: '',
      weightClass: WeightClass.lightHeavyweight,
      country: 'Russia',
      flag: '🇷🇺',
      record: FightRecord(wins: 21, losses: 1, draws: 1),
      rankingPosition: 1,
      heightCm: 191,
      reachCm: 190,
      age: 33,
      stance: 'Orthodox',
      winsByKo: 8,
      winsBySub: 5,
      winsByDec: 8,
      stats: FighterStats(
        sigStrikesPerMin: 3.9,
        strikingAccuracy: 55,
        sigStrikesAbsorbedPerMin: 2.2,
        strikingDefense: 60,
        takedownAvg: 1.5,
        takedownAccuracy: 48,
        takedownDefense: 78,
        submissionAvg: 0.6,
      ),
      bio:
          'A technically sound, defensively responsible striker with underrated '
          'wrestling and a long unbeaten run at 205.',
    ),

    // ── Women's Bantamweight ────────────────────────────────────
    const Fighter(
      id: 'f_harrison',
      name: 'Kayla Harrison',
      nickname: '',
      weightClass: WeightClass.womenBantamweight,
      country: 'United States',
      flag: '🇺🇸',
      record: FightRecord(wins: 18, losses: 1),
      isChampion: true,
      heightCm: 173,
      reachCm: 175,
      age: 35,
      stance: 'Southpaw',
      winsByKo: 4,
      winsBySub: 8,
      winsByDec: 6,
      stats: FighterStats(
        sigStrikesPerMin: 4.5,
        strikingAccuracy: 52,
        sigStrikesAbsorbedPerMin: 2.0,
        strikingDefense: 56,
        takedownAvg: 4.8,
        takedownAccuracy: 58,
        takedownDefense: 80,
        submissionAvg: 1.5,
      ),
      bio:
          'A two-time Olympic judo gold medalist whose world-class grappling '
          'translates into dominant, finish-heavy MMA performances.',
    ),
    const Fighter(
      id: 'f_pena',
      name: 'Julianna Peña',
      nickname: 'The Venezuelan Vixen',
      weightClass: WeightClass.womenBantamweight,
      country: 'United States',
      flag: '🇺🇸',
      record: FightRecord(wins: 12, losses: 5),
      rankingPosition: 1,
      heightCm: 168,
      reachCm: 173,
      age: 35,
      stance: 'Orthodox',
      winsByKo: 1,
      winsBySub: 6,
      winsByDec: 5,
      stats: FighterStats(
        sigStrikesPerMin: 4.0,
        strikingAccuracy: 40,
        sigStrikesAbsorbedPerMin: 4.3,
        strikingDefense: 50,
        takedownAvg: 2.1,
        takedownAccuracy: 38,
        takedownDefense: 55,
        submissionAvg: 1.8,
      ),
      bio:
          'A gritty, never-say-die grappler famous for a huge upset title win, '
          'always dangerous with her scrambles and submissions.',
    ),
  ];

  static final Map<String, Fighter> fighterById = {
    for (final f in fighters) f.id: f,
  };

  static Fighter? fighter(String id) => fighterById[id];

  // ── Rankings ─────────────────────────────────────────────────
  static final List<DivisionRanking> rankings = [
    const DivisionRanking(
      weightClass: WeightClass.lightweight,
      championId: 'f_makhachev',
      contenders: [
        RankingEntry(fighterId: 'f_oliveira', position: 1, change: 1),
        RankingEntry(fighterId: 'f_gaethje', position: 2, change: -1),
        RankingEntry(fighterId: 'f_tsarukyan', position: 3, change: 0),
      ],
    ),
    const DivisionRanking(
      weightClass: WeightClass.welterweight,
      championId: 'f_dellamaddalena',
      contenders: [
        RankingEntry(fighterId: 'f_muhammad', position: 1, change: 0),
        RankingEntry(fighterId: 'f_brady', position: 2, change: 2),
      ],
    ),
    const DivisionRanking(
      weightClass: WeightClass.middleweight,
      championId: 'f_dupessa',
      contenders: [
        RankingEntry(fighterId: 'f_chimaev', position: 1, change: 0),
      ],
    ),
    const DivisionRanking(
      weightClass: WeightClass.lightHeavyweight,
      championId: 'f_pereira',
      contenders: [
        RankingEntry(fighterId: 'f_ankalaev', position: 1, change: 0),
      ],
    ),
    const DivisionRanking(
      weightClass: WeightClass.heavyweight,
      championId: 'f_aspinall',
      contenders: [],
    ),
    const DivisionRanking(
      weightClass: WeightClass.womenBantamweight,
      championId: 'f_harrison',
      contenders: [
        RankingEntry(fighterId: 'f_pena', position: 1, change: 0),
      ],
    ),
  ];

  // ── Events ───────────────────────────────────────────────────
  static final List<Event> events = [
    Event(
      id: 'e_312',
      name: 'UFC 312',
      subtitle: 'Makhachev vs Oliveira 2',
      date: DateTime(2026, 8, 15, 22),
      venue: 'T-Mobile Arena',
      location: 'Las Vegas, NV',
      status: EventStatus.upcoming,
      mainCard: const [
        Bout(
          id: 'b_312_1',
          redCornerId: 'f_makhachev',
          blueCornerId: 'f_oliveira',
          weightClass: WeightClass.lightweight,
          isTitleFight: true,
          isMainEvent: true,
          rounds: 5,
        ),
        Bout(
          id: 'b_312_2',
          redCornerId: 'f_dellamaddalena',
          blueCornerId: 'f_muhammad',
          weightClass: WeightClass.welterweight,
          isTitleFight: true,
          rounds: 5,
        ),
        Bout(
          id: 'b_312_3',
          redCornerId: 'f_gaethje',
          blueCornerId: 'f_tsarukyan',
          weightClass: WeightClass.lightweight,
          rounds: 3,
        ),
      ],
      prelims: const [
        Bout(
          id: 'b_312_p1',
          redCornerId: 'f_brady',
          blueCornerId: 'f_muhammad',
          weightClass: WeightClass.welterweight,
          rounds: 3,
        ),
      ],
    ),
    Event(
      id: 'e_313',
      name: 'UFC 313',
      subtitle: 'Du Plessis vs Chimaev',
      date: DateTime(2026, 9, 12, 22),
      venue: 'Etihad Arena',
      location: 'Abu Dhabi, UAE',
      status: EventStatus.upcoming,
      mainCard: const [
        Bout(
          id: 'b_313_1',
          redCornerId: 'f_dupessa',
          blueCornerId: 'f_chimaev',
          weightClass: WeightClass.middleweight,
          isTitleFight: true,
          isMainEvent: true,
          rounds: 5,
        ),
        Bout(
          id: 'b_313_2',
          redCornerId: 'f_pereira',
          blueCornerId: 'f_ankalaev',
          weightClass: WeightClass.lightHeavyweight,
          isTitleFight: true,
          rounds: 5,
        ),
      ],
    ),
    Event(
      id: 'e_311',
      name: 'UFC 311',
      subtitle: 'Aspinall vs Pereira',
      date: DateTime(2026, 6, 7, 22),
      venue: 'Kaseya Center',
      location: 'Miami, FL',
      status: EventStatus.past,
      mainCard: const [
        Bout(
          id: 'b_311_1',
          redCornerId: 'f_aspinall',
          blueCornerId: 'f_pereira',
          weightClass: WeightClass.heavyweight,
          isMainEvent: true,
          rounds: 5,
          winnerId: 'f_aspinall',
          method: 'KO/TKO',
          finishRound: 'R2',
        ),
        Bout(
          id: 'b_311_2',
          redCornerId: 'f_harrison',
          blueCornerId: 'f_pena',
          weightClass: WeightClass.womenBantamweight,
          isTitleFight: true,
          rounds: 5,
          winnerId: 'f_harrison',
          method: 'Submission',
          finishRound: 'R3',
        ),
      ],
    ),
  ];

  static Event? event(String id) =>
      events.where((e) => e.id == id).firstOrNull;

  // ── Notifications ────────────────────────────────────────────
  static final List<NotificationItem> notifications = [
    NotificationItem(
      id: 'n1',
      title: 'Fight week is here',
      body: 'UFC 312: Makhachev vs Oliveira 2 goes down Saturday. Set a reminder.',
      timestamp: DateTime(2026, 7, 6, 9, 30),
      type: NotificationType.event,
    ),
    NotificationItem(
      id: 'n2',
      title: 'Rankings updated',
      body: 'Sean Brady jumps two spots to #2 at welterweight.',
      timestamp: DateTime(2026, 7, 5, 14, 0),
      type: NotificationType.ranking,
    ),
    NotificationItem(
      id: 'n3',
      title: 'Tom Aspinall retains',
      body: 'Aspinall stops Pereira in the second round at UFC 311.',
      timestamp: DateTime(2026, 6, 7, 23, 45),
      type: NotificationType.fight,
      read: true,
    ),
  ];

  // ── Current user ─────────────────────────────────────────────
  static final UserProfile currentUser = UserProfile(
    id: 'u_me',
    name: 'Alex Rivera',
    email: 'alex.rivera@example.com',
    handle: '@octagoned',
    avatarUrl: '',
    memberSince: DateTime(2021, 3, 1),
    favoriteFighterIds: const ['islam-makhachev', 'tom-aspinall'],
    predictionsMade: 142,
    predictionsCorrect: 98,
  );
}
