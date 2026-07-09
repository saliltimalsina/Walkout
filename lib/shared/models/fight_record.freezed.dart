// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fight_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FightRecord {
  int get wins;
  int get losses;
  int get draws;
  int get noContests;

  /// Create a copy of FightRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FightRecordCopyWith<FightRecord> get copyWith =>
      _$FightRecordCopyWithImpl<FightRecord>(this as FightRecord, _$identity);

  /// Serializes this FightRecord to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FightRecord &&
            (identical(other.wins, wins) || other.wins == wins) &&
            (identical(other.losses, losses) || other.losses == losses) &&
            (identical(other.draws, draws) || other.draws == draws) &&
            (identical(other.noContests, noContests) ||
                other.noContests == noContests));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, wins, losses, draws, noContests);

  @override
  String toString() {
    return 'FightRecord(wins: $wins, losses: $losses, draws: $draws, noContests: $noContests)';
  }
}

/// @nodoc
abstract mixin class $FightRecordCopyWith<$Res> {
  factory $FightRecordCopyWith(
          FightRecord value, $Res Function(FightRecord) _then) =
      _$FightRecordCopyWithImpl;
  @useResult
  $Res call({int wins, int losses, int draws, int noContests});
}

/// @nodoc
class _$FightRecordCopyWithImpl<$Res> implements $FightRecordCopyWith<$Res> {
  _$FightRecordCopyWithImpl(this._self, this._then);

  final FightRecord _self;
  final $Res Function(FightRecord) _then;

  /// Create a copy of FightRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? wins = null,
    Object? losses = null,
    Object? draws = null,
    Object? noContests = null,
  }) {
    return _then(_self.copyWith(
      wins: null == wins
          ? _self.wins
          : wins // ignore: cast_nullable_to_non_nullable
              as int,
      losses: null == losses
          ? _self.losses
          : losses // ignore: cast_nullable_to_non_nullable
              as int,
      draws: null == draws
          ? _self.draws
          : draws // ignore: cast_nullable_to_non_nullable
              as int,
      noContests: null == noContests
          ? _self.noContests
          : noContests // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _FightRecord extends FightRecord {
  const _FightRecord(
      {this.wins = 0, this.losses = 0, this.draws = 0, this.noContests = 0})
      : super._();
  factory _FightRecord.fromJson(Map<String, dynamic> json) =>
      _$FightRecordFromJson(json);

  @override
  @JsonKey()
  final int wins;
  @override
  @JsonKey()
  final int losses;
  @override
  @JsonKey()
  final int draws;
  @override
  @JsonKey()
  final int noContests;

  /// Create a copy of FightRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FightRecordCopyWith<_FightRecord> get copyWith =>
      __$FightRecordCopyWithImpl<_FightRecord>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FightRecordToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FightRecord &&
            (identical(other.wins, wins) || other.wins == wins) &&
            (identical(other.losses, losses) || other.losses == losses) &&
            (identical(other.draws, draws) || other.draws == draws) &&
            (identical(other.noContests, noContests) ||
                other.noContests == noContests));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, wins, losses, draws, noContests);

  @override
  String toString() {
    return 'FightRecord(wins: $wins, losses: $losses, draws: $draws, noContests: $noContests)';
  }
}

/// @nodoc
abstract mixin class _$FightRecordCopyWith<$Res>
    implements $FightRecordCopyWith<$Res> {
  factory _$FightRecordCopyWith(
          _FightRecord value, $Res Function(_FightRecord) _then) =
      __$FightRecordCopyWithImpl;
  @override
  @useResult
  $Res call({int wins, int losses, int draws, int noContests});
}

/// @nodoc
class __$FightRecordCopyWithImpl<$Res> implements _$FightRecordCopyWith<$Res> {
  __$FightRecordCopyWithImpl(this._self, this._then);

  final _FightRecord _self;
  final $Res Function(_FightRecord) _then;

  /// Create a copy of FightRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? wins = null,
    Object? losses = null,
    Object? draws = null,
    Object? noContests = null,
  }) {
    return _then(_FightRecord(
      wins: null == wins
          ? _self.wins
          : wins // ignore: cast_nullable_to_non_nullable
              as int,
      losses: null == losses
          ? _self.losses
          : losses // ignore: cast_nullable_to_non_nullable
              as int,
      draws: null == draws
          ? _self.draws
          : draws // ignore: cast_nullable_to_non_nullable
              as int,
      noContests: null == noContests
          ? _self.noContests
          : noContests // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
