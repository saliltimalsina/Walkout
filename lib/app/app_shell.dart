import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_icons.dart';
import '../core/utils/context_extensions.dart';

/// Bottom-navigation shell hosting the five primary branches. Uses GoRouter's
/// [StatefulNavigationShell] so each tab keeps its own navigation stack and
/// scroll position.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_Destination>[
    _Destination(AppIcons.home, 'Home'),
    _Destination(AppIcons.rankings, 'Rankings'),
    _Destination(Icons.track_changes_rounded, "Pick'Em"),
    _Destination(AppIcons.events, 'Events'),
    // The flagship tab: gold treatment so it reads as the app's marquee
    // feature even at rest.
    _Destination(AppIcons.widgets, 'Widgets', highlighted: true),
  ];

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      // Tapping the active tab returns to that branch's root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: _destinations[i],
                      selected: i == navigationShell.currentIndex,
                      onTap: () => _onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom nav item: red tick above the active icon, brand glow, letterspaced
/// overline label — no stock Material pill. Highlighted destinations swap the
/// whole treatment to gold and keep the icon lit even when inactive.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final highlighted = destination.highlighted;
    final tickColor = highlighted ? c.accent : c.brand;
    final color = highlighted
        ? (selected ? c.accent : c.accent.withValues(alpha: 0.75))
        : (selected ? c.brand : c.textTertiary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        selected: selected,
        button: true,
        label: destination.label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 18 : 0,
              height: 2.5,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: tickColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: tickColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            if (highlighted)
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.accent.withValues(alpha: selected ? 0.35 : 0.18),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(destination.icon, size: 23, color: color),
              )
            else
              Icon(destination.icon, size: 23, color: color),
            const SizedBox(height: 3),
            Text(
              destination.label.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                fontSize: 9,
                color: color,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.label, {this.highlighted = false});
  final IconData icon;
  final String label;

  /// Marquee-feature emphasis: gold accent instead of the standard treatment.
  final bool highlighted;
}
