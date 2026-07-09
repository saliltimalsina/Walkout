import 'package:flutter/material.dart';

/// Hand-placed celebratory confetti: dots and rings, fully deterministic —
/// no Random, no clock. The same pixels render on every frame, so it is safe
/// behind RepaintBoundary exports and in golden tests.
class ConfettiPainter extends CustomPainter {
  const ConfettiPainter({required this.colors});

  final List<Color> colors;

  /// (dx, dy, radius, color index, is ring) — authored, never random.
  static const List<(double, double, double, int, bool)> _dots = [
    (0.07, 0.05, 2.4, 0, false),
    (0.17, 0.10, 1.7, 1, false),
    (0.28, 0.04, 2.9, 2, true),
    (0.41, 0.08, 1.6, 0, false),
    (0.55, 0.03, 2.2, 1, false),
    (0.67, 0.09, 3.1, 0, true),
    (0.80, 0.05, 1.8, 2, false),
    (0.92, 0.11, 2.5, 0, false),
    (0.05, 0.19, 1.5, 2, false),
    (0.19, 0.23, 2.8, 0, true),
    (0.35, 0.18, 1.8, 1, false),
    (0.52, 0.21, 2.3, 0, false),
    (0.69, 0.17, 1.6, 2, false),
    (0.87, 0.22, 2.9, 1, true),
    (0.10, 0.33, 2.1, 0, false),
    (0.29, 0.30, 1.5, 2, false),
    (0.50, 0.34, 2.6, 0, true),
    (0.71, 0.29, 1.9, 1, false),
    (0.90, 0.36, 2.2, 0, false),
    (0.06, 0.46, 1.7, 1, false),
    (0.24, 0.43, 2.4, 0, false),
    (0.47, 0.48, 1.5, 2, false),
    (0.65, 0.44, 2.7, 0, true),
    (0.85, 0.49, 1.8, 1, false),
    (0.13, 0.57, 2.0, 0, false),
    (0.37, 0.60, 1.5, 2, false),
    (0.59, 0.56, 2.3, 1, true),
    (0.79, 0.61, 1.7, 0, false),
    (0.22, 0.71, 1.9, 0, false),
    (0.68, 0.73, 1.6, 2, false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (dx, dy, r, ci, ring) in _dots) {
      final color = colors[ci % colors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: ring ? 0.4 : 0.65)
        ..style = ring ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(dx * size.width, dy * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
