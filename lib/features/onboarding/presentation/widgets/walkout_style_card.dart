import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_radius.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/pressable.dart';
import 'hex_icon.dart';

/// A selectable fan-style ("walkout") archetype.
class FanStyle {
  const FanStyle({
    required this.title,
    required this.description,
    required this.tags,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final List<String> tags;
  final IconData icon;
  final Color color;
}

const fanStyles = <FanStyle>[
  FanStyle(
    title: 'The Finisher',
    description: 'You love knockouts, submissions, and highlight-reel moments.',
    tags: ['Action Seeker', 'Big Moment Fan'],
    icon: Icons.sports_mma_rounded,
    color: Color(0xFFEF4444),
  ),
  FanStyle(
    title: 'The Analyst',
    description: 'You break down every stat, every matchup, every detail.',
    tags: ['Stat Driven', 'Deep Thinker'],
    icon: Icons.query_stats_rounded,
    color: Color(0xFFFACC15),
  ),
  FanStyle(
    title: 'The Matchmaker',
    description: 'You love predicting fights and building the perfect card.',
    tags: ['Predictor', 'Fantasy Builder'],
    icon: Icons.handshake_rounded,
    color: Color(0xFF8B5CF6),
  ),
  FanStyle(
    title: 'The Prospect Scout',
    description: "You're always looking for the next big thing before anyone else.",
    tags: ['Future Focused', 'Talent Spotter'],
    icon: Icons.travel_explore_rounded,
    color: Color(0xFF3B82F6),
  ),
  FanStyle(
    title: 'The Casual',
    description: "You're here for the vibes, the big fights, and the experience.",
    tags: ['Fun First', 'Big Fan Energy'],
    icon: Icons.celebration_rounded,
    color: Color(0xFF22C55E),
  ),
];

class WalkoutStyleCard extends StatelessWidget {
  const WalkoutStyleCard({
    super.key,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final FanStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.brLg,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: selected ? style.color.withValues(alpha: 0.06) : c.surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: selected ? c.brand : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HexIcon(icon: style.icon, color: style.color, size: 50),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(style.title.toUpperCase(),
                      style: context.text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(style.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall
                          ?.copyWith(color: c.textSecondary, height: 1.25)),
                  AppSpacing.vGapXs,
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final t in style.tags)
                        _Tag(label: t, color: style.color),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brPill,
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(label,
          style: context.text.labelSmall?.copyWith(color: color)),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.brand : Colors.transparent,
        border: Border.all(color: selected ? c.brand : c.border, width: 2),
      ),
      child: selected
          ? Icon(Icons.circle, size: 8, color: c.onBrand)
          : null,
    );
  }
}
