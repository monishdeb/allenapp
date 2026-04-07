import 'package:flutter/material.dart';
import '../screens/cf.dart';
import '../screens/chartscreen.dart';
import '../screens/acls6.dart';
import '../screens/search.dart';

class LeftNavDrawer extends StatelessWidget {
  final String locale;
  final bool isEnglishUS;
  final bool isOffline;

  const LeftNavDrawer({
    required this.locale,
    required this.isEnglishUS,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: Text('Conceptual Framework'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConceptualFrameworksScreen(
                      isEnglishUS: isEnglishUS,
                      locale: locale,
                      isOffline: isOffline,
                    ),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('Allen Cognitive Levels'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaxonomyHierarchyScreen(
                      isEnglishUS: isEnglishUS,
                      locale: locale,
                      isOffline: isOffline,
                    ),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('ACLS-6 Activities'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AclsTermsScreen(
                      isEnglishUS: isEnglishUS,
                      locale: locale,
                      isOffline: isOffline,
                    ),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('Search'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Search'),
                    content: CustomSearchBar(
                      isEnglishUS: isEnglishUS,
                      locale: locale,
                      isOffline: isOffline,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
