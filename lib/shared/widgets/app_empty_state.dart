import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';
import 'app_button.dart';

/// Friendly placeholder for empty lists / no-results / error states.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = AppIcons.empty,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  factory AppEmptyState.error({
    String title = 'Something went wrong',
    String? message,
    String actionLabel = 'Retry',
    VoidCallback? onRetry,
  }) =>
      AppEmptyState(
        title: title,
        message: message,
        icon: AppIcons.error,
        actionLabel: onRetry != null ? actionLabel : null,
        onAction: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: AppSpacing.allXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: Icon(icon, size: 32, color: c.textTertiary),
            ),
            AppSpacing.vGapLg,
            Text(
              title,
              style: context.text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppSpacing.vGapSm,
              Text(
                message!,
                style: context.text.bodyMedium?.copyWith(
                  color: c.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.vGapLg,
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
