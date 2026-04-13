import 'package:flutter/material.dart';
import '../screens/chartscreen.dart';
import '../screens/cf.dart';
import '../screens/acls6.dart';
import '../screens/search.dart';

class LeftNavDrawer extends StatelessWidget {
  final String locale;
  final bool isEnglishUS;
  final bool isOffline;
  final String? currentScreen;

  const LeftNavDrawer({
    Key? key,
    required this.locale,
    required this.isEnglishUS,
    required this.isOffline,
    this.currentScreen,
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
    return Padding(
    padding: const EdgeInsets.only(top: 110),
    child: Drawer(
      child: Container(
      color: Colors.white,
      child: Column(
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: const Text(
              'Menu',
              style: TextStyle(
                color: Colors.red,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (currentScreen != 'conceptual_framework')
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
          if (currentScreen != 'conceptual_framework')
          const Divider(height: 1),
          if (currentScreen != 'allen_cognitive_levels')
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
          if (currentScreen != 'allen_cognitive_levels')
          const Divider(height: 1),
          if (currentScreen != 'acls6_activities')
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
          if (currentScreen != 'acls6_activities')
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
      )),
    ));
  }
}
