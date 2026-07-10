import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/features/home_widgets/face_registry.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../../application/gallery_catalog.dart';
import '../../application/gallery_providers.dart';
import '../widgets/living_widget_hero.dart';
import '../widgets/widget_gallery_card.dart';
import '../widgets/widget_time_travel_card.dart';

/// The widget marketplace: every home-screen widget with a live preview and a
/// one-tap Add action. The Living Widget headlines; the board browses by
/// category below it.
class WidgetGalleryScreen extends ConsumerStatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  ConsumerState<WidgetGalleryScreen> createState() =>
      _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends ConsumerState<WidgetGalleryScreen> {
  GalleryCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final specsAsync = ref.watch(gallerySpecsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: const Text('Widgets'),
      ),
      body: specsAsync.when(
        loading: () => const AppLoading(label: 'Setting up the shelf…'),
        error: (_, __) => AppEmptyState.error(
          message: "We couldn't load the widget gallery. Please try again.",
          onRetry: () => ref.invalidate(gallerySpecsProvider),
        ),
        data: (specs) {
          final visible = _filter == null
              ? specs
              : specs
                  .where((s) =>
                      GalleryCatalog.entryFor(s.key).category == _filter)
                  .toList();
          final wide =
              visible.where((s) => s.size == FaceRegistry.four2).toList();
          final square =
              visible.where((s) => s.size == FaceRegistry.two2).toList();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              ResponsiveCenter(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your fights, on your home screen.',
                      style: t.bodyMedium?.copyWith(color: c.textSecondary),
                    ),
                    AppSpacing.vGapLg,
                    const LivingWidgetHero(),
                    AppSpacing.vGapXl,
                    _FilterChips(
                      selected: _filter,
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                    AppSpacing.vGapLg,
                    if (wide.isNotEmpty) ...[
                      const SectionHeader(title: '4×2 Widgets'),
                      for (final spec in wide) ...[
                        WidgetGalleryCard(spec: spec),
                        AppSpacing.vGapLg,
                      ],
                      AppSpacing.vGapSm,
                    ],
                    if (square.isNotEmpty) ...[
                      const SectionHeader(title: '2×2 Widgets'),
                      for (var i = 0; i < square.length; i += 2) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: WidgetGalleryCard(spec: square[i])),
                            AppSpacing.hGapMd,
                            Expanded(
                              child: i + 1 < square.length
                                  ? WidgetGalleryCard(spec: square[i + 1])
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        AppSpacing.vGapMd,
                      ],
                    ],
                    AppSpacing.vGapXl,
                    const WidgetTimeTravelCard(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final GalleryCategory? selected;
  final ValueChanged<GalleryCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          AppChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final category in GalleryCategory.values) ...[
            AppSpacing.hGapSm,
            AppChip(
              label: category.label,
              selected: selected == category,
              onTap: () => onChanged(category),
            ),
          ],
        ],
      ),
    );
  }
}
