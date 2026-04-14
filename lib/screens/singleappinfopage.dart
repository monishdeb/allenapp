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

  @override
  void initState() {
    super.initState();
    isLoading = false;
    isAppOffline = widget.isOffline;
    if (!isAppOffline) {
      var database = db;
      if (database == null || !database.isOpen) {
        initDatabase(false);
      }
      else {
        Offline().getSourceData(database, false);
      }
    }
  }

  // helper function to parse HTML to text
  // removes "full_html" from end of string
  String parseHtmlString(String htmlString) {
    String parsedText = htmlString;

    if (parsedText.endsWith(", full_html")) {
      parsedText = parsedText.substring(0, parsedText.length - 11);
    }

    return parsedText.trim();
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
      return loadingScreen(isEnglishUS: widget.isEnglishUS, locale: widget.locale);
    }
    return Scaffold(
      backgroundColor: Colors.grey[200],
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        locale: widget.locale,
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
                          locale: widget.locale,
                          isEnglishUS: widget.isEnglishUS,
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
                    widget.locale,
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
                    return HtmlWidget(offlineData[0]['body'], textStyle: TextStyle(fontSize: 18));
                  }
                )
              ),
            ),

            // Footer now scrolls with content (no whitespace EVER)
            AllenAppFooter(
              locale: widget.locale,
              isEnglishUS: widget.isEnglishUS,
            ),
          ],
        ),
      ),
    );
  }
}
