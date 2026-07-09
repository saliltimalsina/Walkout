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
    @Default('') String photoUrl, // CDN full-body cutout from ingest, if any
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

  /// Preferred image: the fresh CDN cutout when present, else the bundled one.
  String get photo => photoUrl.isEmpty ? imageUrl : photoUrl;

  String get rankLabel {
    if (isChampion) return 'C';
    if (rankingPosition == null) return 'NR';
    return '#$rankingPosition';
  }
}
