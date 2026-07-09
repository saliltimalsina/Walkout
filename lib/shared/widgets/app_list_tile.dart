import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';
import 'app_card.dart';

/// Standard row: optional leading widget, title/subtitle, trailing widget.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.padding = AppSpacing.allMd,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AppCard(
      onTap: onTap,
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, AppSpacing.hGapMd],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  AppSpacing.vGapXs,
                  Text(
                    subtitle!,
                    style: context.text.bodySmall?.copyWith(
                      color: c.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[AppSpacing.hGapMd, trailing!],
          if (showChevron) ...[
            AppSpacing.hGapSm,
            Icon(AppIcons.forward, size: 20, color: c.textTertiary),
          ],
        ],
      ),
    );
  }
}
