import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_spacing.dart';

/// "By signing up, you agree to our Terms of Use and Privacy Policy" footer with
/// tappable links, laid out over the dark backdrop.
class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key, this.onTerms, this.onPrivacy});

  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.white70);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('By signing up, you agree to our',
            textAlign: TextAlign.center, style: base),
        AppSpacing.vGapXs,
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            _Link('Terms of Use', onTap: onTerms, base: base),
            Text('and', style: base),
            _Link('Privacy Policy', onTap: onPrivacy, base: base),
          ],
        ),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, {required this.onTap, required this.base});

  final String label;
  final VoidCallback? onTap;
  final TextStyle? base;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: base?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
        ),
      ),
    );
  }
}
