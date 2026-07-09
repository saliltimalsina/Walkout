import 'package:flutter/material.dart';

/// UFC-octagon visual language: a rectangle with chamfered corners.
class OctagonBorderShape extends ShapeBorder {
  const OctagonBorderShape({
    this.cut = 14,
    this.side = BorderSide.none,
  });

  final double cut;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  Path _path(Rect rect) {
    final c = cut.clamp(0, rect.shortestSide / 2).toDouble();
    return Path()
      ..moveTo(rect.left + c, rect.top)
      ..lineTo(rect.right - c, rect.top)
      ..lineTo(rect.right, rect.top + c)
      ..lineTo(rect.right, rect.bottom - c)
      ..lineTo(rect.right - c, rect.bottom)
      ..lineTo(rect.left + c, rect.bottom)
      ..lineTo(rect.left, rect.bottom - c)
      ..lineTo(rect.left, rect.top + c)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      _path(rect.deflate(side.width / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width
        ..color = side.color,
    );
  }

  @override
  ShapeBorder scale(double t) =>
      OctagonBorderShape(cut: cut * t, side: side.scale(t));
}

/// Chamfered-corner container — the Pick'Em surface primitive.
class OctagonCard extends StatelessWidget {
  const OctagonCard({
    super.key,
    required this.child,
    this.cut = 14,
    this.color,
    this.gradient,
    this.borderColor = const Color(0xFF262628),
    this.borderWidth = 1,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double cut;
  final Color? color;
  final Gradient? gradient;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: gradient == null ? (color ?? const Color(0xFF121214)) : null,
        gradient: gradient,
        shape: OctagonBorderShape(
          cut: cut,
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}
