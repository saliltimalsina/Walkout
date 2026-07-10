import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/shared/widgets/widgets.dart';

import '../../application/gallery_providers.dart';
import '../../application/widget_pinner.dart';
import 'pin_help_sheet.dart';

/// The gallery's "Add to home screen" action. Fires the system pin sheet when
/// the launcher supports it, otherwise opens the manual-instructions sheet —
/// the button is never a dead end.
class AddWidgetButton extends ConsumerWidget {
  const AddWidgetButton({
    super.key,
    required this.providerClass,
    required this.name,
    this.label,
    this.variant = AppButtonVariant.secondary,
    this.size = AppButtonSize.sm,
  });

  final String providerClass;
  final String name;

  /// Overrides the default "Add" / "How to add" label.
  final String? label;
  final AppButtonVariant variant;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supported = ref.watch(pinSupportedProvider).valueOrNull ?? false;

    return AppButton(
      label: label ?? (supported ? 'Add' : 'How to add'),
      icon: supported ? Icons.add_rounded : Icons.help_outline_rounded,
      variant: variant,
      size: size,
      isFullWidth: true,
      onPressed: () => _add(context, supported),
    );
  }

  Future<void> _add(BuildContext context, bool supported) async {
    HapticFeedback.selectionClick();
    if (!supported) {
      await showPinHelpSheet(context, name: name);
      return;
    }
    try {
      await WidgetPinner.pin(providerClass);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name — check your home screen')),
        );
      }
    } catch (_) {
      if (context.mounted) await showPinHelpSheet(context, name: name);
    }
  }
}
