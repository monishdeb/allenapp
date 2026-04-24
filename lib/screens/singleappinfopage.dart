import '../screens/loadingScreen.dart';
import '../services/Offline.dart';

import '../services/query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/footer.dart';
import '../services/auth.dart';
import 'home.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/left_drawer.dart';
import '../services/HtmlParser.dart';

class SingleAppInfoPage extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  final String nodeTitle;
  bool isOffline;
  static const String route = '/preface';

  SingleAppInfoPage({required this.isEnglishUS, required this.locale, required this.nodeTitle, required this.isOffline});
  @override
  _SingleAppInfoPageState createState() => _SingleAppInfoPageState();
}


class _SingleAppInfoPageState extends State<SingleAppInfoPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isAppOffline = false;
  bool isLoading = true;
  String currentLocale = 'EN';
  @override
  void initState() {
    super.initState();
    isLoading = false;
    currentLocale = widget.locale;
    isAppOffline = widget.isOffline;
    initOfflineDatabase();
  }

  Future<void> initOfflineDatabase() async {
    setState(() {
      isLoading = true;
    });
    var database = db;
    if (database == null || !database.isOpen) {
      database = await initDatabase(false);
      setState(() {
        isLoading = false;
      });
    }
    else {
      Offline().getSourceData(database, false);
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onLocaleChange(String newLocale) {
    setState(() {
      currentLocale = newLocale;
    });
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingScreen(isEnglishUS: currentLocale == 'EN', locale: currentLocale);
    }
    return Scaffold(
      backgroundColor: Colors.grey[200],
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        locale: currentLocale,
        isEnglishUS: currentLocale == 'EN',
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
                          isEnglishUS: currentLocale == 'EN',
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
        isEnglishUS: currentLocale == 'EN',
        isOffline: isAppOffline,
        onOfflineChange: _onChangeOffline,
        onLocaleChange: _onLocaleChange,
      ),
      drawer: LeftNavDrawer(
        locale: currentLocale,
        isEnglishUS: currentLocale == 'EN',
        isOffline: isAppOffline,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title bar
            Container(
              color: Colors.grey[800],
              padding: EdgeInsets.symmetric(horizontal: 16),
              height: 56,
              alignment: Alignment.center,
              child: Text(
                widget.nodeTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: FutureBuilder(
                  future: Offline().getNode(
                    widget.nodeTitle,
                    currentLocale,
                    'allen_app_information',
                    db,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error fetching data'));
                    }
                    final offlineData = snapshot.data as List<dynamic>?;
                    if (offlineData == null || offlineData.isEmpty) {
                      return Center(child: Text('No data found offline'));
                    }
                    return HtmlWidget(HtmlParser().parseHtmlString(offlineData[0]['body']), textStyle: TextStyle(fontSize: 18));
                  }
                )
              ),
            ),

            // Footer now scrolls with content (no whitespace EVER)
            AllenAppFooter(
              locale: currentLocale,
              isEnglishUS: currentLocale == 'EN',
            ),
          ],
        ),
      ),
    );
  }
}
