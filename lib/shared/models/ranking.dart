import 'package:freezed_annotation/freezed_annotation.dart';

import 'weight_class.dart';

part 'ranking.freezed.dart';
part 'ranking.g.dart';

@freezed
abstract class RankingEntry with _$RankingEntry {
  const factory RankingEntry({
    required String fighterId,
    required int position, // 0 = champion, 1..15 = ranked
    @Default(0) int change, // movement vs last update (+/-)
  }) = _RankingEntry;

  factory RankingEntry.fromJson(Map<String, dynamic> json) =>
      _$RankingEntryFromJson(json);
}

@freezed
abstract class DivisionRanking with _$DivisionRanking {
  const DivisionRanking._();

  const factory DivisionRanking({
    required WeightClass weightClass,
    required String championId,
    @Default(<RankingEntry>[]) List<RankingEntry> contenders,
  }) = _DivisionRanking;

  factory DivisionRanking.fromJson(Map<String, dynamic> json) =>
      _$DivisionRankingFromJson(json);
}
