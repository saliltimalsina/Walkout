// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      memberSince: DateTime.parse(json['memberSince'] as String),
      favoriteFighterIds: (json['favoriteFighterIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      predictionsMade: (json['predictionsMade'] as num?)?.toInt() ?? 0,
      predictionsCorrect: (json['predictionsCorrect'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'handle': instance.handle,
      'memberSince': instance.memberSince.toIso8601String(),
      'favoriteFighterIds': instance.favoriteFighterIds,
      'predictionsMade': instance.predictionsMade,
      'predictionsCorrect': instance.predictionsCorrect,
    };
