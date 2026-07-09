import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A countdown rendered as a UFC octagon: a full track octagon with a red
/// stroke that fills clockwise as the fight approaches, a soft inner glow,
/// and centered content (days number + label).
class OctagonRing extends StatelessWidget {
  const OctagonRing({
    super.key,
    required this.progress,
    required this.size,
    this.track = const Color(0xFF2A2A2C),
    this.fill = const Color(0xFFD20A0A),
    this.child,
  });

  /// 0..1 fraction of the octagon perimeter filled.
  final double progress;
  final double size;
  final Color track;
  final Color fill;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OctagonRingPainter(
          progress: progress.clamp(0.0, 1.0),
          track: track,
          fill: fill,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _OctagonRingPainter extends CustomPainter {
  _OctagonRingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 1);
    final cut = rect.shortestSide * 0.29;

    // Octagon vertices clockwise from top-left chamfer start.
    final pts = <Offset>[
      Offset(rect.left + cut, rect.top),
      Offset(rect.right - cut, rect.top),
      Offset(rect.right, rect.top + cut),
      Offset(rect.right, rect.bottom - cut),
      Offset(rect.right - cut, rect.bottom),
      Offset(rect.left + cut, rect.bottom),
      Offset(rect.left, rect.bottom - cut),
      Offset(rect.left, rect.top + cut),
    ];

    Path fullPath() {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final pt in pts.skip(1)) {
        p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    }

    // Faint filled interior for depth.
    canvas.drawPath(
      fullPath(),
      Paint()..color = const Color(0xFF141416),
    );

    // Track octagon.
    canvas.drawPath(
      fullPath(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.miter
        ..color = track,
    );

    // Progress: walk the perimeter, start at top-center, clockwise.
    if (progress > 0) {
      // Reorder so the path starts at the top edge midpoint.
      final segs = <Offset>[
        Offset((pts[0].dx + pts[1].dx) / 2, pts[0].dy), // top mid
        pts[1], pts[2], pts[3], pts[4], pts[5], pts[6], pts[7], pts[0],
        Offset((pts[0].dx + pts[1].dx) / 2, pts[0].dy),
      ];
      final total = _perimeter(segs);
      var remaining = total * progress;

      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.miter
        ..color = fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.miter
        ..color = fill;

      final path = Path()..moveTo(segs.first.dx, segs.first.dy);
      for (var i = 1; i < segs.length && remaining > 0; i++) {
        final a = segs[i - 1];
        final b = segs[i];
        final segLen = (b - a).distance;
        if (remaining >= segLen) {
          path.lineTo(b.dx, b.dy);
          remaining -= segLen;
        } else {
          final t = remaining / segLen;
          path.lineTo(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
          remaining = 0;
        }
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, line);
    }
  }

  double _perimeter(List<Offset> pts) {
    var sum = 0.0;
    for (var i = 1; i < pts.length; i++) {
      sum += (pts[i] - pts[i - 1]).distance;
    }
    return sum;
  }

  @override
  bool shouldRepaint(_OctagonRingPainter old) =>
      old.progress != progress || old.fill != fill;
}

/// Small helper: nudge a value off exact 0 so a just-started ring still shows.
double ringProgress(double raw) => raw <= 0 ? 0 : math.max(0.04, raw);
