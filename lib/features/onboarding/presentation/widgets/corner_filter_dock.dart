import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/app_chip.dart';
import 'package:walkout/shared/widgets/app_search_bar.dart';
import '../providers/corner_providers.dart';

/// Pinned search + filter dock. Quick-filter and weight-class pills stay put
/// while the fighter list scrolls beneath.
class CornerFilterDock extends ConsumerStatefulWidget {
  const CornerFilterDock({super.key});

  @override
  ConsumerState<CornerFilterDock> createState() => _CornerFilterDockState();
}

class _CornerFilterDockState extends ConsumerState<CornerFilterDock> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quick = ref.watch(cornerQuickFilterProvider);
    final counts = ref.watch(quickFilterCountsProvider);
    final weight = ref.watch(cornerWeightFilterProvider);
    final weightClasses = ref.watch(availableWeightClassesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSearchBar(
          controller: _controller,
          hint: 'Search fighters',
          onChanged: (v) =>
              ref.read(cornerSearchProvider.notifier).state = v,
          onClear: _controller.text.isEmpty
              ? null
              : () {
                  _controller.clear();
                  ref.read(cornerSearchProvider.notifier).state = '';
                },
        ),
        AppSpacing.vGapMd,
        _Label('QUICK FILTERS'),
        AppSpacing.vGapSm,
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: QuickFilter.values.length,
            separatorBuilder: (_, __) => AppSpacing.hGapSm,
            itemBuilder: (context, i) {
              final q = QuickFilter.values[i];
              final n = counts[q] ?? 0;
              return AppChip(
                label: '${q.label} ($n)',
                selected: quick == q,
                onTap: () =>
                    ref.read(cornerQuickFilterProvider.notifier).state = q,
              );
            },
          ),
        ),
        AppSpacing.vGapMd,
        _Label('WEIGHT CLASS'),
        AppSpacing.vGapSm,
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: weightClasses.length + 1,
            separatorBuilder: (_, __) => AppSpacing.hGapSm,
            itemBuilder: (context, i) {
              if (i == 0) {
                return AppChip(
                  label: 'All',
                  selected: weight == null,
                  onTap: () => ref
                      .read(cornerWeightFilterProvider.notifier)
                      .state = null,
                );
              }
              final wc = weightClasses[i - 1];
              return AppChip(
                label: wc.abbr,
                selected: weight == wc,
                onTap: () =>
                    ref.read(cornerWeightFilterProvider.notifier).state = wc,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.labelSmall?.copyWith(
        color: context.colors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}
