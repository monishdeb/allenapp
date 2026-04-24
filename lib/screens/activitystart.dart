import 'package:allenapp/services/Offline.dart';
import 'package:flutter_launcher_icons/android.dart';
import '../models/footer.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import 'activitydetail.dart';
import '../models/selectableText.dart';
import '../services/auth.dart';
import '../services/HtmlParser.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/left_drawer.dart';

// screen that renders when the user selects one of the Activities from the ACLS-6 page
class ActivityStartScreen extends StatefulWidget {
  final String label;
  final String body;
  final String activityId;
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;

  const ActivityStartScreen({
    Key? key,
    required this.label,
    required this.body,
    required this.activityId,
    required this.isEnglishUS,
    required this.locale,
    required this.isOffline
  }) : super(key: key);

  @override
  _ActivityStartScreenState createState() => _ActivityStartScreenState();
}

class _ActivityStartScreenState extends State<ActivityStartScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> activities = [];
  bool isAppOffline = false;
  String currentLocale = 'EN';
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    currentLocale = widget.locale;
    isAppOffline = widget.isOffline;
  }

  void _onLocaleChange(String newLocale) {
    setState(() {
      currentLocale = newLocale;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchActivities();
  }

  // fetches all the activities under the parent activity that was chosen
  Future<void> fetchActivities() async {
    List items = [];
    if (!isAppOffline) {
      var database = db;
      if (database == null || !database.isOpen) {
        await initDatabase(false);
      }
      else {
        await Offline().getSourceData(database, false);
      }
    }
    items = await Offline().getActivities(currentLocale, db, null);

    List<Map<String, dynamic>> filteredItems = [];

    final regex = RegExp(r'\.\d{1,3}$');

    for (var item in items) {
      String activityId = '';
      activityId = item['activity_id'] ?? '';
      if (activityId.startsWith(widget.activityId)) {
        final suffix = activityId.substring(widget.activityId.length);

        if (regex.hasMatch(suffix)) {
          filteredItems.add(item);
        }
      }
    }

    setState(() {
      activities = List<Map<String, dynamic>>.from(filteredItems);
    });
  }

  void _onChangeOffline(bool? isOffline) async {
    await setOfflineStatus(isOffline ?? false, true);
    await setOfflineDate(DateTime.now().millisecondsSinceEpoch);
    setState(() {
      isAppOffline = isOffline ?? false;
    });
    fetchActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[200],
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        locale: currentLocale,
        isEnglishUS: (currentLocale == 'EN'),
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
                          locale: currentLocale,
                          isEnglishUS: (currentLocale == 'EN'),
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
        locale: currentLocale,
        isEnglishUS: (currentLocale == 'EN'),
        isOffline: isAppOffline,
        onOfflineChange: _onChangeOffline,
        onLocaleChange: _onLocaleChange,
      ),
      drawer: LeftNavDrawer(
        locale: currentLocale,
        isEnglishUS: (currentLocale == 'EN'),
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
              child:
                Container(
                color: Colors.white,
                child: Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        color: Colors.white,
                        child: SelectableAllenText(text: HtmlParser().parseHtmlString(widget.body), notes: [], isOffline: isAppOffline),
                      )
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      color: Colors.white,
                      child: activities.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: activities
                          .where((activity) => !(activity['label']
                            ?.toString()
                            .contains('Scoring Criterion') ??
                            false))
                          .map((activity) {
                            String label = '';
                            String body = '';
                            String decisionLabel = '';
                            String decisionBody = '';
                            String decisionTaxonomy = '';
                            String decisionTarget = '';
                            String activityId = '';
                            label = ((activity['label'] ?? '') == '' ? '' : activity['label']);
                            body = ((activity['body'] ?? '')  == '' ? '' : activity['body']);
                            decisionTarget = ((activity['decision_targets'] ?? '')  == '' ? '' : activity['decision_targets']);
                            decisionBody = ((activity['decision_body'] ?? '')  == '' ? '' : activity['decision_body']);
                            decisionTaxonomy = ((activity['decision_taxonomy_ids'] ?? '') == '' ? '' : activity['decision_taxonomy_ids']);
                            decisionLabel = ((activity['decision_labels'] ?? '') == '' ? '' : activity['decision_labels']);
                            activityId = ((activity['activity_id'] ?? '') == '' ?  '' : (activity['activity_id'] ?? ''));

                            List<String> parts = activityId.split('.');

                            if (activityId.split('.').length > 2) {
                             return SizedBox.shrink();
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ActivityDetailsScreen(
                                      nodeId: activity['id'].toString() ?? '',
                                      label: label,
                                      body: body,
                                      decisionBody: decisionBody,
                                      activityId: activityId,
                                      decisionLabel: decisionLabel,
                                      decisionTarget: decisionTarget,
                                      decisionTaxonomy: decisionTaxonomy,
                                      isEnglishUS: (currentLocale == 'EN'),
                                      locale: currentLocale,
                                      isOffline: isAppOffline,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          HtmlParser().parseHtmlString(label),
                                          style: TextStyle(
                                              fontSize: 18,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_outlined,
                                        size: 16.0,
                                      ),
                                      //HtmlWidget(
                                        //parseHtmlString(body),
                                      //),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    )
                  ]
                )
              )
            ),
            AllenAppFooter(
              locale: currentLocale,
              isEnglishUS: (currentLocale == 'EN'),
            ),
          ]
        ),
      ),
    );
  }
}
