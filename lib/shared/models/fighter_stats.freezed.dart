// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fighter_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FighterStats {
  /// Significant strikes landed per minute.
  double get sigStrikesPerMin;

  /// Striking accuracy, 0–100 (%).
  double get strikingAccuracy;

  /// Significant strikes absorbed per minute.
  double get sigStrikesAbsorbedPerMin;

  /// Striking defense, 0–100 (%).
  double get strikingDefense;

  /// Takedowns landed per 15 minutes.
  double get takedownAvg;

  /// Takedown accuracy, 0–100 (%).
  double get takedownAccuracy;

  /// Takedown defense, 0–100 (%).
  double get takedownDefense;

  /// Submission attempts per 15 minutes.
  double get submissionAvg;

  /// Create a copy of FighterStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FighterStatsCopyWith<FighterStats> get copyWith =>
      _$FighterStatsCopyWithImpl<FighterStats>(
          this as FighterStats, _$identity);

  /// Serializes this FighterStats to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FighterStats &&
            (identical(other.sigStrikesPerMin, sigStrikesPerMin) ||
                other.sigStrikesPerMin == sigStrikesPerMin) &&
            (identical(other.strikingAccuracy, strikingAccuracy) ||
                other.strikingAccuracy == strikingAccuracy) &&
            (identical(
                    other.sigStrikesAbsorbedPerMin, sigStrikesAbsorbedPerMin) ||
                other.sigStrikesAbsorbedPerMin == sigStrikesAbsorbedPerMin) &&
            (identical(other.strikingDefense, strikingDefense) ||
                other.strikingDefense == strikingDefense) &&
            (identical(other.takedownAvg, takedownAvg) ||
                other.takedownAvg == takedownAvg) &&
            (identical(other.takedownAccuracy, takedownAccuracy) ||
                other.takedownAccuracy == takedownAccuracy) &&
            (identical(other.takedownDefense, takedownDefense) ||
                other.takedownDefense == takedownDefense) &&
            (identical(other.submissionAvg, submissionAvg) ||
                other.submissionAvg == submissionAvg));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sigStrikesPerMin,
      strikingAccuracy,
      sigStrikesAbsorbedPerMin,
      strikingDefense,
      takedownAvg,
      takedownAccuracy,
      takedownDefense,
      submissionAvg);

  @override
  String toString() {
    return 'FighterStats(sigStrikesPerMin: $sigStrikesPerMin, strikingAccuracy: $strikingAccuracy, sigStrikesAbsorbedPerMin: $sigStrikesAbsorbedPerMin, strikingDefense: $strikingDefense, takedownAvg: $takedownAvg, takedownAccuracy: $takedownAccuracy, takedownDefense: $takedownDefense, submissionAvg: $submissionAvg)';
  }
}

/// @nodoc
abstract mixin class $FighterStatsCopyWith<$Res> {
  factory $FighterStatsCopyWith(
          FighterStats value, $Res Function(FighterStats) _then) =
      _$FighterStatsCopyWithImpl;
  @useResult
  $Res call(
      {double sigStrikesPerMin,
      double strikingAccuracy,
      double sigStrikesAbsorbedPerMin,
      double strikingDefense,
      double takedownAvg,
      double takedownAccuracy,
      double takedownDefense,
      double submissionAvg});
}

/// @nodoc
class _$FighterStatsCopyWithImpl<$Res> implements $FighterStatsCopyWith<$Res> {
  _$FighterStatsCopyWithImpl(this._self, this._then);

  final FighterStats _self;
  final $Res Function(FighterStats) _then;

