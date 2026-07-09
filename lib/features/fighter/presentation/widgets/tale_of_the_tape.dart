import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/models.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Two-column grid of physical/biographical attributes.
class TaleOfTheTape extends StatelessWidget {
  const TaleOfTheTape({super.key, required this.fighter});

  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final items = <_TapeEntry>[
      _TapeEntry('Age', '${fighter.age}'),
      _TapeEntry('Height', '${fighter.heightCm} cm'),
      _TapeEntry('Reach', '${fighter.reachCm} cm'),
      _TapeEntry('Stance', fighter.stance),
      _TapeEntry('Weight Class', fighter.weightClass.label),
      _TapeEntry('Division limit', '${fighter.weightClass.limitLbs} lbs'),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TALE OF THE TAPE',
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          AppSpacing.vGapMd,
          for (var i = 0; i < items.length; i += 2) ...[
            if (i > 0) AppSpacing.vGapLg,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _TapeItem(entry: items[i])),
                AppSpacing.hGapMd,
                Expanded(
                  child: i + 1 < items.length
                      ? _TapeItem(entry: items[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TapeEntry {
  const _TapeEntry(this.label, this.value);

  final String label;
  final String value;
}

class _TapeItem extends StatelessWidget {
  const _TapeItem({required this.entry});

  final _TapeEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelMedium?.copyWith(color: c.textTertiary),
        ),
        AppSpacing.vGapXs,
        Text(
          entry.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyLarge?.copyWith(color: c.textPrimary),
        ),
      ],
    );
  }
}
