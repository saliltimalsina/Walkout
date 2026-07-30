import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_dataset.dart';
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

// ── Refresh ────────────────────────────────────────────────────
/// Everything derived from [AppDataset]. Invalidating these alone does NOT
/// re-fetch: they all read through [AppDataset.load], which serves a
/// process-lifetime singleton, so the reset below is what actually pulls new
/// data. Without it a pull-to-refresh re-renders the identical snapshot.
final _datasetProviders = <ProviderOrFamily>[
  fightersProvider,
  fighterProvider,
  championsProvider,
  fightersByWeightClassProvider,
  upcomingEventsProvider,
  pastEventsProvider,
  featuredEventProvider,
  eventProvider,
  rankingsProvider,
];

/// Events whose contents are fixed but whose *derived status* moves with the
/// clock — `getUpcoming`/`getPast`/`getFeatured` partition on `statusAt(now)`,
/// so re-running them against the cached dataset is enough to surface a LIVE
/// flip. No network, no reads.
final _clockDerivedProviders = <ProviderOrFamily>[
  upcomingEventsProvider,
  pastEventsProvider,
  featuredEventProvider,
];

/// Force a full re-read. For explicit user intent (pull-to-refresh, a retry
/// button) and for the dashboard's data-changed push, where new data is known
/// to exist. Also the recovery path for a session stuck on bundled data.
void refreshAppData(WidgetRef ref) {
  AppDataset.reset();
  for (final p in _datasetProviders) {
    ref.invalidate(p);
  }
}

/// Foreground refresh. Re-reads Firestore only when the cached snapshot has
/// aged past [maxAge] (or is bundled); otherwise it just re-filters the
/// clock-derived event lists. Resuming is frequent and free-tier reads are not,
/// so this must not turn every foreground into ~430 document reads.
void refreshAppDataIfStale(WidgetRef ref, {required Duration maxAge}) {
  if (AppDataset.isStale(maxAge)) {
    refreshAppData(ref);
    return;
  }
  for (final p in _clockDerivedProviders) {
    ref.invalidate(p);
  }
}
