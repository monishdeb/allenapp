import 'package:allenapp/screens/aclsdetails.dart';
import 'package:allenapp/screens/activitydetail.dart';
import 'package:allenapp/screens/cf.dart';
import 'package:allenapp/screens/loadingScreen.dart';
import 'package:allenapp/services/Offline.dart';
import 'package:allenapp/services/query.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:footer/footer_view.dart';
import '../services/auth.dart';
import '../models/footer.dart';
import '../models/menu.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../screens/detailscreen.dart';
import '../services/Notes.dart';


class NotesPage extends StatefulWidget {
  final String locale;
  final bool isOffline;

  const NotesPage({Key? key, required String this.locale, required this.isOffline}): super(key: key);

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  bool loading = true;
  bool isAppOffline = false;
  List<Map<String, dynamic>> notes = [];
  Map<String?,String> nodeTaxonomyCache = {};
  Map<String?,String> nodeBodyCache = {};
  Map<String?,String> nodeLabelCache = {};

  @override
  void initState() {
    super.initState();
    loading = true;
    isAppOffline = widget.isOffline;
    getNotes();
  }

  Future<void> getNotes() async {
    List items = [];
    setState(() {
      notes = [];
    });
    final GraphQLClient graphQLClient = client.value;
    if (!isAppOffline) {
      var userId = await getUserID();
      final result = await graphQLClient.query(
        QueryOptions(document: gql(getUserNotes), variables: {
          'user_id': userId
        }),
      );
      if (result.hasException) {
        print('Error fetching activities: ${result.exception.toString()}');
        return;
      }
      items = result.data?['entityQuery']['items'] ?? [];
    }
    else {
      items = await Offline().getAllNotes(db, widget.locale);
    }

    for (var item in items) {
      var noteId = item['id'];
      var note = (isAppOffline ? item['note'] : item['label']);
      var nodeId = (isAppOffline ? item['node_id'].toString() : item['nodeIdRawField']['getString']);
      var nodeType = '';
      var taxonomyId = '';
      var nodeBody = '';
      var nodeLabel = '';
      if (!isAppOffline) {
        for (var reference in item['nodeIdRawField']['entity']['referencedEntities']) {
          if (reference['entityTypeId'] != 'node') {
            continue;
          }
          if (reference['id'] == nodeId &&
              reference['entityTypeId'] == 'node') {
            nodeType = reference['entityBundle'];
          }
          var nodeField = '';
          if (nodeType == 'web_app') {
            nodeField = 'fieldAllenCognitiveLevelRawField';
          }
          if (nodeType == 'conceptual_framework') {
            nodeField = 'fieldConceptualFrameworkRawField';
          }
          if (nodeType == 'acls_6_activities') {
            nodeField = 'fieldActivityIdRawField';
          }
          if (nodeType == 'acls6') {
            nodeField = 'fieldAcls6RawField';
          }
          if (nodeTaxonomyCache.containsKey(nodeId)) {
            taxonomyId = nodeTaxonomyCache[nodeId] ?? '';
          }
          else {
            final nodeResult = await graphQLClient.query(
                QueryOptions(
                    document: gql(getNode), variables: {'nodeId': nodeId})
            );

            if (!nodeResult.hasException) {
              taxonomyId =
              nodeResult
                  .data?['entityQuery']['items'][0][nodeField]['getString'];
              nodeTaxonomyCache[nodeId] = taxonomyId;
              if (nodeType == 'acls6') {
                nodeBodyCache[nodeId] = nodeResult
                    .data?['entityQuery']['items'][0]['bodyRawField']['getString'];
                nodeLabelCache[nodeId] =
                nodeResult.data?['entityQuery']['items'][0]['label'];
              }
            }
          }
        }
      }
      else {
        nodeType = item['node_type'];
        if (nodeTaxonomyCache.containsKey(noteId)) {
          taxonomyId = nodeTaxonomyCache[nodeId] ?? '';
        }
        else {
          taxonomyId = item['taxonomy_id'].toString();
          nodeTaxonomyCache[nodeId] = taxonomyId;
          nodeBodyCache[nodeId] = item['body'];
          nodeLabelCache[nodeId] = item['title'];
        }
      }
      notes.add({
        'noteId': noteId,
        'note': note,
        'nodeType': nodeType,
        'taxonomyId': taxonomyId,
        'nodeBody': nodeBodyCache[nodeId] ?? nodeBody,
        'nodeLabel': nodeLabelCache[nodeId] ?? nodeLabel
      });
    }
    setState(() {
      notes = notes;
      loading = false;
    });
  }

  void _onChangeOffline(bool? isOffline) async {
    setState(() {
      loading = true;
    });
    await setOfflineStatus(isOffline ?? false, true);
    await setOfflineDate(DateTime.now().millisecondsSinceEpoch);
    setState(() {
      isAppOffline = isOffline ?? false;
    });
    getNotes();
  }
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return loadingScreen(isEnglishUS: (widget.locale == 'EN'), locale: widget.locale);
    }
    var menu = Menu(scaffoldKey: _scaffoldKey, locale: widget.locale, isEnglishUS: (widget.locale == 'EN'), isOffline: isAppOffline, onOfflineChange: _onChangeOffline);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Saved Notes',
          style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)
        )
      ),
      endDrawer: menu,
      body: FooterView(
        footer: AllenAppFooter(locale: widget.locale, isEnglishUS: (widget.locale == 'EN')),
        flex: 1,
        children: [
          Container(
            color: Colors.grey[800],
            padding: EdgeInsets.symmetric(horizontal: 16),
            height: 56, // Same as AppBar height
            alignment: Alignment.center,
            child: Text(
              'Notes',
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
                              ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                physics: ScrollPhysics(),
                                itemCount: notes.length,
                                itemBuilder: (context, index) {
                                  final note = notes[index];
                                  return Container(
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16),
                                      title: Text(note['note']),
                                      leading: Icon(
                                        Icons.arrow_forward_ios_outlined,
                                        size: 15.0,
                                      ),
                                      onTap: () {
                                        if (note['nodeType'] == 'web_app' || note['node_type'] == 'web_app') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TaxonomyDetailScreen(
                                                  id: note['taxonomyId'],
                                                  isEnglishUS: (widget.locale == 'EN_US'),
                                                  locale: widget.locale,
                                                  isOffline: isAppOffline
                                              ),
                                            ),
                                          );
                                        }
                                        else if (note['nodeType'] == 'conceptual_framework' || note['node_type'] == 'conceptual_framework') {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => ConceptualFrameworksScreen(isEnglishUS: (widget.locale == 'en'), locale: widget.locale, isOffline: isAppOffline))
                                          );
                                        }
                                        else if (note['nodeType'] == 'acls_6_activities' || note['node_type'] == 'acls_6_activities') {
                                           fetchTargetData(context, note['taxonomyId'], widget.locale, isAppOffline);
                                        }
                                        else if (note['nodeType'] == 'acls6' || note['node_type'] == 'acls6') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => AclsDetailsScreen(
                                              termId: note['taxonomyId'],
                                              body: note['nodeBody'],
                                              nodeId: note['nodeId'],
                                              locale: widget.locale,
                                              label: note['nodeLabel'],
                                              isEnglishUS: (widget.locale == 'EN_US'),
                                              isOffline: isAppOffline
                                            ))
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }
                              )
                            ]
                        )
                      ]
                  )
              )
          )
        ],
      ),
    );
  }
}
