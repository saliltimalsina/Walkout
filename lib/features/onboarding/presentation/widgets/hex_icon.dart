import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:walkout/core/utils/context_extensions.dart';

/// A flat-top hexagon badge with a colored, softly-glowing border and a centred
/// icon — the fan-style motif for the "What's your walkout?" step.
class HexIcon extends StatelessWidget {
  const HexIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 68,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexPainter(color: color, fill: context.colors.surface),
        child: Center(
          child: Icon(icon, color: color, size: size * 0.42),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter({required this.color, required this.fill});

  final Color color;
  final Color fill;

  Path _hex(Size size) {
    final path = Path();
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final r = math.min(w, h) / 2;
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30); // flat-top
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hex(size);
    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    // Glow.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Crisp border.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) =>
      old.color != color || old.fill != fill;
}
