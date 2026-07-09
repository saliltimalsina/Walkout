import 'package:freezed_annotation/freezed_annotation.dart';

part 'fight_record.freezed.dart';
part 'fight_record.g.dart';

@freezed
abstract class FightRecord with _$FightRecord {
  const FightRecord._();

  const factory FightRecord({
    @Default(0) int wins,
    @Default(0) int losses,
    @Default(0) int draws,
    @Default(0) int noContests,
  }) = _FightRecord;

  factory FightRecord.fromJson(Map<String, dynamic> json) =>
      _$FightRecordFromJson(json);

  /// e.g. "23-1-0"
  String get display => '$wins-$losses-$draws';

  int get totalFights => wins + losses + draws + noContests;
}
