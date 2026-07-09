import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String name,
    @Default('') String email,
    @Default('') String avatarUrl,
    @Default('') String handle,
    required DateTime memberSince,
    @Default(<String>[]) List<String> favoriteFighterIds,
    @Default(0) int predictionsMade,
    @Default(0) int predictionsCorrect,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
