import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showBackButton;

  const CustomAppBar({
    required this.scaffoldKey,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: showBackButton ? 96.0 : 48.0,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
          if (showBackButton)
            IconButton(
              icon: Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () {
                Navigator.maybePop(context);
              },
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
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          tooltip: 'More options',
          // TODO: implement popup menu actions (Options, Notes, Unread Changes)
          onSelected: (value) {},
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'options',
              child: Text('Options'),
            ),
            PopupMenuItem<String>(
              value: 'notes',
              child: Text('Notes'),
            ),
            PopupMenuItem<String>(
              value: 'unread_changes',
              child: Text('Unread Changes'),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            scaffoldKey.currentState?.openEndDrawer();
          },
        ),
      ],
    );
  }
}
