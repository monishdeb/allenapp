import 'package:flutter/material.dart';
import '../screens/chartscreen.dart';
import '../screens/cf.dart';
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

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
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
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text(
              'Conceptual Framework',
              style: TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _navigate(
              context,
              ConceptualFrameworksScreen(
                isEnglishUS: isEnglishUS,
                locale: locale,
                isOffline: isOffline,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text(
              'Allen Cognitive Levels',
              style: TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _navigate(
              context,
              TaxonomyHierarchyScreen(
                isEnglishUS: isEnglishUS,
                locale: locale,
                isOffline: isOffline,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text(
              'ACLS-6 Activities',
              style: TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _navigate(
              context,
              AclsTermsScreen(
                isEnglishUS: isEnglishUS,
                locale: locale,
                isOffline: isOffline,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text(
              'Search',
              style: TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.search, size: 16),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text(
                        'Search',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    body: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomSearchBar(
                        isEnglishUS: isEnglishUS,
                        locale: locale,
                        isOffline: isOffline,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
