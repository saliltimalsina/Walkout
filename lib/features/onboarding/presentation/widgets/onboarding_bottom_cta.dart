import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/app_button.dart';

/// Pinned bottom action shared by onboarding steps: a primary CTA plus an
/// optional footnote line beneath it.
class OnboardingBottomCta extends StatelessWidget {
  const OnboardingBottomCta({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.icon,
    this.footnote,
    this.footnoteIcon,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData? icon;
  final String? footnote;
  final IconData? footnoteIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: label,
            icon: icon,
            isFullWidth: true,
            size: AppButtonSize.lg,
            onPressed: enabled ? onPressed : null,
          ),
          if (footnote != null) ...[
            AppSpacing.vGapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (footnoteIcon != null) ...[
                  Icon(footnoteIcon, size: 13, color: c.textTertiary),
                  AppSpacing.hGapXs,
                ],
                Flexible(
                  child: Text(
                    footnote!,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall
                        ?.copyWith(color: c.textTertiary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
