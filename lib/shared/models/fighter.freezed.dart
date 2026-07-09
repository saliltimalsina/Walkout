// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fighter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Fighter {
  String get id;
  String get name;
  String get nickname;
  WeightClass get weightClass;
  String get country;
  String get flag; // emoji flag
  FightRecord get record;
  int? get rankingPosition; // null when unranked
  bool get isChampion;
  String get imageUrl;
  int get heightCm;
  int get reachCm;
  int get age;
  String get stance;
  FighterStats get stats;
  String get bio;
  int get winsByKo;
  int get winsBySub;
  int get winsByDec;

  /// Create a copy of Fighter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FighterCopyWith<Fighter> get copyWith =>
      _$FighterCopyWithImpl<Fighter>(this as Fighter, _$identity);

  /// Serializes this Fighter to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Fighter &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.weightClass, weightClass) ||
                other.weightClass == weightClass) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.record, record) || other.record == record) &&
            (identical(other.rankingPosition, rankingPosition) ||
                other.rankingPosition == rankingPosition) &&
            (identical(other.isChampion, isChampion) ||
                other.isChampion == isChampion) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.reachCm, reachCm) || other.reachCm == reachCm) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.stance, stance) || other.stance == stance) &&
            (identical(other.stats, stats) || other.stats == stats) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.winsByKo, winsByKo) ||
                other.winsByKo == winsByKo) &&
            (identical(other.winsBySub, winsBySub) ||
                other.winsBySub == winsBySub) &&
            (identical(other.winsByDec, winsByDec) ||
                other.winsByDec == winsByDec));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        nickname,
        weightClass,
        country,
        flag,
        record,
        rankingPosition,
        isChampion,
        imageUrl,
        heightCm,
        reachCm,
        age,
        stance,
        stats,
        bio,
        winsByKo,
        winsBySub,
        winsByDec
      ]);

  @override
  String toString() {
    return 'Fighter(id: $id, name: $name, nickname: $nickname, weightClass: $weightClass, country: $country, flag: $flag, record: $record, rankingPosition: $rankingPosition, isChampion: $isChampion, imageUrl: $imageUrl, heightCm: $heightCm, reachCm: $reachCm, age: $age, stance: $stance, stats: $stats, bio: $bio, winsByKo: $winsByKo, winsBySub: $winsBySub, winsByDec: $winsByDec)';
  }
}

/// @nodoc
abstract mixin class $FighterCopyWith<$Res> {
  factory $FighterCopyWith(Fighter value, $Res Function(Fighter) _then) =
      _$FighterCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String nickname,
      WeightClass weightClass,
      String country,
      String flag,
      FightRecord record,
      int? rankingPosition,
      bool isChampion,
      String imageUrl,
      int heightCm,
      int reachCm,
      int age,
      String stance,
      FighterStats stats,
      String bio,
      int winsByKo,
      int winsBySub,
      int winsByDec});

  $FightRecordCopyWith<$Res> get record;
  $FighterStatsCopyWith<$Res> get stats;
}

/// @nodoc
class _$FighterCopyWithImpl<$Res> implements $FighterCopyWith<$Res> {
  _$FighterCopyWithImpl(this._self, this._then);

  final Fighter _self;
  final $Res Function(Fighter) _then;

