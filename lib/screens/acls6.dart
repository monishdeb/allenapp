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
    if (!isAppOffline) {
      var database = db;
      if (database == null || !database.isOpen) {
        await initDatabase(false);
      }
      else {
        await Offline().getSourceData(database, false);
      }
    }
    List items = [];
    setState(() {
      activities = [];
    });
    items = await Offline().getActivities(widget.locale, db, null);
    List<Map<String, dynamic>> filteredItems = [];
    // only keeps the items with activity ID in the form Activity Name 1
    for (var item in items) {
      if ((item['activity_id'] ?? '').endsWith(' 1')) {
        filteredItems.add(item);
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
       title: Image(image: AssetImage("images/Allen_App_title.png"), height: 50),
       actions: [IconButton(onPressed: menu.openEndDrawer, icon: Icon(Icons.menu))]
    );
    if (isLoading) {
      return loadingScreen(isEnglishUS: widget.isEnglishUS, locale: widget.locale);
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
                            tilePadding: EdgeInsets.only(left: 8.0),
                            leading: Icon(Icons.keyboard_arrow_down), // Down arrow on the left
                            trailing: SizedBox.shrink(),
                            title: Text(label, style: TextStyle(fontSize: 18)),
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
                                  contentPadding: EdgeInsets.only(left: 8.0),
                                  title: Text(label, style: TextStyle(fontSize: 18)),
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
            }
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
            fallbackLabel = activity['label'] ?? 'No label';
            fallbackBody = activity['body'] ?? '';
            translatedLabel = activity['label'] ?? 'No label';
            translatedBody = activity['body'] ?? '';
            activityId = activity['activity_id'] ?? '';
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
                      title: Text(label, style: TextStyle(fontSize: 18)),
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
