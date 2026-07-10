import 'dart:io';

import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Manual add-a-widget instructions — shown when the launcher doesn't support
/// the system pin sheet (or on non-Android platforms).
Future<void> showPinHelpSheet(BuildContext context, {required String name}) {
  return showAppBottomSheet<void>(
    context: context,
    title: 'Add $name',
    builder: (context) => _PinHelpContent(name: name),
  );
}

class _PinHelpContent extends StatelessWidget {
  const _PinHelpContent({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    final steps = Platform.isAndroid
        ? const [
            'Long-press an empty spot on your home screen.',
            'Tap Widgets.',
            'Find Walkout in the list.',
            'Touch & hold the widget and drop it anywhere.',
          ]
        : const [
            'Walkout widgets are available on Android for now.',
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  '${i + 1}',
                  style: t.labelSmall?.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(steps[i], style: t.bodyMedium),
                ),
              ),
            ],
          ),
          if (i < steps.length - 1) AppSpacing.vGapMd,
        ],
        AppSpacing.vGapLg,
        AppButton(
          label: 'Got it',
          isFullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
