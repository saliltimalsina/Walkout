// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fighter_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FighterStats _$FighterStatsFromJson(Map<String, dynamic> json) =>
    _FighterStats(
      sigStrikesPerMin: (json['sigStrikesPerMin'] as num?)?.toDouble() ?? 0,
      strikingAccuracy: (json['strikingAccuracy'] as num?)?.toDouble() ?? 0,
      sigStrikesAbsorbedPerMin:
          (json['sigStrikesAbsorbedPerMin'] as num?)?.toDouble() ?? 0,
      strikingDefense: (json['strikingDefense'] as num?)?.toDouble() ?? 0,
      takedownAvg: (json['takedownAvg'] as num?)?.toDouble() ?? 0,
      takedownAccuracy: (json['takedownAccuracy'] as num?)?.toDouble() ?? 0,
      takedownDefense: (json['takedownDefense'] as num?)?.toDouble() ?? 0,
      submissionAvg: (json['submissionAvg'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$FighterStatsToJson(_FighterStats instance) =>
    <String, dynamic>{
      'sigStrikesPerMin': instance.sigStrikesPerMin,
      'strikingAccuracy': instance.strikingAccuracy,
      'sigStrikesAbsorbedPerMin': instance.sigStrikesAbsorbedPerMin,
      'strikingDefense': instance.strikingDefense,
      'takedownAvg': instance.takedownAvg,
      'takedownAccuracy': instance.takedownAccuracy,
      'takedownDefense': instance.takedownDefense,
      'submissionAvg': instance.submissionAvg,
    };
