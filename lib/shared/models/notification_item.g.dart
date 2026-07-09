// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) =>
    _NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: $enumDecodeNullable(_$NotificationTypeEnumMap, json['type']) ??
          NotificationType.news,
      read: json['read'] as bool? ?? false,
    );

Map<String, dynamic> _$NotificationItemToJson(_NotificationItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'read': instance.read,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.event: 'event',
  NotificationType.fight: 'fight',
  NotificationType.ranking: 'ranking',
  NotificationType.news: 'news',
  NotificationType.system: 'system',
};
