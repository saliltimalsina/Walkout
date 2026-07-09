// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {
  String get id;
  String get name;
  String get email;
  String get avatarUrl;
  String get handle;
  DateTime get memberSince;
  List<String> get favoriteFighterIds;
  int get predictionsMade;
  int get predictionsCorrect;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<UserProfile> get copyWith =>
      _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UserProfile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.memberSince, memberSince) ||
                other.memberSince == memberSince) &&
            const DeepCollectionEquality()
                .equals(other.favoriteFighterIds, favoriteFighterIds) &&
            (identical(other.predictionsMade, predictionsMade) ||
                other.predictionsMade == predictionsMade) &&
            (identical(other.predictionsCorrect, predictionsCorrect) ||
                other.predictionsCorrect == predictionsCorrect));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      email,
      avatarUrl,
      handle,
      memberSince,
      const DeepCollectionEquality().hash(favoriteFighterIds),
      predictionsMade,
      predictionsCorrect);

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, email: $email, avatarUrl: $avatarUrl, handle: $handle, memberSince: $memberSince, favoriteFighterIds: $favoriteFighterIds, predictionsMade: $predictionsMade, predictionsCorrect: $predictionsCorrect)';
  }
}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) _then) =
      _$UserProfileCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String email,
      String avatarUrl,
      String handle,
      DateTime memberSince,
      List<String> favoriteFighterIds,
      int predictionsMade,
      int predictionsCorrect});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res> implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? avatarUrl = null,
    Object? handle = null,
    Object? memberSince = null,
    Object? favoriteFighterIds = null,
    Object? predictionsMade = null,
    Object? predictionsCorrect = null,
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
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: null == avatarUrl
          ? _self.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String,
      handle: null == handle
          ? _self.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String,
      memberSince: null == memberSince
          ? _self.memberSince
          : memberSince // ignore: cast_nullable_to_non_nullable
              as DateTime,
      favoriteFighterIds: null == favoriteFighterIds
          ? _self.favoriteFighterIds
          : favoriteFighterIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      predictionsMade: null == predictionsMade
          ? _self.predictionsMade
          : predictionsMade // ignore: cast_nullable_to_non_nullable
              as int,
      predictionsCorrect: null == predictionsCorrect
          ? _self.predictionsCorrect
          : predictionsCorrect // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _UserProfile implements UserProfile {
  const _UserProfile(
      {required this.id,
      required this.name,
      this.email = '',
      this.avatarUrl = '',
      this.handle = '',
      required this.memberSince,
      final List<String> favoriteFighterIds = const <String>[],
      this.predictionsMade = 0,
      this.predictionsCorrect = 0})
      : _favoriteFighterIds = favoriteFighterIds;
  factory _UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String email;
  @override
  @JsonKey()
  final String avatarUrl;
  @override
  @JsonKey()
  final String handle;
  @override
  final DateTime memberSince;
  final List<String> _favoriteFighterIds;
  @override
  @JsonKey()
  List<String> get favoriteFighterIds {
    if (_favoriteFighterIds is EqualUnmodifiableListView)
      return _favoriteFighterIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_favoriteFighterIds);
  }

  @override
  @JsonKey()
  final int predictionsMade;
  @override
  @JsonKey()
  final int predictionsCorrect;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UserProfileCopyWith<_UserProfile> get copyWith =>
      __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UserProfileToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UserProfile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.handle, handle) || other.handle == handle) &&
            (identical(other.memberSince, memberSince) ||
                other.memberSince == memberSince) &&
            const DeepCollectionEquality()
                .equals(other._favoriteFighterIds, _favoriteFighterIds) &&
            (identical(other.predictionsMade, predictionsMade) ||
                other.predictionsMade == predictionsMade) &&
            (identical(other.predictionsCorrect, predictionsCorrect) ||
                other.predictionsCorrect == predictionsCorrect));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      email,
      avatarUrl,
      handle,
      memberSince,
      const DeepCollectionEquality().hash(_favoriteFighterIds),
      predictionsMade,
      predictionsCorrect);

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, email: $email, avatarUrl: $avatarUrl, handle: $handle, memberSince: $memberSince, favoriteFighterIds: $favoriteFighterIds, predictionsMade: $predictionsMade, predictionsCorrect: $predictionsCorrect)';
  }
}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(
          _UserProfile value, $Res Function(_UserProfile) _then) =
      __$UserProfileCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String email,
      String avatarUrl,
      String handle,
      DateTime memberSince,
      List<String> favoriteFighterIds,
      int predictionsMade,
      int predictionsCorrect});
}

/// @nodoc
class __$UserProfileCopyWithImpl<$Res> implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? avatarUrl = null,
    Object? handle = null,
    Object? memberSince = null,
    Object? favoriteFighterIds = null,
    Object? predictionsMade = null,
    Object? predictionsCorrect = null,
  }) {
    return _then(_UserProfile(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: null == avatarUrl
          ? _self.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String,
      handle: null == handle
          ? _self.handle
          : handle // ignore: cast_nullable_to_non_nullable
              as String,
      memberSince: null == memberSince
          ? _self.memberSince
          : memberSince // ignore: cast_nullable_to_non_nullable
              as DateTime,
      favoriteFighterIds: null == favoriteFighterIds
          ? _self._favoriteFighterIds
          : favoriteFighterIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      predictionsMade: null == predictionsMade
          ? _self.predictionsMade
          : predictionsMade // ignore: cast_nullable_to_non_nullable
              as int,
      predictionsCorrect: null == predictionsCorrect
          ? _self.predictionsCorrect
          : predictionsCorrect // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