  /// Create a copy of Fighter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nickname = null,
    Object? weightClass = null,
    Object? country = null,
    Object? flag = null,
    Object? record = null,
    Object? rankingPosition = freezed,
    Object? isChampion = null,
    Object? imageUrl = null,
    Object? heightCm = null,
    Object? reachCm = null,
    Object? age = null,
    Object? stance = null,
    Object? stats = null,
    Object? bio = null,
    Object? winsByKo = null,
    Object? winsBySub = null,
    Object? winsByDec = null,
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
      nickname: null == nickname
          ? _self.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      weightClass: null == weightClass
          ? _self.weightClass
          : weightClass // ignore: cast_nullable_to_non_nullable
              as WeightClass,
      country: null == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      flag: null == flag
          ? _self.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String,
      record: null == record
          ? _self.record
          : record // ignore: cast_nullable_to_non_nullable
              as FightRecord,
      rankingPosition: freezed == rankingPosition
          ? _self.rankingPosition
          : rankingPosition // ignore: cast_nullable_to_non_nullable
              as int?,
      isChampion: null == isChampion
          ? _self.isChampion
          : isChampion // ignore: cast_nullable_to_non_nullable
              as bool,
      imageUrl: null == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      heightCm: null == heightCm
          ? _self.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as int,
      reachCm: null == reachCm
          ? _self.reachCm
          : reachCm // ignore: cast_nullable_to_non_nullable
              as int,
      age: null == age
          ? _self.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      stance: null == stance
          ? _self.stance
          : stance // ignore: cast_nullable_to_non_nullable
              as String,
      stats: null == stats
          ? _self.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as FighterStats,
      bio: null == bio
          ? _self.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String,
      winsByKo: null == winsByKo
          ? _self.winsByKo
          : winsByKo // ignore: cast_nullable_to_non_nullable
              as int,
      winsBySub: null == winsBySub
          ? _self.winsBySub
          : winsBySub // ignore: cast_nullable_to_non_nullable
              as int,
      winsByDec: null == winsByDec
          ? _self.winsByDec
          : winsByDec // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }

  /// Create a copy of Fighter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FightRecordCopyWith<$Res> get record {
    return $FightRecordCopyWith<$Res>(_self.record, (value) {
      return _then(_self.copyWith(record: value));
    });
  }

  /// Create a copy of Fighter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FighterStatsCopyWith<$Res> get stats {
    return $FighterStatsCopyWith<$Res>(_self.stats, (value) {
      return _then(_self.copyWith(stats: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _Fighter extends Fighter {
  const _Fighter(
      {required this.id,
      required this.name,
      this.nickname = '',
      required this.weightClass,
      this.country = '',
      this.flag = '',
      this.record = const FightRecord(),
      this.rankingPosition,
      this.isChampion = false,
      this.imageUrl = '',
      this.heightCm = 0,
      this.reachCm = 0,
      this.age = 0,
      this.stance = 'Orthodox',
      this.stats = const FighterStats(),
      this.bio = '',
      this.winsByKo = 0,
      this.winsBySub = 0,
      this.winsByDec = 0})
      : super._();
  factory _Fighter.fromJson(Map<String, dynamic> json) =>
      _$FighterFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String nickname;
  @override
  final WeightClass weightClass;
  @override
  @JsonKey()
  final String country;
  @override
  @JsonKey()
  final String flag;
// emoji flag
  @override
  @JsonKey()
  final FightRecord record;
  @override
  final int? rankingPosition;
// null when unranked
  @override
  @JsonKey()
  final bool isChampion;
  @override
  @JsonKey()
  final String imageUrl;
  @override
  @JsonKey()
  final int heightCm;
  @override
  @JsonKey()
  final int reachCm;
  @override
  @JsonKey()
  final int age;
  @override
  @JsonKey()
  final String stance;
  @override
  @JsonKey()
  final FighterStats stats;
  @override
  @JsonKey()
  final String bio;
  @override
  @JsonKey()
  final int winsByKo;
  @override
  @JsonKey()
  final int winsBySub;
  @override
  @JsonKey()
  final int winsByDec;

  /// Create a copy of Fighter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FighterCopyWith<_Fighter> get copyWith =>
      __$FighterCopyWithImpl<_Fighter>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FighterToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Fighter &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.weightClass, weightClass) ||
                other.weightClass == weightClass) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.record, record) || other.record == record) &&
            (identical(other.rankingPosition, rankingPosition) ||
                other.rankingPosition == rankingPosition) &&
            (identical(other.isChampion, isChampion) ||
                other.isChampion == isChampion) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.reachCm, reachCm) || other.reachCm == reachCm) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.stance, stance) || other.stance == stance) &&
            (identical(other.stats, stats) || other.stats == stats) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.winsByKo, winsByKo) ||
                other.winsByKo == winsByKo) &&
            (identical(other.winsBySub, winsBySub) ||
                other.winsBySub == winsBySub) &&
            (identical(other.winsByDec, winsByDec) ||
                other.winsByDec == winsByDec));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        nickname,
        weightClass,
        country,
        flag,
        record,
        rankingPosition,
        isChampion,
        imageUrl,
        heightCm,
        reachCm,
        age,
        stance,
        stats,
        bio,
        winsByKo,
        winsBySub,
        winsByDec
      ]);

  @override
  String toString() {
    return 'Fighter(id: $id, name: $name, nickname: $nickname, weightClass: $weightClass, country: $country, flag: $flag, record: $record, rankingPosition: $rankingPosition, isChampion: $isChampion, imageUrl: $imageUrl, heightCm: $heightCm, reachCm: $reachCm, age: $age, stance: $stance, stats: $stats, bio: $bio, winsByKo: $winsByKo, winsBySub: $winsBySub, winsByDec: $winsByDec)';
  }
}

