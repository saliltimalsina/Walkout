import 'package:freezed_annotation/freezed_annotation.dart';

import 'fight_record.dart';
import 'fighter_stats.dart';
import 'weight_class.dart';

part 'fighter.freezed.dart';
part 'fighter.g.dart';

@freezed
abstract class Fighter with _$Fighter {
  const Fighter._();

  const factory Fighter({
    required String id,
    required String name,
    @Default('') String nickname,
    required WeightClass weightClass,
    @Default('') String country,
    @Default('') String flag, // emoji flag
    @Default(FightRecord()) FightRecord record,
    int? rankingPosition, // null when unranked
    @Default(false) bool isChampion,
    @Default('') String imageUrl,
    @Default(0) int heightCm,
    @Default(0) int reachCm,
    @Default(0) int age,
    @Default('Orthodox') String stance,
    @Default(FighterStats()) FighterStats stats,
    @Default('') String bio,
    @Default(0) int winsByKo,
    @Default(0) int winsBySub,
    @Default(0) int winsByDec,
  }) = _Fighter;

  factory Fighter.fromJson(Map<String, dynamic> json) =>
      _$FighterFromJson(json);

  String get displayName => nickname.isEmpty ? name : name;

  String get rankLabel {
    if (isChampion) return 'C';
    if (rankingPosition == null) return 'NR';
    return '#$rankingPosition';
  }
}
