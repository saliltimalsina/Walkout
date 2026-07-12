// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Event _$EventFromJson(Map<String, dynamic> json) => _Event(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      date: _eventDateFromJson(json['date'] as String),
      venue: json['venue'] as String? ?? '',
      location: json['location'] as String? ?? '',
      posterUrl: json['posterUrl'] as String? ?? '',
      heroImage: json['heroImage'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      status: $enumDecodeNullable(_$EventStatusEnumMap, json['status']) ??
          EventStatus.upcoming,
      mainCard: (json['mainCard'] as List<dynamic>?)
              ?.map((e) => Bout.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Bout>[],
      prelims: (json['prelims'] as List<dynamic>?)
              ?.map((e) => Bout.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Bout>[],
    );

Map<String, dynamic> _$EventToJson(_Event instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'subtitle': instance.subtitle,
      'date': _eventDateToJson(instance.date),
      'venue': instance.venue,
      'location': instance.location,
      'posterUrl': instance.posterUrl,
      'heroImage': instance.heroImage,
      'eventType': instance.eventType,
      'status': _$EventStatusEnumMap[instance.status]!,
      'mainCard': instance.mainCard.map((e) => e.toJson()).toList(),
      'prelims': instance.prelims.map((e) => e.toJson()).toList(),
    };

const _$EventStatusEnumMap = {
  EventStatus.upcoming: 'upcoming',
  EventStatus.live: 'live',
  EventStatus.past: 'past',
};
