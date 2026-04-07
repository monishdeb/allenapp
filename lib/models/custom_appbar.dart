import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showBackArrow;

  const CustomAppBar({
    required this.scaffoldKey,
    this.showBackArrow = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: showBackArrow ? 96 : 48,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open navigation drawer',
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
          ),
          if (showBackArrow)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
      title: Text(
        'Allen App',
        style: TextStyle(
          fontFamily: 'helvetica,sans-serif',
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Open settings',
          onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    );
  }
}
