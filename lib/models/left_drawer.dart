/* LeftNavDrawer is the left-side navigation drawer shared across all screens.
 * It is opened by the hamburger menu icon (☰) in the AppBar.
 */
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
    Key? key,
    required this.locale,
    required this.isEnglishUS,
    required this.isOffline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Colors.red[700],
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_forward_ios_outlined, size: 18),
              title: const Text(
                'Conceptual Framework',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConceptualFrameworksScreen(
                      isEnglishUS: isEnglishUS,
                      locale: locale,
                      isOffline: isOffline,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.arrow_forward_ios_outlined, size: 18),
              title: const Text(
                'Allen Cognitive Levels',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaxonomyHierarchyScreen(
                      isEnglishUS: isEnglishUS,
                      locale: locale,
                      isOffline: isOffline,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.arrow_forward_ios_outlined, size: 18),
              title: const Text(
                'ACLS-6 Activities',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AclsTermsScreen(
                      isEnglishUS: isEnglishUS,
                      locale: locale,
                      isOffline: isOffline,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.search, size: 18),
              title: const Text(
                'Search',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: CustomSearchBar(
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