/// @nodoc
abstract mixin class _$FighterCopyWith<$Res> implements $FighterCopyWith<$Res> {
  factory _$FighterCopyWith(_Fighter value, $Res Function(_Fighter) _then) =
      __$FighterCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String nickname,
      WeightClass weightClass,
      String country,
      String flag,
      FightRecord record,
      int? rankingPosition,
      bool isChampion,
      String imageUrl,
      int heightCm,
      int reachCm,
      int age,
      String stance,
      FighterStats stats,
      String bio,
      int winsByKo,
      int winsBySub,
      int winsByDec});

  @override
  $FightRecordCopyWith<$Res> get record;
  @override
  $FighterStatsCopyWith<$Res> get stats;
}

/// @nodoc
class __$FighterCopyWithImpl<$Res> implements _$FighterCopyWith<$Res> {
  __$FighterCopyWithImpl(this._self, this._then);

  final _Fighter _self;
  final $Res Function(_Fighter) _then;

  /// Create a copy of Fighter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? nickname = null,
    Object? weightClass = null,
    Object? country = null,
    Object? flag = null,
    Object? record = null,
    Object? rankingPosition = freezed,
    Object? isChampion = null,
    Object? imageUrl = null,
    Object? heightCm = null,
    Object? reachCm = null,
    Object? age = null,
    Object? stance = null,
    Object? stats = null,
    Object? bio = null,
    Object? winsByKo = null,
    Object? winsBySub = null,
    Object? winsByDec = null,
  }) {
    return _then(_Fighter(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: null == nickname
          ? _self.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      weightClass: null == weightClass
          ? _self.weightClass
          : weightClass // ignore: cast_nullable_to_non_nullable
              as WeightClass,
      country: null == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      flag: null == flag
          ? _self.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String,
      record: null == record
          ? _self.record
          : record // ignore: cast_nullable_to_non_nullable
              as FightRecord,
      rankingPosition: freezed == rankingPosition
          ? _self.rankingPosition
          : rankingPosition // ignore: cast_nullable_to_non_nullable
              as int?,
      isChampion: null == isChampion
          ? _self.isChampion
          : isChampion // ignore: cast_nullable_to_non_nullable
              as bool,
      imageUrl: null == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      heightCm: null == heightCm
          ? _self.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as int,
      reachCm: null == reachCm
          ? _self.reachCm
          : reachCm // ignore: cast_nullable_to_non_nullable
              as int,
      age: null == age
          ? _self.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      stance: null == stance
          ? _self.stance
          : stance // ignore: cast_nullable_to_non_nullable
              as String,
      stats: null == stats
          ? _self.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as FighterStats,
      bio: null == bio
          ? _self.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String,
      winsByKo: null == winsByKo
          ? _self.winsByKo
          : winsByKo // ignore: cast_nullable_to_non_nullable
              as int,
      winsBySub: null == winsBySub
          ? _self.winsBySub
          : winsBySub // ignore: cast_nullable_to_non_nullable
              as int,
      winsByDec: null == winsByDec
          ? _self.winsByDec
          : winsByDec // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }

  /// Create a copy of Fighter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FightRecordCopyWith<$Res> get record {
    return $FightRecordCopyWith<$Res>(_self.record, (value) {
      return _then(_self.copyWith(record: value));
    });
  }

  /// Create a copy of Fighter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FighterStatsCopyWith<$Res> get stats {
    return $FighterStatsCopyWith<$Res>(_self.stats, (value) {
      return _then(_self.copyWith(stats: value));
    });
  }
}

// dart format on
