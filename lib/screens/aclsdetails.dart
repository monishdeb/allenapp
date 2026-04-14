import 'package:allenapp/services/Offline.dart';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../models/footer.dart';
import '../models/selectableText.dart';
import '../services/auth.dart';
import '../Env.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/left_drawer.dart';

// screen for ACLS-6 taxonomy/content type
// renders when the user presses one of the content nodes on ACLS-6 page
class AclsDetailsScreen extends StatefulWidget {
  final String termId;
  final String label;
  final String body;
  final String locale;
  final bool isEnglishUS;
  final String nodeId;
  bool isOffline;

  AclsDetailsScreen(
      {required this.termId, required this.label, required this.body, required this.locale, required this.isEnglishUS, required this.nodeId, required this.isOffline});
  @override
  _AclsDetailsScreenState createState() => _AclsDetailsScreenState();
}


class _AclsDetailsScreenState extends State<AclsDetailsScreen> {
  bool isAppOffline = false;
  @override
  void initState() {
    isAppOffline = widget.isOffline;
    super.initState();
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // helper function to parse HTML to text
  // removes "full_html" from end of string
  String parseHtmlString(String htmlString) {
    String parsedText = htmlString;

    if (parsedText.endsWith(", full_html")) {
      parsedText = parsedText.substring(0, parsedText.length - 11);
    }
    parsedText.replaceAll('"/sites', '"' + Env.DRUPAL_URL + '/sites');
    return parsedText.trim();
  }

  void _onChangeOffline(bool? isOffline) async {
    await setOfflineStatus(isOffline ?? false, true);
    await setOfflineDate(DateTime.now().millisecondsSinceEpoch);
    setState(() {
      isAppOffline = isOffline ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[200],
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
          Container(
            color: Colors.grey[800],
            padding: EdgeInsets.symmetric(horizontal: 16),
            height: 56, // Same as AppBar height
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              color: Colors.white,
              child: FutureBuilder(
                  future: Offline().getChildTaxonomy(widget.termId, 'acls_6', db),
                  builder: (context, childSnapshot) {
                    if (childSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (childSnapshot.hasError) {
                       return Center(child: Text('Error fetching child terms'));
                    }
                    final childTerms = childSnapshot.data ?? [];
                    return ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      physics: ScrollPhysics(),
                      padding: EdgeInsets.all(16),
                      children: [
                        SelectableAllenText(text: parseHtmlString(widget.body), notes: [], currentNodeId: widget.nodeId, isOffline: isAppOffline),
                        SizedBox(height: 32),
                        if (childTerms.isNotEmpty) SizedBox(height: 10),
                          ...childTerms.map<Widget>((term) {
                            final childId = term['id'].toString();
                            return FutureBuilder(
                               future: Offline().getNodesByTaxonomyId(childId, widget.locale, 'acls_6', db),
                               builder: (context, snapshot) {
                                 if (snapshot.connectionState ==
                                   ConnectionState.waiting) {
                                   return SizedBox.shrink();
                                 }
                                 if (snapshot.hasError) {
                                   return SizedBox.shrink();
                                 }
                                 final node = snapshot.data?.firstOrNull;
                                 if (node == null) { return SizedBox.shrink(); }
                                 final childLabel = (node['label'] == '' ? 'No label' : node['label']);
                                 final childBody = (node['body'] == '' ? 'No body' : node['body']);
                                 final contentType = node['content_type'];
                                 // displays child content in new AclsDetailsScreen (recursive)
                                 if (contentType == 'P') {
                                   return ListTile(
                                     contentPadding: EdgeInsets.only(left: 8.0),
                                     title: Text(childLabel, style: TextStyle(fontSize: 18)),
                                     leading: Icon(Icons.arrow_forward_ios_outlined),
                                     onTap: () {
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(
                                           builder: (_) => AclsDetailsScreen(
                                             nodeId: node['id'].toString() ?? '',
                                             termId: childId,
                                             label: childLabel,
                                             body: childBody,
                                             locale: widget.locale,
                                             isEnglishUS: widget.isEnglishUS,
                                             isOffline: isAppOffline,
                                           ),
                                         ),
                                       );
                                     },
                                   );
                                 }
                                 // else displays child content as accordion
                                 else if (contentType == 'A') {
                                   return ExpansionTile(
                                     tilePadding: EdgeInsets.only(left: 8.0),
                                     title: Text(childLabel, style: TextStyle(fontSize: 18)),
                                     children: [
                                       Padding(
                                         padding: const EdgeInsets.all(8.0),
                                         child: SelectableAllenText(text: childBody, notes: [], currentNodeId: node['id'].toString() ?? '', isOffline: isAppOffline)
                                       ),
                                     ],
                                   );
                                 } else {
                                   return SizedBox.shrink();
                                 }
                               }
                            );
                          }).toList()
                      ],
                    );
                  }
                )
          )
        ),
        // Footer now scrolls with content (no whitespace EVER)
        AllenAppFooter(
          locale: widget.locale,
          isEnglishUS: widget.isEnglishUS,
        ),
      ])),
    );
  }
}
