import 'package:flutter/material.dart';
import '../screens/Notes.dart';
import '../screens/login.dart';
import '../services/auth.dart';

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
    final canPop = Navigator.canPop(context);
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: canPop ? 96 : 48,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Navigation menu',
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
          ),
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
            ),
        ],
      ),
      title: Image.asset(
        'images/Allen_App_title.png',
        height: 36,
        fit: BoxFit.contain,
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


/// Settings drawer that replaces the previous endDrawer Menu across all screens.
///
/// Contains:
/// - Log out button
/// - Language selection (English US / English UK) with radio buttons
/// - Font Size section
/// - App Status section with offline mode toggle
class SettingsDrawer extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;
  final void Function(bool?) onOfflineChange;
  final void Function()? onLogout;

  const SettingsDrawer({
    Key? key,
    required this.isEnglishUS,
    required this.locale,
    required this.isOffline,
    required this.onOfflineChange,
    this.onLogout,
  }) : super(key: key);

  @override
  _SettingsDrawerState createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  late bool _isEnglishUS;

  @override
  void initState() {
    super.initState();
    _isEnglishUS = widget.isEnglishUS;
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (widget.onLogout != null) {
      widget.onLogout!();
    } else {
      await storage.deleteAll();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              LoginPage(title: 'Allen App', authenticated: false),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          children: [
            Container(
              color: Colors.red[700],
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: const Text(
                'Allen App Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Log out button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero),
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
                onPressed: () => _handleLogout(context),
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                      fontFamily: 'helvetica,sans-serif',
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Divider(height: 32),
            // Language selection
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                'Language',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
            ),
            RadioListTile<bool>(
              activeColor: Colors.red,
              title: Row(
                children: [
                  Image.asset('icons/flags/png100px/us.png',
                      package: 'country_icons', height: 20),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'English US - imperial units',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              value: true,
              groupValue: _isEnglishUS,
              onChanged: (value) {
                setState(() {
                  _isEnglishUS = value ?? true;
                });
                storeLangaugeCode('EN_US');
              },
            ),
            RadioListTile<bool>(
              activeColor: Colors.red,
              title: Row(
                children: [
                  Image.asset('icons/flags/png100px/gb.png',
                      package: 'country_icons', height: 20),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'English UK - metric units',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              value: false,
              groupValue: _isEnglishUS,
              onChanged: (value) {
                setState(() {
                  _isEnglishUS = value == false;
                });
                storeLangaugeCode('EN');
              },
            ),
            const Divider(height: 32),
            // Font Size
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                'Font Size',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text('Default'),
            ),
            const Divider(height: 32),
            // App Status
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                'App Status',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: CheckboxListTile(
                value: widget.isOffline,
                title: const Text('Is App in Offline Mode?'),
                onChanged: (bool? value) async {
                  widget.onOfflineChange(value);
                  Navigator.of(context).pop();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 4.0),
              child: Text(
                'App Version: 1.0.0',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
