import 'loadingScreen.dart';
import '../services/Offline.dart';
import '../models/footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import 'activitystart.dart';
import 'detailscreen.dart';
import 'acls6.dart';
import '../models/menu.dart';
import '../models/selectableText.dart';
import '../services/auth.dart';
import '../services/Notes.dart';
import '../Env.dart';

// screen that renders once the user starts one of the activities
class ActivityDetailsScreen extends StatefulWidget {
  final String label;
  final String body;
  final String decisionBody;
  final String activityId;
  final String decisionLabel;
  final String decisionTarget;
  final String decisionTaxonomy;
  final bool isEnglishUS;
  final String locale;
  final String nodeId;
  bool isOffline;

  ActivityDetailsScreen({
    Key? key,
    required this.label,
    required this.body,
    required this.decisionBody,
    required this.activityId,
    required this.decisionLabel,
    required this.decisionTarget,
    required this.decisionTaxonomy,
    required this.isEnglishUS,
    required this.locale,
    required this.nodeId,
    required this.isOffline,
  }) : super(key: key);

  @override
  _ActivityDetailsScreenState createState() => _ActivityDetailsScreenState();
}


class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  bool isAppOffline = false;
  bool isLoading = true;
  List<Map<String, dynamic>> userNotes = [];
  @override
  void initState() {
    super.initState();
    isLoading = true;
    isAppOffline = widget.isOffline;
    fetchNotes(widget.nodeId, userNotes);
  }
  Future<void> fetchNotes(currentNodeId, userNotes)  async {
    if (isAppOffline) {
      userNotes = await Offline().getNotesByNode(int.parse(currentNodeId ?? ''), db);
    }
    else {
      await getUserID().then((currentUserId) async {
        final GraphQLClient graphQLClient = client.value;
        final QueryResult res = await graphQLClient.query(
            QueryOptions(document: gql(getNotesForNode),
                variables: {'nodeId': currentNodeId, 'user_id': currentUserId})
        ).then((result) {
          userNotes = List<Map<String, dynamic>>.from(
              result.data?['entityQuery']['items'] ?? []);
          return result;
        });
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  // function to remove "full_html" from end of queried content
  String parseHtmlString(String htmlString) {
    String parsedText = htmlString;
    if (parsedText.endsWith(", full_html")) {
      parsedText = parsedText.substring(0, parsedText.length - 11);
    }
    parsedText.replaceAll('"/sites', '"' + Env.DRUPAL_URL + '/sites');
    return parsedText.trim();
  }

  void _onChangeOffline(bool? isOffline) async {
    setState(() {
      isLoading = true;
    });
    await setOfflineStatus(isOffline ?? false, true);
    await setOfflineDate(DateTime.now().millisecondsSinceEpoch);
    List<Map<String, dynamic>> userNotes = [];
    fetchNotes(widget.nodeId, userNotes);
    setState(() {
      isAppOffline = isOffline ?? false;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    if (isLoading) {
      return loadingScreen(isEnglishUS: widget.isEnglishUS, locale: widget.locale);
    }
    // separates queried decision labels into an array of labels separated by commas
    List<String> decisionLabels = [];
    for(var label in widget.decisionLabel.split(',')) {
      if (label.trim() != 'basic_html' && label.trim() != 'full_html') {
        decisionLabels.add(label.trim());
      }
    }
    // separates queried decision targets into an array of targets separated by commas
    List<String> decisionTargets =
      widget.decisionTarget.split(',').map((e) => e.trim()).toList();
    // separates queried decision taxonomies into an array of taxonomies separated by commas
    List<String> decisionTaxonomies = widget.decisionTaxonomy
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    // separates queried decision bodies into an array of text separated by "full_html"
    List<String> decisionBodies = widget.decisionBody
        .split('full_html')
        .map((e) => e.replaceAll(',', '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
    // throws error if num of labels and bodies don't match for now
    if (decisionBodies.isNotEmpty &&
        decisionBodies.length != decisionLabels.length) {
      throw Exception(
          "Number of decision labels and decision bodies must be the same.");
    }

    Map<int, VoidCallback> buttonActions = {};
    Map<int, String?> associatedTaxonomies = {};
    int? otherActivity;

    // step 1: assign taxonomies to 'Next' labels
    List<int> nextLabelIndexes = [];
    List<int> backLabelIndexes = [];
    for (int i = 0; i < decisionLabels.length; i++) {
      if (decisionLabels[i] == "Next") {
        nextLabelIndexes.add(i);
      }
      else if (decisionLabels[i] == "More") {
        otherActivity = i;
      }
      else if (decisionLabels[i] == "Back") {
        backLabelIndexes.add(i);
      }
    }
    if (decisionTaxonomies.isNotEmpty) {
      if (nextLabelIndexes.length != decisionTaxonomies.length && nextLabelIndexes.isNotEmpty) {
        try {
          throw Exception(
            "Number of 'Next' labels does not match number of decision taxonomies.");
        } on Exception catch (e) {
            // Handle soft exception gracefully
            print(e);
            debugPrint(
              "Warning: ${nextLabelIndexes.length} 'Next' labels but "
              "${decisionTaxonomies.length} decision taxonomies"
            );
        }
      }

      if (nextLabelIndexes.isNotEmpty) {
      for (int i = 0; i < decisionTaxonomies.length; i++) {
        int labelIndex = nextLabelIndexes[i];
        String taxonomyId = decisionTaxonomies[i];

        associatedTaxonomies[labelIndex] = taxonomyId;
        buttonActions[labelIndex] = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaxonomyDetailScreen(
                // navigates user to taxonomy screen when decision taxonomy is pressed
                id: taxonomyId,
                isEnglishUS: widget.isEnglishUS,
                locale: widget.locale,
                isOffline: isAppOffline,
              ),
            ),
          );
        };
      }
      }
    }
    // step 2: assign remaining decision targets to remaining labels
    int targetIndex = 0;
    for (int i = 0; i < decisionLabels.length; i++) {
      // if this index already has a taxonomy, skip it
      if (buttonActions.containsKey(i)) continue;

      if (targetIndex < decisionTargets.length) {
        String targetId = decisionTargets[targetIndex];
        buttonActions[i] = () {
          fetchTargetData(context, targetId, widget.locale, isAppOffline);
        };
        targetIndex++;
      } else {
        if (otherActivity != null && i == otherActivity) {
          buttonActions[i] = () {
            Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) =>  AclsTermsScreen(
                   isEnglishUS: widget.isEnglishUS,
                   locale: widget.locale,
                   isOffline: isAppOffline,
                ),
              ),
            );
          };
        }
        else {
          // step 3: leftover label, no taxonomy or target
          buttonActions[i] = () {
            print("No target for this button");
          };
        }
      }
    }
    var menu = Menu(scaffoldKey: _scaffoldKey, locale: widget.locale, isEnglishUS: widget.isEnglishUS, isOffline: isAppOffline, onOfflineChange: _onChangeOffline);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Image(image: AssetImage("images/Allen_App_title.png"), height: 50),
        actions: [IconButton(onPressed: menu.openEndDrawer, icon: Icon(Icons.menu))],
      ),
      endDrawer: menu,
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
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    SizedBox(height: 8),
                    SelectableAllenText(text: parseHtmlString(widget.body), notes: userNotes, currentNodeId: widget.nodeId, isOffline: isAppOffline),
                    SizedBox(height: 16),
                    for (int i = 0; i < decisionLabels.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (decisionBodies.isNotEmpty &&
                                    i < decisionBodies.length)
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: SelectableAllenText(
                                        text: parseHtmlString(decisionBodies[i]), currentNodeId: widget.nodeId, notes: userNotes, isOffline: isAppOffline,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero
                                  ),
                                  backgroundColor: Colors.grey[800],
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(40, 40), //////// HERE
                                ),
                                onPressed: buttonActions[i],
                                child: Text(decisionLabels[i], style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ),
              AllenAppFooter(
                locale: widget.locale,
                isEnglishUS: widget.isEnglishUS,
              ),
            ]
          )
        ),
    );
  }
}
