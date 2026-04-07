import 'package:flutter/material.dart';

/// ArrowLabel - rectangular label with optional triangular pointers on left/right.
/// Draws both fill and stroke in one CustomPainter so borders align and adjacent
/// labels can overlap without double-border seams.
class ArrowLabel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final bool showLeftPointer;
  final bool showRightPointer;
  final double pointerRatio; // pointer width as fraction of height
  final Color borderColor;
  final double borderWidth;

  const ArrowLabel({
    Key? key,
    required this.child,
    this.color = const Color(0xFFC0392B),
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    this.showLeftPointer = false,
    this.showRightPointer = true,
    this.pointerRatio = 0.45,
    this.borderColor = Colors.black,
    this.borderWidth = 1.6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Keep a fixed height at parent (e.g. kToolbarHeight) for predictable pointer size
    return CustomPaint(
      painter: _ArrowPainter(
        color: color,
        borderColor: borderColor,
        borderWidth: borderWidth,
        showLeft: showLeftPointer,
        showRight: showRightPointer,
        pointerRatio: pointerRatio,
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool showLeft;
  final bool showRight;
  final double pointerRatio;

  _ArrowPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.showLeft,
    required this.showRight,
    required this.pointerRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Paint fill = Paint()..color = color..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round;

    final double inset = size.height * pointerRatio;

    final Path path = Path();

    // Top edge
    path.moveTo(showLeft ? inset : 0, 0);
    path.lineTo(showRight ? size.width - inset : size.width, 0);

    // Right pointer tip (if present)
    if (showRight) path.lineTo(size.width, size.height / 2);
    path.lineTo(showRight ? size.width - inset : size.width, size.height);

    // Bottom edge
    path.lineTo(showLeft ? inset : 0, size.height);

    // Left pointer tip (if present)
    if (showLeft) path.lineTo(0, size.height / 2);

    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) {
    return old.color != color ||
        old.borderColor != borderColor ||
        old.borderWidth != borderWidth ||
        old.showLeft != showLeft ||
        old.showRight != showRight ||
        old.pointerRatio != pointerRatio;
  }
}
