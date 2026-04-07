import 'package:flutter/material.dart';

class NotesAppBar extends StatelessWidget {
  const NotesAppBar({required this.isElevated, required this.isVisible});
  final bool isElevated;
  final bool isVisible;


  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(duration: Duration(milliseconds: 200),
      height: isVisible ? 80.0 : 0,
      child: BottomAppBar(
        elevation: isElevated ? null : 0.0,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Show notes',
              icon: const Icon(Icons.note_outlined),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            )
          ],
        )
      )
    );
  }
}