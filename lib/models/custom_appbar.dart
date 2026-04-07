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
      title: Text(
        'Allen App',
        style: TextStyle(
          fontFamily: 'helvetica,sans-serif',
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.menu),
        tooltip: 'Menu',
        onPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        if (showBackButton)
          IconButton(
            icon: Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              Navigator.maybePop(context);
            },
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          tooltip: 'More options',
          onSelected: (value) {
            // Handle popup menu selection
          },
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
