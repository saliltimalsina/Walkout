import 'package:freezed_annotation/freezed_annotation.dart';

import 'weight_class.dart';

part 'bout.freezed.dart';
part 'bout.g.dart';

@freezed
abstract class Bout with _$Bout {
  const factory Bout({
    required String id,

    /// Roster fighter id when the corner matches our dataset; empty otherwise.
    @Default('') String redCornerId,
    @Default('') String blueCornerId,

    /// Corner display names — used when a corner isn't in our roster (so any
    /// scraped card still renders).
    @Default('') String redName,
    @Default('') String blueName,

    @Default(WeightClass.lightweight) WeightClass weightClass,

    /// Raw division label from the source (e.g. "Middleweight", "Catchweight").
    @Default('') String weightLabel,

    @Default(false) bool isTitleFight,
    @Default(false) bool isMainEvent,
    @Default(3) int rounds,

    /// Winner fighter id for completed bouts; null if upcoming.
    String? winnerId,
    @Default('') String method, // e.g. "KO/TKO", "Submission", "Decision"
    @Default('') String finishRound,
  }) = _Bout;

  factory Bout.fromJson(Map<String, dynamic> json) => _$BoutFromJson(json);
}
