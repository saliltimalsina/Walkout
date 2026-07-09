import 'bout.dart';
import 'event.dart';
import 'fighter.dart';

/// How sure the user is about a pick. Affects points, not correctness.
enum PickConfidence {
  coinFlip('Coin Flip', 100),
  confident('Confident', 120),
  certain('Certain', 150);

  const PickConfidence(this.label, this.points);

  final String label;

  /// Points awarded when the pick is correct.
  final int points;

  static PickConfidence fromName(String value) =>
      PickConfidence.values.firstWhere(
        (c) => c.name == value,
        orElse: () => PickConfidence.coinFlip,
      );
}

/// One fight prediction: which corner wins and how confident the user is.
/// [percent] is the slider value (0–100); [confidence] is derived from it
/// and drives the points.
class FightPick {
  const FightPick({
    required this.fighterId,
    this.percent = 50,
  });

  final String fighterId;
  final int percent;

  PickConfidence get confidence => percent >= 75
      ? PickConfidence.certain
      : percent >= 40
          ? PickConfidence.confident
          : PickConfidence.coinFlip;

  FightPick copyWith({String? fighterId, int? percent}) => FightPick(
        fighterId: fighterId ?? this.fighterId,
        percent: percent ?? this.percent,
      );

  Map<String, dynamic> toJson() => {
        'fighterId': fighterId,
        'percent': percent,
      };

  factory FightPick.fromJson(Map<String, dynamic> json) => FightPick(
        fighterId: json['fighterId'] as String? ?? '',
        // Older cards stored a confidence name instead of a percent.
        percent: json['percent'] as int? ??
            switch (json['confidence'] as String? ?? '') {
              'certain' => 90,
              'confident' => 60,
              _ => 50,
            },
      );
}

/// The user's full prediction card for one event.
class PickCard {
  const PickCard({
    required this.eventId,
    this.picks = const {},
    this.anySubmission,
    this.submitted = false,
  });

  final String eventId;

  /// Bout index (across main card then prelims) → pick.
  final Map<int, FightPick> picks;

  /// Bonus: will any fight end in a submission?
  final bool? anySubmission;

  final bool submitted;

  PickCard copyWith({
    Map<int, FightPick>? picks,
    bool? anySubmission,
    bool? submitted,
  }) =>
      PickCard(
        eventId: eventId,
        picks: picks ?? this.picks,
        anySubmission: anySubmission ?? this.anySubmission,
        submitted: submitted ?? this.submitted,
      );

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'picks': {
          for (final e in picks.entries) '${e.key}': e.value.toJson(),
        },
        if (anySubmission != null) 'anySubmission': anySubmission,
        'submitted': submitted,
      };

  factory PickCard.fromJson(Map<String, dynamic> json) => PickCard(
        eventId: json['eventId'] as String? ?? '',
        picks: {
          for (final e
              in (json['picks'] as Map<String, dynamic>? ?? {}).entries)
            int.parse(e.key):
                FightPick.fromJson(e.value as Map<String, dynamic>),
        },
        anySubmission: json['anySubmission'] as bool?,
        submitted: json['submitted'] as bool? ?? false,
      );
}

/// All bouts of an event in pick order: main card first, then prelims.
List<Bout> pickableBouts(Event event) => [...event.mainCard, ...event.prelims];

/// Grades one card against an event's results.
class CardScore {
  const CardScore({
    required this.correct,
    required this.wrong,
    required this.pending,
    required this.points,
  });

  final int correct;
  final int wrong;
  final int pending;
  final int points;

  int get graded => correct + wrong;
  bool get complete => pending == 0 && graded > 0;
  bool get perfect => complete && wrong == 0;
}

/// Deterministic demo community split (percent of fans on this fighter)
/// until a real backend exists.
int communityPct(String eventId, int boutIndex, String fighterId) {
  final h = Object.hash(eventId, boutIndex, fighterId);
  return 22 + h.abs() % 66; // 22–87%
}

/// Whether [pickedId] is the on-paper favorite of [bout]: champion first,
/// then better ranking, then better record.
bool isFavoritePick(Bout bout, String pickedId, Map<String, Fighter> byId) {
  final red = byId[bout.redCornerId];
  final blue = byId[bout.blueCornerId];
  if (red == null || blue == null) return true;
  int rank(Fighter f) => f.isChampion ? 0 : (f.rankingPosition ?? 99);
  if (rank(red) != rank(blue)) {
    final favorite =
        rank(red) < rank(blue) ? bout.redCornerId : bout.blueCornerId;
    return pickedId == favorite;
  }
  final favorite = red.record.wins >= blue.record.wins
      ? bout.redCornerId
      : bout.blueCornerId;
  return pickedId == favorite;
}

/// How a card was played: risk, upsets, and the prediction-style label.
class CardDna {
  const CardDna({
    required this.emoji,
    required this.label,
    required this.line,
    required this.riskScore,
    required this.favorites,
    required this.underdogs,
    required this.upsets,
    required this.avgPercent,
    required this.communityMatch,
  });

  final String emoji;
  final String label;
  final String line;
  final int riskScore;
  final int favorites;
  final int underdogs;
  final int upsets;
  final int avgPercent;
  final int communityMatch;
}

CardDna analyzeCard(PickCard card, Event event, Map<String, Fighter> byId) {
  final bouts = pickableBouts(event);
  var favorites = 0, underdogs = 0, upsets = 0;
  var pctSum = 0, communitySum = 0;
  final n = card.picks.length;

  for (final e in card.picks.entries) {
    if (e.key >= bouts.length) continue;
    final community = communityPct(event.id, e.key, e.value.fighterId);
    communitySum += community;
    pctSum += e.value.percent;
    if (isFavoritePick(bouts[e.key], e.value.fighterId, byId)) {
      favorites++;
    } else {
      underdogs++;
      if (community < 35) upsets++;
    }
  }

  final avgPercent = n == 0 ? 0 : pctSum ~/ n;
  final communityMatch = n == 0 ? 0 : communitySum ~/ n;
  final underdogShare = n == 0 ? 0.0 : underdogs / n;
  final riskScore = n == 0
      ? 0
      : (underdogShare * 70 + (100 - communityMatch) * 0.3)
          .round()
          .clamp(1, 99);

  final (emoji, label, line) = underdogShare >= 0.4
      ? ('🔥', 'Chaos Agent', 'You bet against the world and love it.')
      : underdogShare >= 0.22
          ? ('🦅', 'Underdog Hunter',
              'You back the fighters no one sees coming.')
          : (favorites >= n * 0.8 && avgPercent >= 70)
              ? ('🎯', 'The Analyst', 'Favorites, conviction, precision.')
              : ('🦈', 'Calculated Gambler', 'Balanced risk, sharp edges.');

  return CardDna(
    emoji: emoji,
    label: label,
    line: line,
    riskScore: riskScore,
    favorites: favorites,
    underdogs: underdogs,
    upsets: upsets,
    avgPercent: avgPercent,
    communityMatch: communityMatch,
  );
}

CardScore scoreCard(PickCard card, Event event) {
  final bouts = pickableBouts(event);
  var correct = 0, wrong = 0, pending = 0, points = 0;
  for (final entry in card.picks.entries) {
    if (entry.key >= bouts.length) continue;
    final winner = bouts[entry.key].winnerId;
    if (winner == null) {
      pending++;
    } else if (winner == entry.value.fighterId) {
      correct++;
      points += entry.value.confidence.points;
    } else {
      wrong++;
    }
  }
  return CardScore(
    correct: correct,
    wrong: wrong,
    pending: pending,
    points: points,
  );
}
