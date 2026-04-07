import 'loadingScreen.dart';
import '../services/Offline.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import 'aclsdetails.dart';
import 'activitystart.dart';
import '../models/menu.dart';
import '../models/footer.dart';
import 'package:footer/footer_view.dart';
import '../models/selectableText.dart';
import '../services/auth.dart';
import '../Env.dart';

// screen that renders when the user presses ACLS-6 from the main menu
// split into two sections: ACLS section and Activities section
class AclsTermsScreen extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;
  const AclsTermsScreen({Key? key, required this.isEnglishUS, required this.locale, required this.isOffline})
      : super(key: key);

  @override
  _AclsTermsScreenState createState() => _AclsTermsScreenState();
}

class _AclsTermsScreenState extends State<AclsTermsScreen> {
  List<Map<String, dynamic>> activities = [];
  bool isLoading = true;
  bool isAppOffline = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    isAppOffline = widget.isOffline;
    fetchActivities();
  }

  // function fetches all content from Drupal with type ACLS-6 Activities and filters them
  // only stores main activities
  Future<void> fetchActivities() async {
    List items = [];
    setState(() {
      activities = [];
    });
    if (isAppOffline) {
      items = await Offline().getActivities(widget.locale, db, null);
    }
    else {
      final GraphQLClient graphQLClient = client.value;

      final result = await graphQLClient.query(
        QueryOptions(document: gql(getActivities),
            variables: {'langcode': widget.locale}),
      );

      if (result.hasException) {
        print('Error fetching activities: ${result.exception.toString()}');
        return;
      }

      items = result.data?['entityQuery']['items'] ?? [];
    }
    List<Map<String, dynamic>> filteredItems = [];
    // only keeps the items with activity ID in the form Activity Name 1
    for (var item in items) {
      if (!isAppOffline) {
        if ((item['fieldActivityIdRawField']?['getString'] ?? '')
            .endsWith(' 1')) {
          filteredItems.add(item);
        }
      }
      else {
        if ((item['activity_id'] ?? '').endsWith(' 1')) {
          filteredItems.add(item);
        }
      }
    }

    setState(() {
      activities = List<Map<String, dynamic>>.from(filteredItems);
      isLoading = false;
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
    });
    fetchActivities();
  }

  @override
  Widget build(BuildContext context) {
    var menu = Menu(scaffoldKey: _scaffoldKey, locale: widget.locale, isEnglishUS: widget.isEnglishUS, isOffline: isAppOffline, onOfflineChange: _onChangeOffline);
    var appbar = AppBar(
         title: Text(
           'Allen App',
           style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)
         ),
         centerTitle: true,
         actions: [IconButton(onPressed: menu.openEndDrawer, icon: Icon(Icons.menu))],
    );
    if (isLoading) {
      return loadingScreen();
    }
    final client = GraphQLProvider.of(context).value;
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: menu,
      appBar: appbar,
      body: FooterView(
        footer: AllenAppFooter(locale: widget.locale, isEnglishUS: widget.isEnglishUS),
        children: [
          Container(
            color: Colors.grey[800],
            padding: EdgeInsets.symmetric(horizontal: 16),
            height: 56, // Same as AppBar height
            alignment: Alignment.center,
            child: Text(
              'ACLS Terms',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          !isAppOffline ? (
            FutureBuilder<QueryResult>(
              future: client.query(QueryOptions(document: gql(getParentTermsACLS))),
              builder: (context, snapshot) {
                // returns error to screen if graphql query fails to complete
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data?.hasException == true) {
                  return Center(child: Text('Error fetching terms'));
                }
                final terms = snapshot.data?.data?['entityQuery']['items'] ?? [];
                return ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: ScrollPhysics(),
                  children: [
                    // upper part of the screen, ACLS section, displays taxonomy and content type ACLS-6
                    ...terms.map((term) {
                      final termId = term['id'].toString();
                      return FutureBuilder<QueryResult>(
                         future: client.query(QueryOptions(
                           document: gql(getNodeACLS),
                           variables: {'termId': termId},
                         )),
                         builder: (context, nodeSnapshot) {
                           if (nodeSnapshot.connectionState ==
                             ConnectionState.waiting) {
                             return SizedBox.shrink();
                           }
                           if (nodeSnapshot.hasError ||
                             nodeSnapshot.data?.hasException == true) {
                             return SizedBox.shrink();
                           }
                           final node = (nodeSnapshot.data?.data?['entityQuery']
                             ['items'] as List?)
                             ?.firstOrNull;
                           if (node == null) return SizedBox.shrink();
                           final label = node['label'] ?? 'No label';
                           final body =
                             node['bodyRawField']?['getString'].replaceAll(', full_html', '') ?? 'No body';

                           final contentType = node['fieldContentTypeRawField']?['getString'].toUpperCase();
                           if (label == 'ACLS-6') {
                           return Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: Container(
                                 color: Colors.white,
                                 child: SelectableAllenText(text: body, notes: [], currentNodeId: node['id'] ?? '', isOffline: isAppOffline)
                               )
                             );
                           }
                           if (contentType == 'A') {
                             return ExpansionTile(
                               leading: Icon(Icons.keyboard_arrow_down), // Down arrow on the left
                               trailing: SizedBox.shrink(),
                               title: Text(label),
                               children: [
                                 Padding(
                                   padding: const EdgeInsets.all(8.0),
                                   child: SelectableAllenText(text: body, notes: [], currentNodeId: node['id'] ?? '', isOffline: isAppOffline)
                                 ),
                               ],
                             );
                           }

                           // navigates to new screen when one of the pieces of content are pressed by user
                           return Container(
                             margin: EdgeInsets.only(left: 20),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment
                                 .spaceBetween,
                               children: [
                                 Icon(
                                   Icons.arrow_forward_ios_outlined,
                                   size: 15.0,
                                 ),
                                 Expanded(
                                   child: ListTile(
                                     title: Text(label),
                                     onTap: () {
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(
                                           builder: (_) =>
                                             AclsDetailsScreen(
                                               nodeId: node['id'] ?? '',
                                               termId: termId,
                                               label: label,
                                               body: body,
                                               locale: widget.locale,
                                               isEnglishUS: widget
                                                 .isEnglishUS,
                                               isOffline: isAppOffline,
                                             ),
                                         ),
                                       );
                                     },
                                   )
                                 )
                               ]
                             )
                           );
                         },
                      );
                    }).toList()
                 ]
               );
              }
            )
          ) : (
            FutureBuilder(
              future: Offline().getRootTaxonomy(db, 'acls_6'),
              builder: (context, snapshot) {
                // returns error to screen if graphql query fails to complete
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error fetching terms'));
                }
                final terms = snapshot.data ?? [];
                return ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: ScrollPhysics(),
                  children: [
                    // upper part of the screen, ACLS section, displays taxonomy and content type ACLS-6
                    ...terms.map((term) {
                      final termId = term['id'].toString();
                      return FutureBuilder(
                        future: Offline().getNodesByTaxonomyId(
                          termId.toString(), widget.locale, 'acls_6', db),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error fetching child terms'));
                          }
                          final node = snapshot.data?.firstOrNull;
                          if (node == null) return SizedBox.shrink();
                          final label = node['label'] ?? 'No label';
                          final body = node['body'].replaceAll(', full_html', '') ?? 'No body';

                          final contentType = node['fieldContentTypeRawField']?['getString'].toUpperCase();
                          if (label == 'ACLS-6') {
                          return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                color: Colors.white,
                                child: SelectableAllenText(text: body, notes: [], currentNodeId: node['id'].toString() ?? '', isOffline: isAppOffline)
                              )
                            );
                          }
                          if (contentType == 'A') {
                            return ExpansionTile(
                              leading: Icon(Icons.keyboard_arrow_down), // Down arrow on the left
                              trailing: SizedBox.shrink(),
                              title: Text(label),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SelectableAllenText(text: body, notes: [], currentNodeId: node['id'].toString() ?? '', isOffline: isAppOffline)
                                ),
                              ],
                            );
                          }
                          // navigates to new screen when one of the pieces of content are pressed by user
                          return Container(
                            margin: EdgeInsets.only(left: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  size: 15.0,
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: Text(label),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>  AclsDetailsScreen(
                                            nodeId: node['id'].toString() ?? '',
                                            termId: termId,
                                            label: label,
                                            body: body,
                                            locale: widget.locale,
                                            isEnglishUS: widget.isEnglishUS,
                                            isOffline: isAppOffline,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                               )
                             ]
                           )
                         );
                       }
                     );
                    }).toList()
                  ]
                );
              })
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Activities',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // lower part of the screen, Activities section, displays ACLS-6 Activities content labels
          // navigates to a new screen when user presses on one of the activities
          ...activities.map((activity) {
            String fallbackLabel = '';
            String fallbackBody = '';
            String translatedLabel = '';
            String translatedBody = '';
            String activityId = '';
            if (!isAppOffline) {
              fallbackLabel = activity['label'] ?? 'No label';
              fallbackBody =
                activity['bodyRawField']?['getString'] ?? '';
              translatedLabel =
                activity['translation']?['titleRawField']?['getString'];
              translatedBody =
                activity['translation']?['bodyRawField']?['getString'];
              activityId =
                activity['fieldActivityIdRawField']?['getString'] ?? '';
            }
            else {
              fallbackLabel = activity['label'] ?? 'No label';
              fallbackBody = activity['body'] ?? '';
              translatedLabel = activity['label'] ?? 'No label';
              translatedBody = activity['body'] ?? '';
              activityId = activity['activity_id'] ?? '';
            }
            final label = widget.isEnglishUS && translatedLabel != ''
              ? translatedLabel
              : fallbackLabel;
            final body = widget.isEnglishUS && translatedBody != ''
              ? translatedBody
              : fallbackBody;
            return Container(
              margin: EdgeInsets.only(left: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 15.0,
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(label),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActivityStartScreen(
                              label: label,
                              body: body,
                              activityId: activityId,
                              isEnglishUS: widget.isEnglishUS,
                              locale: widget.locale,
                              isOffline: isAppOffline,
                            ),
                          ),
                        );
                      },
                    )
                  )
                ]
              )
            );
          }).toList(),
        ],
      )
    );
  }
}
