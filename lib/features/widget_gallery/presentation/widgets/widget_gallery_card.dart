import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/features/home_widgets/face_registry.dart';
import 'package:walkout/shared/widgets/widgets.dart';

import '../../application/gallery_catalog.dart';
import 'add_widget_button.dart';
import 'widget_face_preview.dart';

/// One widget on the marketplace shelf: live preview, name, size tag, blurb
/// and the Add action. Works at full width (4x2 faces) and in a two-column
/// grid (2x2 faces).
class WidgetGalleryCard extends StatelessWidget {
  const WidgetGalleryCard({super.key, required this.spec});

  final FaceSpec spec;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final entry = GalleryCatalog.entryFor(spec.key);
    final configurable = FaceRegistry.configurableKeys.contains(spec.key);
    final sizeTag = spec.size == FaceRegistry.four2 ? '4×2' : '2×2';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WidgetFacePreview(face: spec.face, size: spec.size),
          AppSpacing.vGapMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.hGapSm,
              Text(
                sizeTag,
                style: t.labelSmall?.copyWith(
                  color: c.textTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          AppSpacing.vGapXs,
          Text(
            entry.blurb,
            style: t.labelSmall?.copyWith(color: c.textTertiary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (configurable) ...[
            AppSpacing.vGapSm,
            Row(
              children: [
                Icon(AppIcons.profile, size: 12, color: c.accent),
                AppSpacing.hGapXs,
                Flexible(
                  child: Text(
                    'PICK YOUR FIGHTER',
                    style: t.labelSmall?.copyWith(
                      color: c.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.vGapMd,
          AddWidgetButton(
            providerClass: spec.providerClass,
            name: entry.name,
          ),
        ],
      ),
    );
  }
}
