// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fighter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Fighter _$FighterFromJson(Map<String, dynamic> json) => _Fighter(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String? ?? '',
      weightClass: $enumDecode(_$WeightClassEnumMap, json['weightClass']),
      country: json['country'] as String? ?? '',
      flag: json['flag'] as String? ?? '',
      record: json['record'] == null
          ? const FightRecord()
          : FightRecord.fromJson(json['record'] as Map<String, dynamic>),
      rankingPosition: (json['rankingPosition'] as num?)?.toInt(),
      isChampion: json['isChampion'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String? ?? '',
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 0,
      reachCm: (json['reachCm'] as num?)?.toInt() ?? 0,
      age: (json['age'] as num?)?.toInt() ?? 0,
      stance: json['stance'] as String? ?? 'Orthodox',
      stats: json['stats'] == null
          ? const FighterStats()
          : FighterStats.fromJson(json['stats'] as Map<String, dynamic>),
      bio: json['bio'] as String? ?? '',
      winsByKo: (json['winsByKo'] as num?)?.toInt() ?? 0,
      winsBySub: (json['winsBySub'] as num?)?.toInt() ?? 0,
      winsByDec: (json['winsByDec'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FighterToJson(_Fighter instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nickname': instance.nickname,
      'weightClass': _$WeightClassEnumMap[instance.weightClass]!,
      'country': instance.country,
      'flag': instance.flag,
      'record': instance.record.toJson(),
      'rankingPosition': instance.rankingPosition,
      'isChampion': instance.isChampion,
      'imageUrl': instance.imageUrl,
      'heightCm': instance.heightCm,
      'reachCm': instance.reachCm,
      'age': instance.age,
      'stance': instance.stance,
      'stats': instance.stats.toJson(),
      'bio': instance.bio,
      'winsByKo': instance.winsByKo,
      'winsBySub': instance.winsBySub,
      'winsByDec': instance.winsByDec,
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
