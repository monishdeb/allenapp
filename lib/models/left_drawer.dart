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
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey[800]),
              child: Text(
                'Allen App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.library_books),
              title: Text('Conceptual Framework'),
              onTap: () {
                Navigator.of(context).pop();
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
            ListTile(
              leading: Icon(Icons.account_tree),
              title: Text('Allen Cognitive Levels'),
              onTap: () {
                Navigator.of(context).pop();
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
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('ACLS-6 Activities'),
              onTap: () {
                Navigator.of(context).pop();
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
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Search'),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
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
