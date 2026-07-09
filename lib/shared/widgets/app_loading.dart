import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';

/// Centered spinner with an optional label. Use for full-screen loads where a
/// skeleton isn't warranted.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: c.brand),
          ),
          if (label != null) ...[
            AppSpacing.vGapMd,
            Text(label!, style: context.text.bodySmall?.copyWith(
              color: c.textSecondary,
            )),
          ],
        ],
      ),
    );
  }
}
