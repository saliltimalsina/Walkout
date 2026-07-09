// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Bout {
  String get id;

  /// Roster fighter id when the corner matches our dataset; empty otherwise.
  String get redCornerId;
  String get blueCornerId;

  /// Corner display names — used when a corner isn't in our roster (so any
  /// scraped card still renders).
  String get redName;
  String get blueName;
  WeightClass get weightClass;

  /// Raw division label from the source (e.g. "Middleweight", "Catchweight").
  String get weightLabel;
  bool get isTitleFight;
  bool get isMainEvent;
  int get rounds;

  /// Winner fighter id for completed bouts; null if upcoming.
  String? get winnerId;
  String get method; // e.g. "KO/TKO", "Submission", "Decision"
  String get finishRound;

  /// Create a copy of Bout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BoutCopyWith<Bout> get copyWith =>
      _$BoutCopyWithImpl<Bout>(this as Bout, _$identity);

  /// Serializes this Bout to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Bout &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.redCornerId, redCornerId) ||
                other.redCornerId == redCornerId) &&
            (identical(other.blueCornerId, blueCornerId) ||
                other.blueCornerId == blueCornerId) &&
            (identical(other.redName, redName) || other.redName == redName) &&
            (identical(other.blueName, blueName) ||
                other.blueName == blueName) &&
            (identical(other.weightClass, weightClass) ||
                other.weightClass == weightClass) &&
            (identical(other.weightLabel, weightLabel) ||
                other.weightLabel == weightLabel) &&
            (identical(other.isTitleFight, isTitleFight) ||
                other.isTitleFight == isTitleFight) &&
            (identical(other.isMainEvent, isMainEvent) ||
                other.isMainEvent == isMainEvent) &&
            (identical(other.rounds, rounds) || other.rounds == rounds) &&
            (identical(other.winnerId, winnerId) ||
                other.winnerId == winnerId) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.finishRound, finishRound) ||
                other.finishRound == finishRound));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      redCornerId,
      blueCornerId,
      redName,
      blueName,
      weightClass,
      weightLabel,
      isTitleFight,
      isMainEvent,
      rounds,
      winnerId,
      method,
      finishRound);

  @override
  String toString() {
    return 'Bout(id: $id, redCornerId: $redCornerId, blueCornerId: $blueCornerId, redName: $redName, blueName: $blueName, weightClass: $weightClass, weightLabel: $weightLabel, isTitleFight: $isTitleFight, isMainEvent: $isMainEvent, rounds: $rounds, winnerId: $winnerId, method: $method, finishRound: $finishRound)';
  }
}

/// @nodoc
abstract mixin class $BoutCopyWith<$Res> {
  factory $BoutCopyWith(Bout value, $Res Function(Bout) _then) =
      _$BoutCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String redCornerId,
      String blueCornerId,
      String redName,
      String blueName,
      WeightClass weightClass,
      String weightLabel,
      bool isTitleFight,
      bool isMainEvent,
      int rounds,
      String? winnerId,
      String method,
      String finishRound});
}

/// @nodoc
class _$BoutCopyWithImpl<$Res> implements $BoutCopyWith<$Res> {
  _$BoutCopyWithImpl(this._self, this._then);

  final Bout _self;
  final $Res Function(Bout) _then;

  /// Create a copy of Bout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? redCornerId = null,
    Object? blueCornerId = null,
    Object? redName = null,
    Object? blueName = null,
    Object? weightClass = null,
    Object? weightLabel = null,
    Object? isTitleFight = null,
    Object? isMainEvent = null,
    Object? rounds = null,
    Object? winnerId = freezed,
    Object? method = null,
    Object? finishRound = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      redCornerId: null == redCornerId
          ? _self.redCornerId
          : redCornerId // ignore: cast_nullable_to_non_nullable
              as String,
      blueCornerId: null == blueCornerId
          ? _self.blueCornerId
          : blueCornerId // ignore: cast_nullable_to_non_nullable
              as String,
      redName: null == redName
          ? _self.redName
          : redName // ignore: cast_nullable_to_non_nullable
              as String,
      blueName: null == blueName
          ? _self.blueName
          : blueName // ignore: cast_nullable_to_non_nullable
              as String,
      weightClass: null == weightClass
          ? _self.weightClass
          : weightClass // ignore: cast_nullable_to_non_nullable
              as WeightClass,
      weightLabel: null == weightLabel
          ? _self.weightLabel
          : weightLabel // ignore: cast_nullable_to_non_nullable
              as String,
      isTitleFight: null == isTitleFight
          ? _self.isTitleFight
          : isTitleFight // ignore: cast_nullable_to_non_nullable
              as bool,
      isMainEvent: null == isMainEvent
          ? _self.isMainEvent
          : isMainEvent // ignore: cast_nullable_to_non_nullable
              as bool,
      rounds: null == rounds
          ? _self.rounds
          : rounds // ignore: cast_nullable_to_non_nullable
              as int,
      winnerId: freezed == winnerId
          ? _self.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      finishRound: null == finishRound
          ? _self.finishRound
          : finishRound // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _Bout implements Bout {
  const _Bout(
      {required this.id,
      this.redCornerId = '',
      this.blueCornerId = '',
      this.redName = '',
      this.blueName = '',
      this.weightClass = WeightClass.lightweight,
      this.weightLabel = '',
      this.isTitleFight = false,
      this.isMainEvent = false,
      this.rounds = 3,
      this.winnerId,
      this.method = '',
      this.finishRound = ''});
  factory _Bout.fromJson(Map<String, dynamic> json) => _$BoutFromJson(json);

