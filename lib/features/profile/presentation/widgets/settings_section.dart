import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:walkout/core/providers/app_providers.dart';
import 'package:walkout/core/router/app_routes.dart';
import 'package:walkout/core/theme/app_icons.dart';
import 'package:walkout/core/theme/app_spacing.dart';
import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/widgets/widgets.dart';

/// Account/app settings: appearance, notifications, and about.
class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Settings'),
        AppListTile(
          leading: Icon(AppIcons.theme, color: c.textSecondary),
          title: 'Appearance',
          subtitle: _themeLabel(themeMode),
          onTap: () => _showThemeSheet(context, ref, themeMode),
        ),
        AppSpacing.vGapSm,
        AppListTile(
          leading: Icon(AppIcons.notifications, color: c.textSecondary),
          title: 'Notifications',
          showChevron: true,
          onTap: () => context.push(AppRoutes.notifications),
        ),
        AppSpacing.vGapSm,
        AppListTile(
          leading: Icon(Icons.info_outline_rounded, color: c.textSecondary),
          title: 'About Walkout',
          subtitle: 'Version 1.0.0',
          showChevron: true,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Walkout · Version 1.0.0')),
          ),
        ),
      ],
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  Future<void> _showThemeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    return showAppBottomSheet(
      context: context,
      title: 'Appearance',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final mode in ThemeMode.values) ...[
            AppListTile(
              title: _themeLabel(mode),
              trailing: mode == current
                  ? Icon(AppIcons.check, color: sheetContext.colors.brand)
                  : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).set(mode);
                Navigator.of(sheetContext).pop();
              },
            ),
            if (mode != ThemeMode.values.last) AppSpacing.vGapSm,
          ],
        ],
      ),
    );
  }
}
