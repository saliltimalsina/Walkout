import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'mock_data.dart';

/// Read access to the signed-in user's profile.
class ProfileRepository {
  const ProfileRepository();

  Future<UserProfile> getCurrent() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockData.currentUser;
  }
}

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => const ProfileRepository());
