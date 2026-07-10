import 'package:flutter/material.dart';

import 'package:walkout/core/theme/app_radius.dart';

/// Renders a real widget face composable, scaled to fit whatever width the
/// card gives it. Faces are pure widgets that expect their exact logical size
/// (329x158 or 158x158), so we lay them out at that size inside a [FittedBox].
class WidgetFacePreview extends StatelessWidget {
  const WidgetFacePreview({
    super.key,
    required this.face,
    required this.size,
  });

  final Widget face;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: size.aspectRatio,
      child: ClipRRect(
        // Launcher-like rounded corners, matching the real widget frame.
        borderRadius: AppRadius.brLg,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox.fromSize(
            size: size,
            child: IgnorePointer(child: face),
          ),
        ),
      ),
    );
  }
}
