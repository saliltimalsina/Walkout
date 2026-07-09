import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';

/// Reassurance card shown near the bottom of an onboarding step
/// (icon + title + one-line explanation).
class OnboardingInfoCard extends StatelessWidget {
  const OnboardingInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: AppSpacing.allMd,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.brandContainer,
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, color: c.brand, size: 22),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: context.text.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                AppSpacing.vGapXs,
                Text(message,
                    style: context.text.bodySmall
                        ?.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
