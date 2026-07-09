import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/core/providers/app_providers.dart';
import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/features/home_widgets/home_widget_service.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Dev tool: shifts the Living Widget's "now" so every calendar state
/// (fight week → fight night → result → aftermath) can be demoed against
/// the static bundled dataset. Also how store screenshots get staged.
class WidgetTimeTravelCard extends ConsumerStatefulWidget {
  const WidgetTimeTravelCard({super.key});

  @override
  ConsumerState<WidgetTimeTravelCard> createState() =>
      _WidgetTimeTravelCardState();
}

class _WidgetTimeTravelCardState extends ConsumerState<WidgetTimeTravelCard> {
  late int _hours =
      ref.read(storageServiceProvider).widgetTimeOffsetHours;
  bool _busy = false;

  Future<void> _apply(int hours) async {
    setState(() {
      _hours = hours;
      _busy = true;
    });
    final storage = ref.read(storageServiceProvider);
    await storage.setWidgetTimeOffsetHours(hours);
    await HomeWidgetService.refresh(storage);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    final presets = <(String, int)>[
      ('NOW', 0),
      ('+1D', 24),
      ('+2D', 48),
      ('+3D', 72),
      ('FIGHT NIGHT', 24 * 3 - 3), // near a card ~3 days out in the dataset
      ('+7D', 24 * 7),
    ];

    return AppCard(
      padding: AppSpacing.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: c.brand),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'WIDGET TIME TRAVEL',
                  style: t.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  _hours == 0 ? 'LIVE' : '+${_hours}H',
                  style: t.labelMedium?.copyWith(
                    color: _hours == 0 ? c.success : c.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          AppSpacing.vGapXs,
          Text(
            'Dev: shifts the Living Widget clock to demo fight-week states.',
            style: t.labelSmall?.copyWith(color: c.textTertiary),
          ),
          AppSpacing.vGapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (label, hours) in presets)
                Pressable(
                  onTap: _busy ? null : () => _apply(hours),
                  semanticLabel: label,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _hours == hours ? c.brand : c.surface,
                      borderRadius: AppRadius.brPill,
                      border: Border.all(
                        color: _hours == hours ? c.brand : c.border,
                      ),
                    ),
                    child: Text(
                      label,
                      style: t.labelSmall?.copyWith(
                        color: _hours == hours ? c.onBrand : c.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
