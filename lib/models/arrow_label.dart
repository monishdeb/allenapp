import 'package:flutter/material.dart';

class ArrowLabel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final TagArrowDirection arrowDirection;

  const ArrowLabel({
    Key? key,
    required this.child,
    this.color = const Color(0xFFC0392B),
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    this.arrowDirection = TagArrowDirection.left,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TagClipper(arrowDirection),
      child: Container(
        color: color,
        padding: padding,
        child: Center(child: child),
      ),
    );
  }
}

enum TagArrowDirection { left, right }

class _TagClipper extends CustomClipper<Path> {
  final TagArrowDirection direction;
  _TagClipper(this.direction);

  @override
  Path getClip(Size size) {
    final double inset = size.height * 0.45;
    Path path = Path();
    if (direction == TagArrowDirection.left) {
      path.moveTo(inset, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(inset, size.height);
      path.lineTo(0, size.height / 2);
    } else {
      // Arrow points right
      path.moveTo(0, 0);
      path.lineTo(size.width - inset, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(size.width - inset, size.height);
      path.lineTo(0, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
