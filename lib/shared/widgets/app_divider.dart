import 'package:flutter/material.dart';

import '../../core/utils/context_extensions.dart';

/// Thin hairline divider using the theme's divider token.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.indent = 0, this.endIndent = 0});

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: context.colors.divider,
    );
  }
}
