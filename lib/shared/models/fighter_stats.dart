import 'package:freezed_annotation/freezed_annotation.dart';

part 'fighter_stats.freezed.dart';
part 'fighter_stats.g.dart';

@freezed
abstract class FighterStats with _$FighterStats {
  const factory FighterStats({
    /// Significant strikes landed per minute.
    @Default(0) double sigStrikesPerMin,

    /// Striking accuracy, 0–100 (%).
    @Default(0) double strikingAccuracy,

    /// Significant strikes absorbed per minute.
    @Default(0) double sigStrikesAbsorbedPerMin,

    /// Striking defense, 0–100 (%).
    @Default(0) double strikingDefense,

    /// Takedowns landed per 15 minutes.
    @Default(0) double takedownAvg,

    /// Takedown accuracy, 0–100 (%).
    @Default(0) double takedownAccuracy,

    /// Takedown defense, 0–100 (%).
    @Default(0) double takedownDefense,

    /// Submission attempts per 15 minutes.
    @Default(0) double submissionAvg,
  }) = _FighterStats;

  factory FighterStats.fromJson(Map<String, dynamic> json) =>
      _$FighterStatsFromJson(json);
}
