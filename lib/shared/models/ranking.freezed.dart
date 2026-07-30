// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ranking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RankingEntry {
  String get fighterId;
  int get position; // 0 = champion, 1..15 = ranked
  int get change; // movement vs last update (+/-)
  /// Entered the top 15 in the latest update (ufc.com marks these `NR`
  /// rather than giving a movement figure).
  bool get isNew;

  /// Create a copy of RankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RankingEntryCopyWith<RankingEntry> get copyWith =>
      _$RankingEntryCopyWithImpl<RankingEntry>(
          this as RankingEntry, _$identity);

  /// Serializes this RankingEntry to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RankingEntry &&
            (identical(other.fighterId, fighterId) ||
                other.fighterId == fighterId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.change, change) || other.change == change) &&
            (identical(other.isNew, isNew) || other.isNew == isNew));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, fighterId, position, change, isNew);

  @override
  String toString() {
    return 'RankingEntry(fighterId: $fighterId, position: $position, change: $change, isNew: $isNew)';
  }
}

/// @nodoc
abstract mixin class $RankingEntryCopyWith<$Res> {
  factory $RankingEntryCopyWith(
          RankingEntry value, $Res Function(RankingEntry) _then) =
      _$RankingEntryCopyWithImpl;
  @useResult
  $Res call({String fighterId, int position, int change, bool isNew});
}

/// @nodoc
class _$RankingEntryCopyWithImpl<$Res> implements $RankingEntryCopyWith<$Res> {
  _$RankingEntryCopyWithImpl(this._self, this._then);

  final RankingEntry _self;
  final $Res Function(RankingEntry) _then;

  /// Create a copy of RankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fighterId = null,
    Object? position = null,
    Object? change = null,
    Object? isNew = null,
  }) {
    return _then(_self.copyWith(
      fighterId: null == fighterId
          ? _self.fighterId
          : fighterId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      change: null == change
          ? _self.change
          : change // ignore: cast_nullable_to_non_nullable
              as int,
      isNew: null == isNew
          ? _self.isNew
          : isNew // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _RankingEntry implements RankingEntry {
  const _RankingEntry(
      {required this.fighterId,
      required this.position,
      this.change = 0,
      this.isNew = false});
  factory _RankingEntry.fromJson(Map<String, dynamic> json) =>
      _$RankingEntryFromJson(json);

  @override
  final String fighterId;
  @override
  final int position;
// 0 = champion, 1..15 = ranked
  @override
  @JsonKey()
  final int change;
// movement vs last update (+/-)
  /// Entered the top 15 in the latest update (ufc.com marks these `NR`
  /// rather than giving a movement figure).
  @override
  @JsonKey()
  final bool isNew;

  /// Create a copy of RankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RankingEntryCopyWith<_RankingEntry> get copyWith =>
      __$RankingEntryCopyWithImpl<_RankingEntry>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RankingEntryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RankingEntry &&
            (identical(other.fighterId, fighterId) ||
                other.fighterId == fighterId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.change, change) || other.change == change) &&
            (identical(other.isNew, isNew) || other.isNew == isNew));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, fighterId, position, change, isNew);

  @override
  String toString() {
    return 'RankingEntry(fighterId: $fighterId, position: $position, change: $change, isNew: $isNew)';
  }
}

/// @nodoc
abstract mixin class _$RankingEntryCopyWith<$Res>
    implements $RankingEntryCopyWith<$Res> {
  factory _$RankingEntryCopyWith(
          _RankingEntry value, $Res Function(_RankingEntry) _then) =
      __$RankingEntryCopyWithImpl;
  @override
  @useResult
  $Res call({String fighterId, int position, int change, bool isNew});
}

