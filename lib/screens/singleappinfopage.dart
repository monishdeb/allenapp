import '../screens/loadingScreen.dart';
import '../services/Offline.dart';

import '../services/query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/menu.dart';
import '../models/custom_appbar.dart';
import '../models/footer.dart';
import 'package:footer/footer_view.dart';
import '../services/auth.dart';

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
      return loadingScreen();
    }
    final client = GraphQLProvider
        .of(context)
        .value;
      return Scaffold(
        key: _scaffoldKey,
        appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
        endDrawer: menu,
        body: FooterView(
          footer: AllenAppFooter(locale: widget.locale, isEnglishUS: widget.isEnglishUS),
          flex: 1,
          children: [
          Container(
              color: Colors.grey[800],
              padding: EdgeInsets.symmetric(horizontal: 16),
              height: 56, // Same as AppBar height
              alignment: Alignment.center,
              child: Text(
                widget.nodeTitle,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isAppOffline ? (
                        FutureBuilder(
                          future: Offline().getNode(widget.nodeTitle, widget.locale, 'allen_app_information', db),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error fetching child terms'));
                            }
                            return HtmlWidget(snapshot.data?[0]['body']);
                          },
                        ) ): (
                        FutureBuilder<QueryResult>(
                          future: client.query(QueryOptions(
                            document: gql(getSinglePage),
                            variables: {
                              'langcode': widget.locale,
                              'nodeTitle': widget.nodeTitle,
                            },
                          )),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError ||
                              snapshot.data?.hasException == true) {
                              return Center(
                               child: Text('Error fetching child terms'));
                            }
                            final node = snapshot.data
                              ?.data?['entityQuery']['items'] ?? [];
                              return HtmlWidget(parseHtmlString(
                                node[0]['translation']['bodyRawField']['getString'])
                              );
                          }
                        ))
                    ]
                  )
                ]
              )
            )
          )
        ]
      )
    );
  }
}
