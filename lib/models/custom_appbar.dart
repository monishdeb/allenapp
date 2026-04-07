import 'package:flutter/material.dart';
import '../screens/Notes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String locale;
  final bool isEnglishUS;
  final bool isOffline;

  const CustomAppBar({
    Key? key,
    required this.scaffoldKey,
    required this.locale,
    required this.isEnglishUS,
    required this.isOffline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Navigation menu',
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
          ),
        ],
      ),
      title: const Text(
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
          icon: const Icon(Icons.more_vert, color: Colors.white),
          tooltip: 'More options',
          onSelected: (value) {
            if (value == 'saved_notes') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotesPage(locale: locale, isOffline: isOffline),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'saved_notes',
              child: Text('Saved Notes'),
            ),
            const PopupMenuItem<String>(
              value: 'unread_changes',
              child: Text('Unread Changes'),
            ),
            const PopupMenuItem<String>(
              value: 'options',
              child: Text('Options'),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          tooltip: 'Settings',
          onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
