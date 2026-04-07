import 'package:allenapp/screens/loadingScreen.dart';
import 'package:allenapp/screens/Notes.dart';

import 'package:flutter/material.dart';
import 'chartscreen.dart';
import 'cf.dart';
import 'acls6.dart';
import 'singleappinfopage.dart';
import '../models/footer.dart';
import 'package:footer/footer_view.dart';
import '../services/auth.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  bool isOffline = false;
  static const String route = '/home';
  HomePage({required this.isEnglishUS, required this.locale, required this.isOffline});

  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isAppOffline = false;
  bool isLoading = true;
  String _selectedLanguage = 'EN_US';

  @override
  void initState() {
    isAppOffline = widget.isOffline;
    _selectedLanguage = widget.locale;
    super.initState();
    isLoading = false;
  }

  void _onChangeOffline(bool? isOffline) async {
    setState(() {
      isLoading = true;
    });
    await setOfflineStatus(isOffline ?? false, true);
    await setOfflineDate(DateTime.now().millisecondsSinceEpoch);
    setState(() {
      isAppOffline = isOffline ?? false;
      isLoading = false;
    });
  }

  void _openSettingsDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _logout() async {
    await logoutUser();
    if (!mounted) return;
    Navigator.of(_scaffoldKey.currentContext!).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginPage(title: 'Allen App', authenticated: false),
      ),
      (route) => false,
    );
  }

  Widget _buildSettingsDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Colors.red[700],
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: const Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () {
                _scaffoldKey.currentState?.closeEndDrawer();
                _logout();
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            RadioListTile<String>(
              activeColor: Colors.red,
              title: Row(
                children: [
                  Image.asset('icons/flags/png100px/us.png', package: 'country_icons', height: 20),
                  const SizedBox(width: 10),
                  const Flexible(child: Text('English US - imperial units')),
                ],
              ),
              value: 'EN_US',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value ?? 'EN_US';
                });
                storeLangaugeCode(value);
              },
            ),
            RadioListTile<String>(
              activeColor: Colors.red,
              title: Row(
                children: [
                  Image.asset('icons/flags/png100px/gb.png', package: 'country_icons', height: 20),
                  const SizedBox(width: 10),
                  const Flexible(child: Text('English UK - metric units')),
                ],
              ),
              value: 'EN',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value ?? 'EN';
                });
                storeLangaugeCode(value);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Font Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Font size settings coming soon.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('App Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('App Version: 1.0.0', style: TextStyle(fontSize: 14)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Mode: ${isAppOffline ? "Offline" : "Online"}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingScreen();
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
            'Allen App',
             style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back',
            onPressed: Navigator.canPop(context) ? () => Navigator.pop(context) : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'saved_notes') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotesPage(locale: widget.locale, isOffline: isAppOffline),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'saved_notes', child: Text('Saved Notes')),
              PopupMenuItem(value: 'unread_changes', child: Text('Unread Changes')),
              PopupMenuItem(value: 'options', child: Text('Options')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: _openSettingsDrawer,
          ),
        ],
      ),
      endDrawer: Builder(
        builder: (context) => _buildSettingsDrawer(context),
      ),
      body: FooterView(
        footer: AllenAppFooter(isEnglishUS: widget.isEnglishUS, locale: widget.locale),
        flex: 1,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(),
                    },
                    children: [
                      TableRow(children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                            'Welcome to the Allen App - the Allen Cognitive Disability Model Electronic Textbook, Resource Manual, and Assessment Toolkit by Claudia Kay Allen.',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ]),
                      ...[
                        'Preface',
                        'Conceptual Framework',
                        'Allen Cognitive Levels',
                        'ACLS-6',
                        'Glossary of Terms',
                      ].map((title) {
                        return TableRow(children: [
                          MouseRegion(
                            onEnter: (_) => {},
                            onExit: (_) => {},
                            child: GestureDetector(
                              onTap: () {
                                if (title == 'Allen Cognitive Levels') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            TaxonomyHierarchyScreen(
                                                isEnglishUS: widget.isEnglishUS,
                                                locale: widget.locale,
                                                isOffline: isAppOffline)),
                                  );
                                } else if (title == 'Conceptual Framework') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ConceptualFrameworksScreen(
                                                isEnglishUS: widget.isEnglishUS,
                                                locale: widget.locale,
                                                isOffline: isAppOffline)),
                                  );
                                } else if (title == 'ACLS-6') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AclsTermsScreen(
                                            isEnglishUS: widget.isEnglishUS,
                                            locale: widget.locale,
                                            isOffline: isAppOffline
                                        )),
                                  );
                                } else if (title == 'Preface') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SingleAppInfoPage(
                                      isEnglishUS: widget.isEnglishUS,
                                      locale: widget.locale,
                                      nodeTitle: "Preface",
                                      isOffline: isAppOffline
                                    )),
                                  );
                                } else if (title == 'Glossary of Terms') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SingleAppInfoPage(
                                      isEnglishUS: widget.isEnglishUS,
                                      locale: widget.locale,
                                      nodeTitle: "Glossary of Terms",
                                      isOffline: isAppOffline
                                    )),
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8.0),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(
                                        Icons.arrow_forward_ios_outlined,
                                        size: 20.0,
                                    ),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
