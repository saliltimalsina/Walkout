import 'package:flutter/material.dart';

import 'package:walkout/core/utils/context_extensions.dart';
import 'package:walkout/shared/models/fighter.dart';
import 'corner_slot.dart';

/// The implied octagon of five slots. [fighters] is a length-5 list where nulls
/// render as empty "+" targets. A faint closed outline connects the slots and
/// thin spokes run to the centre, evoking the cage — the shape strengthens as
/// portraits fill in.
class CornerOctagon extends StatelessWidget {
  const CornerOctagon({
    super.key,
    required this.fighters,
    required this.onRemove,
    this.height = 250,
  });

  final List<Fighter?> fighters; // length 5
  final void Function(int index) onRemove;
  final double height;

  // Fractional slot centres (x, y) within the box — apex, two shoulders, two base.
  static const _centers = <Offset>[
    Offset(0.5, 0.12),
    Offset(0.14, 0.40),
    Offset(0.86, 0.40),
    Offset(0.30, 0.82),
    Offset(0.70, 0.82),
  ];
  static const _hub = Offset(0.5, 0.54);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const slot = 62.0;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = height;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OctagonPainter(
                    centers: _centers,
                    hub: _hub,
                    color: c.border,
                    filled: [
                      for (var i = 0; i < _centers.length; i++)
                        i < fighters.length && fighters[i] != null,
                    ],
                    brand: c.brand,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: _hub.dy * h - 22,
                child: Column(
                  children: [
                    Text('YOUR',
                        style: context.text.labelSmall?.copyWith(
                            color: c.textTertiary, letterSpacing: 2)),
                    Text('CORNER',
                        style: context.text.titleLarge?.copyWith(
                            color: c.brand, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              for (var i = 0; i < _centers.length; i++)
                Positioned(
                  left: _centers[i].dx * w - (slot + 8) / 2,
                  top: _centers[i].dy * h - slot / 2,
                  width: slot + 8,
                  child: Center(
                    child: CornerSlot(
                      fighter: i < fighters.length ? fighters[i] : null,
                      size: slot,
                      onRemove: () => onRemove(i),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OctagonPainter extends CustomPainter {
  _OctagonPainter({
    required this.centers,
    required this.hub,
    required this.color,
    required this.filled,
    required this.brand,
  });

  final List<Offset> centers;
  final Offset hub;
  final Color color;
  final List<bool> filled;
  final Color brand;

  // Closed perimeter through all five slots (apex -> shoulders -> base -> back).
  static const _perimeter = [0, 2, 4, 3, 1];

  @override
  void paint(Canvas canvas, Size size) {
    Offset px(Offset f) => Offset(f.dx * size.width, f.dy * size.height);

    final line = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final spoke = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 1;

    final hubPx = px(hub);

    // Spokes to the hub.
    for (final ctr in centers) {
      canvas.drawLine(px(ctr), hubPx, spoke);
    }

    // Perimeter (closed). Segments between two filled slots glow brand.
    for (var i = 0; i < _perimeter.length; i++) {
      final a = _perimeter[i];
      final b = _perimeter[(i + 1) % _perimeter.length];
      final lit = filled[a] && filled[b];
      canvas.drawLine(
        px(centers[a]),
        px(centers[b]),
        lit
            ? (Paint()
              ..color = brand.withValues(alpha: 0.7)
              ..strokeWidth = 1.6
              ..style = PaintingStyle.stroke)
            : line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OctagonPainter old) =>
      old.color != color || old.brand != brand || !_sameFilled(old.filled);

  bool _sameFilled(List<bool> other) {
    if (other.length != filled.length) return false;
    for (var i = 0; i < filled.length; i++) {
      if (other[i] != filled[i]) return false;
    }
    return true;
  }
}
