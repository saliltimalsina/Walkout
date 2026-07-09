import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';

import 'octagon_card.dart';

/// Sample friends league standings with the user slotted in by points.
/// League members are demo data until accounts exist.
class FriendsLeagueCard extends StatelessWidget {
  const FriendsLeagueCard({super.key, required this.userPoints});

  final int userPoints;

  static const _members = <(String, int)>[
    ('Momo', 1260),
    ('Alex', 1180),
    ('David', 1020),
    ('Sarah', 980),
    ('John', 870),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = <(String, int, bool)>[
      for (final m in _members) (m.$1, m.$2, false),
      ('You', userPoints, true),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return OctagonCard(
      cut: 14,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _StandingRow(
              rank: i + 1,
              name: rows[i].$1,
              points: rows[i].$2,
              isYou: rows[i].$3,
              showDivider: i > 0,
            ),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.rank,
    required this.name,
    required this.points,
    required this.isYou,
    required this.showDivider,
  });

  final int rank;
  final String name;
  final int points;
  final bool isYou;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final leader = rank == 1;

    // Edge accent: brand for the user's row, gold for the leader.
    final edge = isYou
        ? c.brand
        : leader
            ? c.accent.withValues(alpha: 0.85)
            : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color:
            isYou ? c.brand.withValues(alpha: 0.12) : Colors.transparent,
        border: Border(
          left: BorderSide(color: edge, width: 3),
          top: showDivider
              ? const BorderSide(color: Color(0xFF1D1D1F))
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: leader
                ? Icon(Icons.emoji_events_rounded,
                    size: 16, color: c.accent)
                : Text(
                    '$rank',
                    style: t.labelMedium?.copyWith(
                      color: isYou ? c.brand : c.textTertiary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          AppSpacing.hGapSm,
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isYou
                    ? c.brand.withValues(alpha: 0.8)
                    : leader
                        ? c.accent.withValues(alpha: 0.6)
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFF2A2A2C),
              child: Text(
                name[0],
                style: t.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isYou ? c.brand : c.textSecondary,
                ),
              ),
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(
                      fontWeight: isYou ? FontWeight.w800 : FontWeight.w600,
                      color: isYou ? c.brand : null,
                    ),
                  ),
                ),
                if (isYou) ...[
                  AppSpacing.hGapSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: ShapeDecoration(
                      color: c.brand.withValues(alpha: 0.16),
                      shape: const OctagonBorderShape(cut: 5),
                    ),
                    child: Text(
                      'YOU',
                      style: t.labelSmall?.copyWith(
                        fontSize: 9,
                        color: c.brand,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$points',
                  style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isYou
                        ? c.brand
                        : leader
                            ? c.accent
                            : null,
                  ),
                ),
                TextSpan(
                  text: ' PTS',
                  style: t.labelSmall?.copyWith(
                    fontSize: 9,
                    color: c.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
