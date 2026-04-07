import '../screens/loadingScreen.dart';
import '../services/Offline.dart';

import '../services/query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/menu.dart';
import '../models/footer.dart';
import '../services/auth.dart';
import 'home.dart';

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
    var menu = Menu(scaffoldKey: _scaffoldKey, locale: widget.locale, isEnglishUS: widget.isEnglishUS, isOffline: isAppOffline, onOfflineChange: _onChangeOffline);
    if (isLoading) {
      return loadingScreen(isEnglishUS: widget.isEnglishUS, locale: widget.locale);
    }
    final client = GraphQLProvider
        .of(context)
        .value;
  return Scaffold(
  backgroundColor: Colors.grey[200],
  key: _scaffoldKey,
  appBar: AppBar(
    title: Image(image: AssetImage("images/Allen_App_title.png"), height: 50),
    leading:  IconButton(
      icon: Icon(
        Icons.home,
        color: Colors.white.withOpacity(0.85),
        size: 20,
      ),
      onPressed: () => Navigator.push(
        context, MaterialPageRoute(
          builder: (context) => HomePage(isEnglishUS: widget.isEnglishUS, locale: widget.locale, isOffline: isAppOffline)
        )
      )
    ),
  ),
  endDrawer: menu,
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
              future: isAppOffline
              ? Offline().getNode(
                  widget.nodeTitle,
                  widget.locale,
                  'allen_app_information',
                  db,
                )
              : client.query(
                  QueryOptions(
                    document: gql(getSinglePage),
                    variables: {
                      'langcode': widget.locale,
                      'nodeTitle': widget.nodeTitle,
                    },
                  ),
                ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error fetching data'));
            }

            if (isAppOffline) {
              final offlineData = snapshot.data as List<dynamic>?;
              if (offlineData == null || offlineData.isEmpty) {
                return Center(child: Text('No data found offline'));
              }
              return HtmlWidget(offlineData[0]['body'], textStyle: TextStyle(fontSize: 18));
            } else {
              final result = snapshot.data as QueryResult?;
              if (result == null ||
                  result.hasException ||
                  result.data == null) {
                return Center(child: Text('Error fetching data online'));
              }

              final items = result.data?['entityQuery']['items']
                      as List<dynamic>? ??
                  [];
              if (items.isEmpty) {
                return Center(child: Text('No data found online'));
              }

              final rawHtml = items[0]['translation']
                      ['bodyRawField']['getString'] as String? ??
                  '';

              return HtmlWidget(parseHtmlString(rawHtml), textStyle: TextStyle(fontSize: 18));
            }
          },
        )),
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