  /// Create a copy of FighterStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sigStrikesPerMin = null,
    Object? strikingAccuracy = null,
    Object? sigStrikesAbsorbedPerMin = null,
    Object? strikingDefense = null,
    Object? takedownAvg = null,
    Object? takedownAccuracy = null,
    Object? takedownDefense = null,
    Object? submissionAvg = null,
  }) {
    return _then(_self.copyWith(
      sigStrikesPerMin: null == sigStrikesPerMin
          ? _self.sigStrikesPerMin
          : sigStrikesPerMin // ignore: cast_nullable_to_non_nullable
              as double,
      strikingAccuracy: null == strikingAccuracy
          ? _self.strikingAccuracy
          : strikingAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      sigStrikesAbsorbedPerMin: null == sigStrikesAbsorbedPerMin
          ? _self.sigStrikesAbsorbedPerMin
          : sigStrikesAbsorbedPerMin // ignore: cast_nullable_to_non_nullable
              as double,
      strikingDefense: null == strikingDefense
          ? _self.strikingDefense
          : strikingDefense // ignore: cast_nullable_to_non_nullable
              as double,
      takedownAvg: null == takedownAvg
          ? _self.takedownAvg
          : takedownAvg // ignore: cast_nullable_to_non_nullable
              as double,
      takedownAccuracy: null == takedownAccuracy
          ? _self.takedownAccuracy
          : takedownAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      takedownDefense: null == takedownDefense
          ? _self.takedownDefense
          : takedownDefense // ignore: cast_nullable_to_non_nullable
              as double,
      submissionAvg: null == submissionAvg
          ? _self.submissionAvg
          : submissionAvg // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _FighterStats implements FighterStats {
  const _FighterStats(
      {this.sigStrikesPerMin = 0,
      this.strikingAccuracy = 0,
      this.sigStrikesAbsorbedPerMin = 0,
      this.strikingDefense = 0,
      this.takedownAvg = 0,
      this.takedownAccuracy = 0,
      this.takedownDefense = 0,
      this.submissionAvg = 0});
  factory _FighterStats.fromJson(Map<String, dynamic> json) =>
      _$FighterStatsFromJson(json);

  /// Significant strikes landed per minute.
  @override
  @JsonKey()
  final double sigStrikesPerMin;

  /// Striking accuracy, 0–100 (%).
  @override
  @JsonKey()
  final double strikingAccuracy;

  /// Significant strikes absorbed per minute.
  @override
  @JsonKey()
  final double sigStrikesAbsorbedPerMin;

  /// Striking defense, 0–100 (%).
  @override
  @JsonKey()
  final double strikingDefense;

  /// Takedowns landed per 15 minutes.
  @override
  @JsonKey()
  final double takedownAvg;

  /// Takedown accuracy, 0–100 (%).
  @override
  @JsonKey()
  final double takedownAccuracy;

  /// Takedown defense, 0–100 (%).
  @override
  @JsonKey()
  final double takedownDefense;

  /// Submission attempts per 15 minutes.
  @override
  @JsonKey()
  final double submissionAvg;

  /// Create a copy of FighterStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FighterStatsCopyWith<_FighterStats> get copyWith =>
      __$FighterStatsCopyWithImpl<_FighterStats>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FighterStatsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FighterStats &&
            (identical(other.sigStrikesPerMin, sigStrikesPerMin) ||
                other.sigStrikesPerMin == sigStrikesPerMin) &&
            (identical(other.strikingAccuracy, strikingAccuracy) ||
                other.strikingAccuracy == strikingAccuracy) &&
            (identical(
                    other.sigStrikesAbsorbedPerMin, sigStrikesAbsorbedPerMin) ||
                other.sigStrikesAbsorbedPerMin == sigStrikesAbsorbedPerMin) &&
            (identical(other.strikingDefense, strikingDefense) ||
                other.strikingDefense == strikingDefense) &&
            (identical(other.takedownAvg, takedownAvg) ||
                other.takedownAvg == takedownAvg) &&
            (identical(other.takedownAccuracy, takedownAccuracy) ||
                other.takedownAccuracy == takedownAccuracy) &&
            (identical(other.takedownDefense, takedownDefense) ||
                other.takedownDefense == takedownDefense) &&
            (identical(other.submissionAvg, submissionAvg) ||
                other.submissionAvg == submissionAvg));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sigStrikesPerMin,
      strikingAccuracy,
      sigStrikesAbsorbedPerMin,
      strikingDefense,
      takedownAvg,
      takedownAccuracy,
      takedownDefense,
      submissionAvg);

  @override
  String toString() {
    return 'FighterStats(sigStrikesPerMin: $sigStrikesPerMin, strikingAccuracy: $strikingAccuracy, sigStrikesAbsorbedPerMin: $sigStrikesAbsorbedPerMin, strikingDefense: $strikingDefense, takedownAvg: $takedownAvg, takedownAccuracy: $takedownAccuracy, takedownDefense: $takedownDefense, submissionAvg: $submissionAvg)';
  }
}

/// @nodoc
abstract mixin class _$FighterStatsCopyWith<$Res>
    implements $FighterStatsCopyWith<$Res> {
  factory _$FighterStatsCopyWith(
          _FighterStats value, $Res Function(_FighterStats) _then) =
      __$FighterStatsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double sigStrikesPerMin,
      double strikingAccuracy,
      double sigStrikesAbsorbedPerMin,
      double strikingDefense,
      double takedownAvg,
      double takedownAccuracy,
      double takedownDefense,
      double submissionAvg});
}

/// @nodoc
class __$FighterStatsCopyWithImpl<$Res>
    implements _$FighterStatsCopyWith<$Res> {
  __$FighterStatsCopyWithImpl(this._self, this._then);

  final _FighterStats _self;
  final $Res Function(_FighterStats) _then;

  /// Create a copy of FighterStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sigStrikesPerMin = null,
    Object? strikingAccuracy = null,
    Object? sigStrikesAbsorbedPerMin = null,
    Object? strikingDefense = null,
    Object? takedownAvg = null,
    Object? takedownAccuracy = null,
    Object? takedownDefense = null,
    Object? submissionAvg = null,
  }) {
    return _then(_FighterStats(
      sigStrikesPerMin: null == sigStrikesPerMin
          ? _self.sigStrikesPerMin
          : sigStrikesPerMin // ignore: cast_nullable_to_non_nullable
              as double,
      strikingAccuracy: null == strikingAccuracy
          ? _self.strikingAccuracy
          : strikingAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      sigStrikesAbsorbedPerMin: null == sigStrikesAbsorbedPerMin
          ? _self.sigStrikesAbsorbedPerMin
          : sigStrikesAbsorbedPerMin // ignore: cast_nullable_to_non_nullable
              as double,
      strikingDefense: null == strikingDefense
          ? _self.strikingDefense
          : strikingDefense // ignore: cast_nullable_to_non_nullable
              as double,
      takedownAvg: null == takedownAvg
          ? _self.takedownAvg
          : takedownAvg // ignore: cast_nullable_to_non_nullable
              as double,
      takedownAccuracy: null == takedownAccuracy
          ? _self.takedownAccuracy
          : takedownAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      takedownDefense: null == takedownDefense
          ? _self.takedownDefense
          : takedownDefense // ignore: cast_nullable_to_non_nullable
              as double,
      submissionAvg: null == submissionAvg
          ? _self.submissionAvg
          : submissionAvg // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on
