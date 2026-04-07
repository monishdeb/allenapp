import 'package:flutter/material.dart';
import 'arrow_label.dart';

/// BreadcrumbRow - builds a row of ArrowLabel items and overlaps them so
/// triangular pointers tuck into the previous item seamlessly.
///
/// NOTE: overlap is computed as pointerWidth + borderWidth so the next label
/// fully covers the previous pointer stroke. If you still see a seam, increase
/// extraOverlap slightly.
class BreadcrumbRow extends StatelessWidget {
  final List<String> labels;
  final List<VoidCallback?> actions;
  final double height;
  final double pointerRatio;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final bool twoSided;
  final double extraOverlap; // in px, use if you still see a 1px seam on some devices

  const BreadcrumbRow({
    Key? key,
    required this.labels,
    required this.actions,
    this.height = kToolbarHeight,
    this.pointerRatio = 0.5,
    this.color = const Color(0xFFC0392B),
    this.borderColor = Colors.black,
    this.borderWidth = 1.6,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.twoSided = false,
    this.extraOverlap = 0.0,
  })  : assert(labels.length == actions.length),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final double pointerWidth = height * pointerRatio;
    // Ensure next label covers the previous pointer *and* its stroke.
    final double overlap = pointerWidth + borderWidth + extraOverlap;

    List<Widget> items = [];
    for (int i = 0; i < labels.length; i++) {
      final bool isFirst = i == 0;
      final bool isLast = i == labels.length - 1;

      final bool showLeft = twoSided ? !isFirst : false;
      final bool showRight = twoSided ? !isLast : !isLast;

      Widget label = SizedBox(
        height: height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: actions[i],
            child: ArrowLabel(
              child: Text(labels[i]),
              showLeftPointer: showLeft,
              showRightPointer: showRight,
              pointerRatio: pointerRatio,
              color: color,
              borderColor: borderColor,
              borderWidth: borderWidth,
              padding: padding,
            ),
          ),
        ),
      );

      if (isFirst) {
        items.add(label);
      } else {
        items.add(Transform.translate(
          offset: Offset(-overlap, 0),
          child: label,
        ));
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }
}