/// @nodoc
class __$RankingEntryCopyWithImpl<$Res>
    implements _$RankingEntryCopyWith<$Res> {
  __$RankingEntryCopyWithImpl(this._self, this._then);

  final _RankingEntry _self;
  final $Res Function(_RankingEntry) _then;

  /// Create a copy of RankingEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fighterId = null,
    Object? position = null,
    Object? change = null,
    Object? isNew = null,
  }) {
    return _then(_RankingEntry(
      fighterId: null == fighterId
          ? _self.fighterId
          : fighterId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      change: null == change
          ? _self.change
          : change // ignore: cast_nullable_to_non_nullable
              as int,
      isNew: null == isNew
          ? _self.isNew
          : isNew // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$DivisionRanking {
  WeightClass get weightClass;
  String get championId;
  List<RankingEntry> get contenders;

  /// Create a copy of DivisionRanking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DivisionRankingCopyWith<DivisionRanking> get copyWith =>
      _$DivisionRankingCopyWithImpl<DivisionRanking>(
          this as DivisionRanking, _$identity);

  /// Serializes this DivisionRanking to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DivisionRanking &&
            (identical(other.weightClass, weightClass) ||
                other.weightClass == weightClass) &&
            (identical(other.championId, championId) ||
                other.championId == championId) &&
            const DeepCollectionEquality()
                .equals(other.contenders, contenders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, weightClass, championId,
      const DeepCollectionEquality().hash(contenders));

  @override
  String toString() {
    return 'DivisionRanking(weightClass: $weightClass, championId: $championId, contenders: $contenders)';
  }
}

/// @nodoc
abstract mixin class $DivisionRankingCopyWith<$Res> {
  factory $DivisionRankingCopyWith(
          DivisionRanking value, $Res Function(DivisionRanking) _then) =
      _$DivisionRankingCopyWithImpl;
  @useResult
  $Res call(
      {WeightClass weightClass,
      String championId,
      List<RankingEntry> contenders});
}

/// @nodoc
class _$DivisionRankingCopyWithImpl<$Res>
    implements $DivisionRankingCopyWith<$Res> {
  _$DivisionRankingCopyWithImpl(this._self, this._then);

  final DivisionRanking _self;
  final $Res Function(DivisionRanking) _then;

  /// Create a copy of DivisionRanking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weightClass = null,
    Object? championId = null,
    Object? contenders = null,
  }) {
    return _then(_self.copyWith(
      weightClass: null == weightClass
          ? _self.weightClass
          : weightClass // ignore: cast_nullable_to_non_nullable
              as WeightClass,
      championId: null == championId
          ? _self.championId
          : championId // ignore: cast_nullable_to_non_nullable
              as String,
      contenders: null == contenders
          ? _self.contenders
          : contenders // ignore: cast_nullable_to_non_nullable
              as List<RankingEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _DivisionRanking extends DivisionRanking {
  const _DivisionRanking(
      {required this.weightClass,
      required this.championId,
      final List<RankingEntry> contenders = const <RankingEntry>[]})
      : _contenders = contenders,
        super._();
  factory _DivisionRanking.fromJson(Map<String, dynamic> json) =>
      _$DivisionRankingFromJson(json);

  @override
  final WeightClass weightClass;
  @override
  final String championId;
  final List<RankingEntry> _contenders;
  @override
  @JsonKey()
  List<RankingEntry> get contenders {
    if (_contenders is EqualUnmodifiableListView) return _contenders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contenders);
  }

  /// Create a copy of DivisionRanking
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DivisionRankingCopyWith<_DivisionRanking> get copyWith =>
      __$DivisionRankingCopyWithImpl<_DivisionRanking>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DivisionRankingToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DivisionRanking &&
            (identical(other.weightClass, weightClass) ||
                other.weightClass == weightClass) &&
            (identical(other.championId, championId) ||
                other.championId == championId) &&
            const DeepCollectionEquality()
                .equals(other._contenders, _contenders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, weightClass, championId,
      const DeepCollectionEquality().hash(_contenders));

  @override
  String toString() {
    return 'DivisionRanking(weightClass: $weightClass, championId: $championId, contenders: $contenders)';
  }
}

/// @nodoc
abstract mixin class _$DivisionRankingCopyWith<$Res>
    implements $DivisionRankingCopyWith<$Res> {
  factory _$DivisionRankingCopyWith(
          _DivisionRanking value, $Res Function(_DivisionRanking) _then) =
      __$DivisionRankingCopyWithImpl;
  @override
  @useResult
  $Res call(
      {WeightClass weightClass,
      String championId,
      List<RankingEntry> contenders});
}

/// @nodoc
class __$DivisionRankingCopyWithImpl<$Res>
    implements _$DivisionRankingCopyWith<$Res> {
  __$DivisionRankingCopyWithImpl(this._self, this._then);

  final _DivisionRanking _self;
  final $Res Function(_DivisionRanking) _then;

  /// Create a copy of DivisionRanking
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? weightClass = null,
    Object? championId = null,
    Object? contenders = null,
  }) {
    return _then(_DivisionRanking(
      weightClass: null == weightClass
          ? _self.weightClass
          : weightClass // ignore: cast_nullable_to_non_nullable
              as WeightClass,
      championId: null == championId
          ? _self.championId
          : championId // ignore: cast_nullable_to_non_nullable
              as String,
      contenders: null == contenders
          ? _self._contenders
          : contenders // ignore: cast_nullable_to_non_nullable
              as List<RankingEntry>,
    ));
  }
}

// dart format on
