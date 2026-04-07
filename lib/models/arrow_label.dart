import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ArrowLabel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final TagArrowDirection arrowDirection;
  final bool isFirst;
  final double pointerBorderWidth;

  const ArrowLabel({
    Key? key,
    required this.child,
    this.color = const Color(0xFFC0392B),
    this.padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    this.arrowDirection = TagArrowDirection.left,
    this.isFirst = false,
    this.pointerBorderWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    if (isFirst && arrowDirection == TagArrowDirection.left) {
      widgets.add(Image(image: AssetImage('images/navleft.png'), height: 29.0));
      //widgets.add(Container(width: 50, height: 50, child: SvgPicture.asset('images/navleft.svg'),));
    }
    else if (arrowDirection == TagArrowDirection.left) {
      widgets.add(Image(image: AssetImage('images/navlinkleft.png'), height: 29.0));
      //widgets.add(SvgPicture.asset('images/navlinkleft.svg'));
    }
    widgets.add(child);
    if (arrowDirection == TagArrowDirection.right) {
      widgets.add(Image(image: AssetImage('images/navright.png'), height: 31.0));
      //widgets.add(SvgPicture.asset('images/navright.svg', height: 26.0, width: 8.0,));
    }
    return Row(
      children: widgets
    );
    /*return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        child,
        // Colored arrow
        /*ClipPath(
          clipper: _TagClipper(arrowDirection),
          child: Container(
            color: color,
            padding: padding,
            child: Center(child: child),
          ),
        ),*/
        Image(image: AssetImage('images/navlinkleft.png'))
        // Border at pointer tip only
        /*CustomPaint(
          painter: _ArrowTipBorderPainter(
              color: Colors.black,
              direction: arrowDirection,
              borderWidth: pointerBorderWidth),
        ),*/
      ],
    );*/
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

// Draw only the arrow tip border
class _ArrowTipBorderPainter extends CustomPainter {
  final Color color;
  final TagArrowDirection direction;
  final double borderWidth;

  _ArrowTipBorderPainter(
      {required this.color, required this.direction, this.borderWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    Path tipPath = Path();
    final double inset = size.height * 0.45;

    if (direction == TagArrowDirection.left) {
      tipPath.moveTo(0, size.height / 2);
      tipPath.lineTo(inset, 0);
      tipPath.lineTo(inset, size.height);
      tipPath.close();
    } else {
      tipPath.moveTo(size.width, size.height / 2);
      tipPath.lineTo(size.width - inset, 0);
      tipPath.lineTo(size.width - inset, size.height);
      tipPath.close();
    }

    canvas.drawPath(tipPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
