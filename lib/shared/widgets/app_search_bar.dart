import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/context_extensions.dart';
import 'pressable.dart';

/// Search entry point. When [readOnly] it behaves as a tappable button that
/// routes to the search screen; otherwise it's a live input.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search fighters, events…',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.onClear,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final field = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(AppIcons.search, size: 20, color: c.textTertiary),
          AppSpacing.hGapSm,
          Expanded(
            child: readOnly
                ? Text(hint, style: context.text.bodyMedium?.copyWith(
                    color: c.textTertiary,
                  ))
                : TextField(
                    controller: controller,
                    onChanged: onChanged,
                    autofocus: autofocus,
                    style: context.text.bodyMedium,
                    cursorColor: c.brand,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintText: hint,
                      hintStyle: context.text.bodyMedium?.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ),
          ),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Icon(AppIcons.close, size: 18, color: c.textTertiary),
            ),
        ],
      ),
    );

    if (readOnly) {
      return Pressable(onTap: onTap, semanticLabel: hint, child: field);
    }
    return field;
  }
}
