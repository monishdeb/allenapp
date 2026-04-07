import 'package:allenapp/services/Offline.dart';

import '../widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../models/footer.dart';
import 'package:footer/footer_view.dart';
import '../models/selectableText.dart';
import '../services/auth.dart';
import '../Env.dart';

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
    final client = GraphQLProvider.of(context).value;
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        isEnglishUS: widget.isEnglishUS,
        locale: widget.locale,
        isOffline: isAppOffline,
        onOfflineChange: _onChangeOffline,
      ),
      endDrawer: SettingsDrawer(
        isEnglishUS: widget.isEnglishUS,
        locale: widget.locale,
        isOffline: isAppOffline,
        onOfflineChange: _onChangeOffline,
      ),
      body: FooterView(
       flex: 1,
       footer: AllenAppFooter(locale: widget.locale, isEnglishUS: widget.isEnglishUS),
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
          isAppOffline ? (
            FutureBuilder(
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
                                 title: Text(childLabel),
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
                                 title: Text(childLabel),
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
          ) : (
            FutureBuilder<QueryResult>(
            future: client.query(QueryOptions(
              document: gql(getChildTermsACLS), // queries for child terms and displays underneath content for current term
              variables: {
                'parentIds': [widget.termId]
              },
            )),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data?.hasException == true) {
                return Center(child: Text('Error fetching child terms'));
              }
              final childTerms = snapshot.data?.data?['entityQuery']['items'] ?? [];

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
                      final childId = term['id'];
                      return FutureBuilder<QueryResult>(
                        future: client.query(QueryOptions(
                          document: gql(getNodeACLS), // queries for the content associated with the current ACLS-6 taxonomy term
                          variables: {'termId': childId},
                        )),
                        builder: (context, childSnapshot) {
                          if (childSnapshot.connectionState ==
                            ConnectionState.waiting) {
                            return SizedBox.shrink();
                          }
                          if (childSnapshot.hasError ||
                            childSnapshot.data?.hasException == true) {
                            return SizedBox.shrink();
                          }
                          final node = (childSnapshot.data?.data?['entityQuery']
                            ['items'] as List?)?.firstOrNull;
                          if (node == null) { return SizedBox.shrink(); }

                          final childLabel = node['label'] ?? 'No label';
                          final childBody =
                              node['bodyRawField']?['getString'].replaceAll(', full_html', '')  ?? 'No body';
                          final contentType =
                            node['fieldContentTypeRawField']?['getString'].toString().toUpperCase();
                          // displays child content in new AclsDetailsScreen (recursive)
                          if (contentType == 'P') {
                            return ListTile(
                              title: Text(childLabel),
                              leading: Icon(Icons.arrow_forward_ios_outlined),
                                onTap: () {
                                  Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AclsDetailsScreen(
                                      nodeId: node['id'] ?? '',
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
                              title: Text(childLabel),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SelectableAllenText(text: childBody, notes: [], currentNodeId: node['id'] ?? '', isOffline: isAppOffline)
                                ),
                              ],
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      );
                    }).toList(),
                ],
             );
            },
          )
        )
      ]),
    );
  }
}
