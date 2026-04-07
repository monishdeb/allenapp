import 'package:allenapp/screens/loadingScreen.dart';

import '../widgets/custom_app_bar.dart';
import '../models/left_drawer.dart';
import 'package:flutter/material.dart';
import 'chartscreen.dart';
import 'cf.dart';
import 'acls6.dart';
import 'singleappinfopage.dart';
import '../models/footer.dart';
import 'package:footer/footer_view.dart';
import '../services/auth.dart';

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
  @override
  void initState() {
    isAppOffline = widget.isOffline;
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
    });
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingScreen();
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        locale: widget.locale,
        isEnglishUS: widget.isEnglishUS,
        isOffline: isAppOffline,
        onOfflineChange: _onChangeOffline,
      ),
      endDrawer: SettingsDrawer(
        locale: widget.locale,
        isEnglishUS: widget.isEnglishUS,
        isOffline: isAppOffline,
        onOfflineChange: _onChangeOffline,
      ),
      drawer: LeftNavDrawer(
        locale: widget.locale,
        isEnglishUS: widget.isEnglishUS,
        isOffline: isAppOffline,
      ),
      body: new FooterView(
        footer: AllenAppFooter(isEnglishUS: widget.isEnglishUS, locale: widget.locale),
        flex: 1,
        children:<Widget>[
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
                            }
                            else if (title == 'Preface') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SingleAppInfoPage(
                                  isEnglishUS: widget.isEnglishUS,
                                  locale: widget.locale,
                                  nodeTitle: "Preface",
                                  isOffline: isAppOffline
                                )),
                              );
                            }
                            else if (title == 'Glossary of Terms') {
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
                            decoration: BoxDecoration(
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    size: 20.0,
                                ),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
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
      )
    );
  }
}
