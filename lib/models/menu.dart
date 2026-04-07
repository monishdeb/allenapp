/* Menu is a settings drawer used as "end drawer" across all screens.
 */
import 'package:flutter/material.dart';
import '../services/auth.dart';

class Menu extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String locale;
  final bool isEnglishUS;
  final bool isOffline;
  final void Function(bool?) onOfflineChange;

  const Menu({
    Key? key,
    required this.scaffoldKey,
    required this.locale,
    required this.isEnglishUS,
    required this.isOffline,
    required this.onOfflineChange,
  }) : super(key: key);

  void openEndDrawer() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  late bool _isEnglishUS;

  @override
  void initState() {
    super.initState();
    _isEnglishUS = widget.isEnglishUS;
  }

  void _closeDrawer() {
    Navigator.of(context).pop();
  }

  void _logout() {
    logout().then((_) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.red[700],
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Log out
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log out', style: TextStyle(fontSize: 16)),
                  onTap: _logout,
                ),
                const Divider(height: 1),
                // Language selection
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Language',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                RadioListTile<bool>(
                  title: const Text('English (US)'),
                  value: true,
                  groupValue: _isEnglishUS,
                  onChanged: (bool? value) {
                    setState(() {
                      _isEnglishUS = value ?? true;
                    });
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('English (UK)'),
                  value: false,
                  groupValue: _isEnglishUS,
                  onChanged: (bool? value) {
                    setState(() {
                      _isEnglishUS = !(value ?? false);
                    });
                  },
                ),
                const Divider(height: 1),
                // Font Size
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Font Size', style: TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                // App Status
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Status', style: TextStyle(fontSize: 16)),
                  subtitle: const Text('Version: 1.0.0'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                // Offline mode toggle
                SwitchListTile(
                  secondary: const Icon(Icons.wifi_off),
                  title: const Text(
                    'Offline Mode',
                    style: TextStyle(fontSize: 16),
                  ),
                  value: widget.isOffline,
                  onChanged: (bool value) async {
                    widget.onOfflineChange(value);
                    _closeDrawer();
                  },
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}