import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/pressable.dart';

/// Static Fight Pass promo card.
class FightPassBanner extends StatelessWidget {
  const FightPassBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.brLg,
      child: Container(
        padding: AppSpacing.allLg,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.brand.withValues(alpha: 0.30), c.surface],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: AppRadius.brLg,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'UFC '),
                      TextSpan(text: 'FIGHT PASS',
                          style: TextStyle(color: c.brand)),
                    ]),
                    style: context.text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                  AppSpacing.vGapXs,
                  Text('Live events, replays and exclusive originals.',
                      style: context.text.bodySmall
                          ?.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            // The "Explore" pill only appears when the banner actually
            // leads somewhere.
            if (onTap != null) ...[
              AppSpacing.hGapMd,
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                    color: c.brand, borderRadius: AppRadius.brPill),
                child: Text('Explore',
                    style: context.text.labelLarge?.copyWith(
                        color: c.onBrand, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
