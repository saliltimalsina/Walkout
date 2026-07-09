// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Bout _$BoutFromJson(Map<String, dynamic> json) => _Bout(
      id: json['id'] as String,
      redCornerId: json['redCornerId'] as String? ?? '',
      blueCornerId: json['blueCornerId'] as String? ?? '',
      redName: json['redName'] as String? ?? '',
      blueName: json['blueName'] as String? ?? '',
      weightClass:
          $enumDecodeNullable(_$WeightClassEnumMap, json['weightClass']) ??
              WeightClass.lightweight,
      weightLabel: json['weightLabel'] as String? ?? '',
      isTitleFight: json['isTitleFight'] as bool? ?? false,
      isMainEvent: json['isMainEvent'] as bool? ?? false,
      rounds: (json['rounds'] as num?)?.toInt() ?? 3,
      winnerId: json['winnerId'] as String?,
      method: json['method'] as String? ?? '',
      finishRound: json['finishRound'] as String? ?? '',
    );

Map<String, dynamic> _$BoutToJson(_Bout instance) => <String, dynamic>{
      'id': instance.id,
      'redCornerId': instance.redCornerId,
      'blueCornerId': instance.blueCornerId,
      'redName': instance.redName,
      'blueName': instance.blueName,
      'weightClass': _$WeightClassEnumMap[instance.weightClass]!,
      'weightLabel': instance.weightLabel,
      'isTitleFight': instance.isTitleFight,
      'isMainEvent': instance.isMainEvent,
      'rounds': instance.rounds,
      'winnerId': instance.winnerId,
      'method': instance.method,
      'finishRound': instance.finishRound,
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
