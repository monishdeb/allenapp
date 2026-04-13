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
      notes = [];
    });
    items = await Offline().getAllNotes(db, widget.locale);
    for (var item in items) {
      var noteId = item['id'];
      var note = item['note'];
      var nodeId = item['node_id'].toString();
      var nodeType = '';
      var taxonomyId = '';
      var nodeBody = '';
      var nodeLabel = '';
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
        title: Image(image: AssetImage("images/Allen_App_title.png"), height: 50)
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
