// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Event {
  String get id;
  String get name;
  String get subtitle; // e.g. "Jones vs Aspinall"
  @JsonKey(fromJson: _eventDateFromJson, toJson: _eventDateToJson)
  DateTime get date;
  String get venue;
  String get location;
  String get posterUrl;

  /// Full-bleed cover/hero image (bundled asset path) for the home hero.
  String get heroImage;

  /// Headline label, e.g. "UFC Fight Night" or "UFC 328".
  String get eventType;

  /// Pipeline hint written by ingest/seed. Do NOT use for logic — it only
  /// updates when data is republished. Use [statusAt]/[isLiveAt] instead.
  EventStatus get status;
  List<Bout> get mainCard;
  List<Bout> get prelims;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EventCopyWith<Event> get copyWith =>
      _$EventCopyWithImpl<Event>(this as Event, _$identity);

  /// Serializes this Event to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Event &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.venue, venue) || other.venue == venue) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.posterUrl, posterUrl) ||
                other.posterUrl == posterUrl) &&
            (identical(other.heroImage, heroImage) ||
                other.heroImage == heroImage) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other.mainCard, mainCard) &&
            const DeepCollectionEquality().equals(other.prelims, prelims));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      subtitle,
      date,
      venue,
      location,
      posterUrl,
      heroImage,
      eventType,
      status,
      const DeepCollectionEquality().hash(mainCard),
      const DeepCollectionEquality().hash(prelims));

  @override
  String toString() {
    return 'Event(id: $id, name: $name, subtitle: $subtitle, date: $date, venue: $venue, location: $location, posterUrl: $posterUrl, heroImage: $heroImage, eventType: $eventType, status: $status, mainCard: $mainCard, prelims: $prelims)';
  }
}

/// @nodoc
abstract mixin class $EventCopyWith<$Res> {
  factory $EventCopyWith(Event value, $Res Function(Event) _then) =
      _$EventCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String subtitle,
      @JsonKey(fromJson: _eventDateFromJson, toJson: _eventDateToJson)
      DateTime date,
      String venue,
      String location,
      String posterUrl,
      String heroImage,
      String eventType,
      EventStatus status,
      List<Bout> mainCard,
      List<Bout> prelims});
}

