import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_repository.dart';
import '../data/fighter_repository.dart';
import '../data/notification_repository.dart';
import '../data/profile_repository.dart';
import '../data/ranking_repository.dart';
import '../models/event.dart';
import '../models/fighter.dart';
import '../models/notification_item.dart';
import '../models/ranking.dart';
import '../models/user_profile.dart';
import '../models/weight_class.dart';

// ── Fighters ───────────────────────────────────────────────────
final fightersProvider = FutureProvider<List<Fighter>>((ref) {
  return ref.watch(fighterRepositoryProvider).getAll();
});

final fighterProvider =
    FutureProvider.family<Fighter, String>((ref, id) {
  return ref.watch(fighterRepositoryProvider).getById(id);
});

final championsProvider = FutureProvider<List<Fighter>>((ref) {
  return ref.watch(fighterRepositoryProvider).getChampions();
});

final fightersByWeightClassProvider =
    FutureProvider.family<List<Fighter>, WeightClass>((ref, wc) {
  return ref.watch(fighterRepositoryProvider).getByWeightClass(wc);
});

// ── Events ─────────────────────────────────────────────────────
final upcomingEventsProvider = FutureProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).getUpcoming();
});

final pastEventsProvider = FutureProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).getPast();
});

final featuredEventProvider = FutureProvider<Event?>((ref) {
  return ref.watch(eventRepositoryProvider).getFeatured();
});

final eventProvider = FutureProvider.family<Event, String>((ref, id) {
  return ref.watch(eventRepositoryProvider).getById(id);
});

// ── Rankings ───────────────────────────────────────────────────
final rankingsProvider = FutureProvider<List<DivisionRanking>>((ref) {
  return ref.watch(rankingRepositoryProvider).getAll();
});

// ── Notifications ──────────────────────────────────────────────
final notificationsProvider =
    FutureProvider<List<NotificationItem>>((ref) {
  return ref.watch(notificationRepositoryProvider).getAll();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (items) => items.where((n) => !n.read).length,
    orElse: () => 0,
  );
});

// ── Profile ────────────────────────────────────────────────────
final currentUserProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).getCurrent();
});
