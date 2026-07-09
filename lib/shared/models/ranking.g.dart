// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RankingEntry _$RankingEntryFromJson(Map<String, dynamic> json) =>
    _RankingEntry(
      fighterId: json['fighterId'] as String,
      position: (json['position'] as num).toInt(),
      change: (json['change'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$RankingEntryToJson(_RankingEntry instance) =>
    <String, dynamic>{
      'fighterId': instance.fighterId,
      'position': instance.position,
      'change': instance.change,
    };

_DivisionRanking _$DivisionRankingFromJson(Map<String, dynamic> json) =>
    _DivisionRanking(
      weightClass: $enumDecode(_$WeightClassEnumMap, json['weightClass']),
      championId: json['championId'] as String,
      contenders: (json['contenders'] as List<dynamic>?)
              ?.map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RankingEntry>[],
    );

Map<String, dynamic> _$DivisionRankingToJson(_DivisionRanking instance) =>
    <String, dynamic>{
      'weightClass': _$WeightClassEnumMap[instance.weightClass]!,
      'championId': instance.championId,
      'contenders': instance.contenders.map((e) => e.toJson()).toList(),
    };

const _$WeightClassEnumMap = {
  WeightClass.flyweight: 'flyweight',
  WeightClass.bantamweight: 'bantamweight',
  WeightClass.featherweight: 'featherweight',
  WeightClass.lightweight: 'lightweight',
  WeightClass.welterweight: 'welterweight',
  WeightClass.middleweight: 'middleweight',
  WeightClass.lightHeavyweight: 'lightHeavyweight',
  WeightClass.heavyweight: 'heavyweight',
  WeightClass.womenStrawweight: 'womenStrawweight',
  WeightClass.womenFlyweight: 'womenFlyweight',
  WeightClass.womenBantamweight: 'womenBantamweight',
};