  @override
  final String id;

  /// Roster fighter id when the corner matches our dataset; empty otherwise.
  @override
  @JsonKey()
  final String redCornerId;
  @override
  @JsonKey()
  final String blueCornerId;

  /// Corner display names — used when a corner isn't in our roster (so any
  /// scraped card still renders).
  @override
  @JsonKey()
  final String redName;
  @override
  @JsonKey()
  final String blueName;
  @override
  @JsonKey()
  final WeightClass weightClass;

  /// Raw division label from the source (e.g. "Middleweight", "Catchweight").
  @override
  @JsonKey()
  final String weightLabel;
  @override
  @JsonKey()
  final bool isTitleFight;
  @override
  @JsonKey()
  final bool isMainEvent;
  @override
  @JsonKey()
  final int rounds;

  /// Winner fighter id for completed bouts; null if upcoming.
  @override
  final String? winnerId;
  @override
  @JsonKey()
  final String method;
// e.g. "KO/TKO", "Submission", "Decision"
  @override
  @JsonKey()
  final String finishRound;

  /// Create a copy of Bout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BoutCopyWith<_Bout> get copyWith =>
      __$BoutCopyWithImpl<_Bout>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BoutToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Bout &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.redCornerId, redCornerId) ||
                other.redCornerId == redCornerId) &&
            (identical(other.blueCornerId, blueCornerId) ||
                other.blueCornerId == blueCornerId) &&
            (identical(other.redName, redName) || other.redName == redName) &&
            (identical(other.blueName, blueName) ||
                other.blueName == blueName) &&
            (identical(other.weightClass, weightClass) ||
                other.weightClass == weightClass) &&
            (identical(other.weightLabel, weightLabel) ||
                other.weightLabel == weightLabel) &&
            (identical(other.isTitleFight, isTitleFight) ||
                other.isTitleFight == isTitleFight) &&
            (identical(other.isMainEvent, isMainEvent) ||
                other.isMainEvent == isMainEvent) &&
            (identical(other.rounds, rounds) || other.rounds == rounds) &&
            (identical(other.winnerId, winnerId) ||
                other.winnerId == winnerId) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.finishRound, finishRound) ||
                other.finishRound == finishRound));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      redCornerId,
      blueCornerId,
      redName,
      blueName,
      weightClass,
      weightLabel,
      isTitleFight,
      isMainEvent,
      rounds,
      winnerId,
      method,
      finishRound);

  @override
  String toString() {
    return 'Bout(id: $id, redCornerId: $redCornerId, blueCornerId: $blueCornerId, redName: $redName, blueName: $blueName, weightClass: $weightClass, weightLabel: $weightLabel, isTitleFight: $isTitleFight, isMainEvent: $isMainEvent, rounds: $rounds, winnerId: $winnerId, method: $method, finishRound: $finishRound)';
  }
}

/// @nodoc
abstract mixin class _$BoutCopyWith<$Res> implements $BoutCopyWith<$Res> {
  factory _$BoutCopyWith(_Bout value, $Res Function(_Bout) _then) =
      __$BoutCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String redCornerId,
      String blueCornerId,
      String redName,
      String blueName,
      WeightClass weightClass,
      String weightLabel,
      bool isTitleFight,
      bool isMainEvent,
      int rounds,
      String? winnerId,
      String method,
      String finishRound});
}

/// @nodoc
class __$BoutCopyWithImpl<$Res> implements _$BoutCopyWith<$Res> {
  __$BoutCopyWithImpl(this._self, this._then);

  final _Bout _self;
  final $Res Function(_Bout) _then;

  /// Create a copy of Bout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? redCornerId = null,
    Object? blueCornerId = null,
    Object? redName = null,
    Object? blueName = null,
    Object? weightClass = null,
    Object? weightLabel = null,
    Object? isTitleFight = null,
    Object? isMainEvent = null,
    Object? rounds = null,
    Object? winnerId = freezed,
    Object? method = null,
    Object? finishRound = null,
  }) {
    return _then(_Bout(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      redCornerId: null == redCornerId
          ? _self.redCornerId
          : redCornerId // ignore: cast_nullable_to_non_nullable
              as String,
      blueCornerId: null == blueCornerId
          ? _self.blueCornerId
          : blueCornerId // ignore: cast_nullable_to_non_nullable
              as String,
      redName: null == redName
          ? _self.redName
          : redName // ignore: cast_nullable_to_non_nullable
              as String,
      blueName: null == blueName
          ? _self.blueName
          : blueName // ignore: cast_nullable_to_non_nullable
              as String,
      weightClass: null == weightClass
          ? _self.weightClass
          : weightClass // ignore: cast_nullable_to_non_nullable
              as WeightClass,
      weightLabel: null == weightLabel
          ? _self.weightLabel
          : weightLabel // ignore: cast_nullable_to_non_nullable
              as String,
      isTitleFight: null == isTitleFight
          ? _self.isTitleFight
          : isTitleFight // ignore: cast_nullable_to_non_nullable
              as bool,
      isMainEvent: null == isMainEvent
          ? _self.isMainEvent
          : isMainEvent // ignore: cast_nullable_to_non_nullable
              as bool,
      rounds: null == rounds
          ? _self.rounds
          : rounds // ignore: cast_nullable_to_non_nullable
              as int,
      winnerId: freezed == winnerId
          ? _self.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      finishRound: null == finishRound
          ? _self.finishRound
          : finishRound // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
