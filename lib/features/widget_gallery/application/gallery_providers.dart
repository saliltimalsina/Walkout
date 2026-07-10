import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/core/providers/app_providers.dart';
import 'package:walkout/features/home_widgets/application/living_state.dart';
import 'package:walkout/features/home_widgets/face_registry.dart';
import 'package:walkout/features/home_widgets/widget_image_resolver.dart';
import 'package:walkout/shared/data/app_dataset.dart';
import 'package:walkout/shared/providers/favorites_controller.dart';

import 'widget_pinner.dart';

/// Whether the launcher supports the system pin-widget sheet. Gates every
/// "Add" button; false routes to the manual-instructions sheet instead.
final pinSupportedProvider =
    FutureProvider<bool>((_) => WidgetPinner.isSupported());

/// The full board of widget faces, built exactly the way
/// [HomeWidgetService.refresh] builds them — same dataset, same favorites,
/// same time offset — so the gallery previews are the real thing.
///
/// The [WidgetImageResolver.warm] call is load-bearing: face images resolve to
/// null for remote refs that haven't been downloaded yet, so previews built
/// before warming render without portraits.
final gallerySpecsProvider = FutureProvider<List<FaceSpec>>((ref) async {
  final dataset = await AppDataset.load();
  final favorites = ref.watch(favoritesProvider);
  final storage = ref.read(storageServiceProvider);
  final now =
      DateTime.now().add(Duration(hours: storage.widgetTimeOffsetHours));
  final specs = FaceRegistry.build(
    dataset: dataset,
    favorites: favorites,
    now: now,
  );
  await WidgetImageResolver.warm([for (final s in specs) ...s.assets]);
  return specs;
});

/// Everything the Living Widget hero needs to render a live preview.
final livingPreviewProvider =
    FutureProvider<({LivingSnapshot snapshot, DateTime now})>((ref) async {
  final dataset = await AppDataset.load();
  final favorites = ref.watch(favoritesProvider);
  final storage = ref.read(storageServiceProvider);
  final now =
      DateTime.now().add(Duration(hours: storage.widgetTimeOffsetHours));
  final snapshot = LivingStateMachine.resolve(
    now: now,
    events: dataset.events,
    favorites: favorites,
    fighterById: dataset.fighterById,
  );
  await WidgetImageResolver.warm([
    snapshot.fighter?.photo ?? '',
    snapshot.opponent?.photo ?? '',
  ]);
  return (snapshot: snapshot, now: now);
});
