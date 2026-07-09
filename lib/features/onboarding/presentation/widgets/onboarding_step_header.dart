import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';

/// Segmented step-progress bar shared across onboarding steps.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.current, // 0-based
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 180,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current ? c.brand : c.border,
                  borderRadius: AppRadius.brPill,
                ),
              ),
            ),
            if (i != total - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// Standard onboarding header: back · progress · Skip, with an optional
/// [trailing] widget shown just before Skip.
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.current,
    required this.total,
    required this.onBack,
    required this.onSkip,
    this.trailing,
  });

  final int current;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: c.textPrimary, size: 20),
            onPressed: onBack,
          ),
          Expanded(child: Center(child: OnboardingProgress(
            current: current,
            total: total,
          ))),
          if (trailing != null) ...[trailing!, AppSpacing.hGapSm],
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: c.textSecondary),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