/// @nodoc
class _$EventCopyWithImpl<$Res> implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._self, this._then);

  final Event _self;
  final $Res Function(Event) _then;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? subtitle = null,
    Object? date = null,
    Object? venue = null,
    Object? location = null,
    Object? posterUrl = null,
    Object? heroImage = null,
    Object? eventType = null,
    Object? status = null,
    Object? mainCard = null,
    Object? prelims = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      subtitle: null == subtitle
          ? _self.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      venue: null == venue
          ? _self.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      posterUrl: null == posterUrl
          ? _self.posterUrl
          : posterUrl // ignore: cast_nullable_to_non_nullable
              as String,
      heroImage: null == heroImage
          ? _self.heroImage
          : heroImage // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _self.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as EventStatus,
      mainCard: null == mainCard
          ? _self.mainCard
          : mainCard // ignore: cast_nullable_to_non_nullable
              as List<Bout>,
      prelims: null == prelims
          ? _self.prelims
          : prelims // ignore: cast_nullable_to_non_nullable
              as List<Bout>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _Event extends Event {
  const _Event(
      {required this.id,
      required this.name,
      this.subtitle = '',
      @JsonKey(fromJson: _eventDateFromJson, toJson: _eventDateToJson)
      required this.date,
      this.venue = '',
      this.location = '',
      this.posterUrl = '',
      this.heroImage = '',
      this.eventType = '',
      this.status = EventStatus.upcoming,
      final List<Bout> mainCard = const <Bout>[],
      final List<Bout> prelims = const <Bout>[]})
      : _mainCard = mainCard,
        _prelims = prelims,
        super._();
  factory _Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String subtitle;
// e.g. "Jones vs Aspinall"
  @override
  @JsonKey(fromJson: _eventDateFromJson, toJson: _eventDateToJson)
  final DateTime date;
  @override
  @JsonKey()
  final String venue;
  @override
  @JsonKey()
  final String location;
  @override
  @JsonKey()
  final String posterUrl;

  /// Full-bleed cover/hero image (bundled asset path) for the home hero.
  @override
  @JsonKey()
  final String heroImage;

  /// Headline label, e.g. "UFC Fight Night" or "UFC 328".
  @override
  @JsonKey()
  final String eventType;

  /// Pipeline hint written by ingest/seed. Do NOT use for logic — it only
  /// updates when data is republished. Use [statusAt]/[isLiveAt] instead.
  @override
  @JsonKey()
  final EventStatus status;
  final List<Bout> _mainCard;
  @override
  @JsonKey()
  List<Bout> get mainCard {
    if (_mainCard is EqualUnmodifiableListView) return _mainCard;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mainCard);
  }

  final List<Bout> _prelims;
  @override
  @JsonKey()
  List<Bout> get prelims {
    if (_prelims is EqualUnmodifiableListView) return _prelims;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_prelims);
  }

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EventCopyWith<_Event> get copyWith =>
      __$EventCopyWithImpl<_Event>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EventToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Event &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.venue, venue) || other.venue == venue) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.posterUrl, posterUrl) ||
                other.posterUrl == posterUrl) &&
            (identical(other.heroImage, heroImage) ||
                other.heroImage == heroImage) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._mainCard, _mainCard) &&
            const DeepCollectionEquality().equals(other._prelims, _prelims));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      subtitle,
      date,
      venue,
      location,
      posterUrl,
      heroImage,
      eventType,
      status,
      const DeepCollectionEquality().hash(_mainCard),
      const DeepCollectionEquality().hash(_prelims));

  @override
  String toString() {
    return 'Event(id: $id, name: $name, subtitle: $subtitle, date: $date, venue: $venue, location: $location, posterUrl: $posterUrl, heroImage: $heroImage, eventType: $eventType, status: $status, mainCard: $mainCard, prelims: $prelims)';
  }
}

/// @nodoc
abstract mixin class _$EventCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory _$EventCopyWith(_Event value, $Res Function(_Event) _then) =
      __$EventCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String subtitle,
      @JsonKey(fromJson: _eventDateFromJson, toJson: _eventDateToJson)
      DateTime date,
      String venue,
      String location,
      String posterUrl,
      String heroImage,
      String eventType,
      EventStatus status,
      List<Bout> mainCard,
      List<Bout> prelims});
}

/// @nodoc
class __$EventCopyWithImpl<$Res> implements _$EventCopyWith<$Res> {
  __$EventCopyWithImpl(this._self, this._then);

  final _Event _self;
  final $Res Function(_Event) _then;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? subtitle = null,
    Object? date = null,
    Object? venue = null,
    Object? location = null,
    Object? posterUrl = null,
    Object? heroImage = null,
    Object? eventType = null,
    Object? status = null,
    Object? mainCard = null,
    Object? prelims = null,
  }) {
    return _then(_Event(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      subtitle: null == subtitle
          ? _self.subtitle
          : subtitle // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      venue: null == venue
          ? _self.venue
          : venue // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      posterUrl: null == posterUrl
          ? _self.posterUrl
          : posterUrl // ignore: cast_nullable_to_non_nullable
              as String,
      heroImage: null == heroImage
          ? _self.heroImage
          : heroImage // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _self.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as EventStatus,
      mainCard: null == mainCard
          ? _self._mainCard
          : mainCard // ignore: cast_nullable_to_non_nullable
              as List<Bout>,
      prelims: null == prelims
          ? _self._prelims
          : prelims // ignore: cast_nullable_to_non_nullable
              as List<Bout>,
    ));
  }
}

// dart format on
