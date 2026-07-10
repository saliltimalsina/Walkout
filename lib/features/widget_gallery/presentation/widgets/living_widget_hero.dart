import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/features/home_widgets/faces/living_face.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../../application/gallery_catalog.dart';
import '../../application/gallery_providers.dart';
import 'add_widget_button.dart';
import 'widget_face_preview.dart';

/// The gallery's flagship section: The Living Widget with a live preview of
/// its current calendar state and a first-class Add action. Gold-framed so it
/// reads as the headliner of the shelf.
class LivingWidgetHero extends ConsumerWidget {
  const LivingWidgetHero({super.key});

  static const _faceSize = Size(329, 158);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final preview = ref.watch(livingPreviewProvider);

    // Gradient gold frame: a 1.5px gradient shell around the card surface.
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.accent.withValues(alpha: 0.9),
            c.accent.withValues(alpha: 0.25),
            c.border,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.lg - 1.5),
          ),
        ),
        padding: AppSpacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: c.accent),
                AppSpacing.hGapXs,
                Text(
                  'FLAGSHIP',
                  style: t.labelSmall?.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            AppSpacing.vGapSm,
            Text(
              GalleryCatalog.livingName.toUpperCase(),
              style: t.headlineSmall?.copyWith(letterSpacing: 0.5),
            ),
            AppSpacing.vGapXs,
            Text(
              GalleryCatalog.livingBlurb,
              style: t.bodySmall?.copyWith(color: c.textSecondary),
            ),
            AppSpacing.vGapMd,
            preview.when(
              loading: () => AspectRatio(
                aspectRatio: _faceSize.aspectRatio,
                child: ClipRRect(
                  borderRadius: AppRadius.brLg,
                  child: ColoredBox(color: c.skeleton),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (p) => WidgetFacePreview(
                face: LivingFace(snapshot: p.snapshot, now: p.now),
                size: _faceSize,
              ),
            ),
            AppSpacing.vGapMd,
            const AddWidgetButton(
              providerClass: 'LivingWidgetProvider',
              name: GalleryCatalog.livingName,
              label: 'Add to Home Screen',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.md,
            ),
          ],
        ),
      ),
    );
  }
}
