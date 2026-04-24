import 'package:allenapp/screens/loadingScreen.dart';
import 'package:flutter/material.dart';
import 'chartscreen.dart';
import 'cf.dart';
import 'acls6.dart';
import 'singleappinfopage.dart';
import '../models/footer.dart';
import '../services/auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/left_drawer.dart';

class HomePage extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  bool isOffline = false;
  static const String route = '/home';

  HomePage({
    required this.isEnglishUS,
    required this.locale,
    required this.isOffline,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isAppOffline = false;
  bool isLoading = true;
  String currentLocale = 'EN';

  @override
  void initState() {
    isAppOffline = widget.isOffline;
    currentLocale = widget.locale;
    super.initState();
    isLoading = false;
  }

  void _onChangeOffline(bool? isOffline) async {
    setState(() => isLoading = true);
    await setOfflineStatus(isOffline ?? false, false);
    await setOfflineDate(DateTime.now().millisecondsSinceEpoch);
    setState(() {
      isAppOffline = isOffline ?? false;
      isLoading = false;
    });
  }

  void _onLocaleChange(String newLocale) {
    setState(() {
      currentLocale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return loadingScreen(isEnglishUS: (currentLocale == 'EN'), locale: currentLocale);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        print("Back button pressed but blocked");
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[200],
        appBar: CustomAppBar(
          scaffoldKey: _scaffoldKey,
          locale: currentLocale,
          isEnglishUS: widget.isEnglishUS,
          isOffline: isAppOffline,
          onMoreOptionsPressed: () {
          showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
              barrierColor: Colors.black54,
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 110), // Add top padding
                        child: Material(
                          borderRadius: BorderRadius.zero,
                          child: MoreOptionsDrawer(
                            locale: currentLocale,
                            isEnglishUS: (currentLocale == 'EN'),
                            isOffline: isAppOffline,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        endDrawer: SettingsDrawer(
          locale: currentLocale,
          isEnglishUS: (currentLocale == 'EN'),
          isOffline: isAppOffline,
          onOfflineChange: _onChangeOffline,
          onLocaleChange: _onLocaleChange,
        ),
        drawer: LeftNavDrawer(
          locale: currentLocale,
          isEnglishUS: (currentLocale == 'EN'),
          isOffline: isAppOffline,
          currentScreen: 'home',
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Colors.white,
                    child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(),
                    },
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              'Welcome to the Allen App - the Allen Cognitive Disability Model Electronic Textbook, Resource Manual, and Assessment Toolkit by Claudia Kay Allen.',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      ...[
                        'Preface',
                        'Conceptual Framework',
                        'Allen Cognitive Levels',
                        'ACLS-6',
                        'Glossary of Terms',
                      ].map((title) {
                        return TableRow(
                          children: [
                            MouseRegion(
                              onEnter: (_) {},
                              onExit: (_) {},
                              child: GestureDetector(
                                onTap: () {
                                  if (title == 'Allen Cognitive Levels') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TaxonomyHierarchyScreen(
                                          isEnglishUS: (currentLocale == 'EN'),
                                          locale: currentLocale,
                                          isOffline: isAppOffline,
                                        ),
                                      ),
                                    );
                                  } else if (title == 'Conceptual Framework') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ConceptualFrameworksScreen(
                                          isEnglishUS: (currentLocale == 'EN'),
                                          locale: currentLocale,
                                          isOffline: isAppOffline,
                                        ),
                                      ),
                                    );
                                  } else if (title == 'ACLS-6') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AclsTermsScreen(
                                          isEnglishUS: (currentLocale == 'EN'),
                                          locale: currentLocale,
                                          isOffline: isAppOffline,
                                        ),
                                      ),
                                    );
                                  } else if (title == 'Preface') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SingleAppInfoPage(
                                          isEnglishUS: (currentLocale == 'EN'),
                                          locale: currentLocale,
                                          nodeTitle: "Preface",
                                          isOffline: isAppOffline,
                                        ),
                                      ),
                                    );
                                  } else if (title == 'Glossary of Terms') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SingleAppInfoPage(
                                          isEnglishUS: (currentLocale == 'EN'),
                                          locale: currentLocale,
                                          nodeTitle: "Glossary of Terms",
                                          isOffline: isAppOffline,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      top: BorderSide(width: 0.2, color: Colors.grey),
                                      bottom: BorderSide(width: 0.2, color: Colors.grey),
                                    )
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_outlined,
                                        size: 20.0,
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),

                    ],
                  )),
                ),
              AllenAppFooter(
                locale: currentLocale,
                isEnglishUS: (currentLocale == 'EN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
