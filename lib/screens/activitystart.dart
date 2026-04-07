import 'package:allenapp/services/Offline.dart';
import 'package:flutter_launcher_icons/android.dart';

import '../models/footer.dart';
import '../widgets/custom_app_bar.dart';
import '../models/left_drawer.dart';
import 'package:flutter/material.dart';
import 'package:footer/footer_view.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import 'activitydetail.dart';
import '../models/selectableText.dart';
import '../services/auth.dart';

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
  List<Map<String, dynamic>> activities = [];
  bool isAppOffline = false;
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    isAppOffline = widget.isOffline;
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchActivities();
  }

  // remove "full_html" from end of string
  String parseHtmlString(String htmlString) {
    String parsedText = htmlString;

    if (parsedText.endsWith(", full_html")) {
      parsedText = parsedText.substring(0, parsedText.length - 11);
    }

    return parsedText.trim();
  }

  // fetches all the activities under the parent activity that was chosen
  Future<void> fetchActivities() async {
    List items = [];
    if (!isAppOffline) {
      final GraphQLClient graphQLClient = GraphQLProvider
          .of(context)
          .value;

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
    else {
      items = await Offline().getActivities(widget.locale, db, null);
    }

    List<Map<String, dynamic>> filteredItems = [];

    final regex = RegExp(r'\.\d{1,3}$');

    for (var item in items) {
      String activityId = '';
      if (!isAppOffline) {
        activityId = item['fieldActivityIdRawField']?['getString'] ?? '';
      }
      else {
        activityId = item['activity_id'] ?? '';
      }

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
      key: _scaffoldState,
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
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldState,
        locale: widget.locale,
        isEnglishUS: widget.isEnglishUS,
        isOffline: isAppOffline,
        onOfflineChange: _onChangeOffline,
      ),
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: FooterView(footer: AllenAppFooter(locale: widget.locale, isEnglishUS: widget.isEnglishUS),
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
              padding: const EdgeInsets.all(8.0),
              child: Container(
                color: Colors.white,
                child: SelectableAllenText(text: parseHtmlString(widget.body), notes: [], isOffline: isAppOffline),
              )
          ),
          SingleChildScrollView(
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
                    if (!isAppOffline) {
                      var activityDetails = activity['translation'];
                      label = activity['label'] ?? 'No label';
                      body =
                        activityDetails['bodyRawField']?['getString'] ??
                          'No body';
                      decisionLabel =
                        activityDetails['fieldDecisionLabelRawField']
                          ?['getString'] ?? 'No decision label';
                      decisionBody =
                        activityDetails['fieldDecisionBodyRawField']
                          ?['getString'] ?? 'No decision body';
                      activityId =
                        activityDetails['fieldActivityIdRawField']?['getString'] ??
                          '';
                      decisionTarget =
                        activityDetails['fieldDecisionTargetRawField']?['getString'] ??
                          'No decision target';
                      decisionTaxonomy =
                        activityDetails['fieldDecisionTaxonomyRawField']
                          ?['getString'] ?? 'No decision taxonomy';
                    }
                    else {
                      label = ((activity['label'] ?? '') == '' ? '' : activity['label']);
                      body = ((activity['body'] ?? '')  == '' ? '' : activity['body']);
                      decisionTarget = ((activity['decision_targets'] ?? '')  == '' ? '' : activity['decision_targets']);
                      decisionBody = ((activity['decision_body'] ?? '')  == '' ? '' : activity['decision_body']);
                      decisionTaxonomy = ((activity['decision_taxonomy_ids'] ?? '') == '' ? '' : activity['decision_taxonomy_ids']);
                      decisionLabel = ((activity['decision_labels'] ?? '') == '' ? '' : activity['decision_labels']);
                      activityId = ((activity['activity_id'] ?? '') == '' ?  '' : (activity['activity_id'] ?? ''));
                    }

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
                              isEnglishUS: widget.isEnglishUS,
                              locale: widget.locale,
                              isOffline: isAppOffline,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                 Icons.arrow_forward_ios_outlined,
                                 size: 18.0,
                              ),
                              SizedBox(height: 8),
                              Text(
                                parseHtmlString(label),
                                style: TextStyle(
                                    fontSize: 18
                                ),
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
        )]),
      ),
    );
  }
}
