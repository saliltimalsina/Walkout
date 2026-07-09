// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fight_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FightRecord _$FightRecordFromJson(Map<String, dynamic> json) => _FightRecord(
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      noContests: (json['noContests'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FightRecordToJson(_FightRecord instance) =>
    <String, dynamic>{
      'wins': instance.wins,
      'losses': instance.losses,
      'draws': instance.draws,
      'noContests': instance.noContests,
    };
