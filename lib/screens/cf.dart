import 'dart:io';

import 'package:allenapp/services/Offline.dart';

import '../models/selectableText.dart';
import '../models/footer.dart';
import '../services/query.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../widgets/custom_app_bar.dart';
import 'package:footer/footer_view.dart';
import '../services/auth.dart';

// screen that renders when the user selected Conceptual Frameworks from main menu page
class ConceptualFrameworksScreen extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;

  ConceptualFrameworksScreen(
      {required this.isEnglishUS, required this.locale, required this.isOffline});

  @override
  _ConceptualFrameworkScreenState createState() => _ConceptualFrameworkScreenState();
}


class _ConceptualFrameworkScreenState extends State<ConceptualFrameworksScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isAppOffline = false;

  @override
  void initState() {
    super.initState();
    isAppOffline = widget.isOffline;
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
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        locale: widget.locale,
        isEnglishUS: widget.isEnglishUS,
        isOffline: isAppOffline,
        onOfflineChange: _onChangeOffline,
      ),
      endDrawer: SettingsDrawer(
        locale: widget.locale,
        isEnglishUS: widget.isEnglishUS,
        isOffline: isAppOffline,
        onOfflineChange: _onChangeOffline,
      ),
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
              'Conceptual Framework',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          !isAppOffline ? (
            Query(
              options: QueryOptions(document: gql(getParentCFTerms)),
              builder: (QueryResult result, {fetchMore, refetch}) {
                if (result.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (result.hasException) {
                  return Center(child: Text("Error: ${result.exception.toString()}"));
                }
                List items = result.data?["entityQuery"]["items"] ?? [];
                return ListView.builder(
                    itemCount: items.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    physics: ScrollPhysics(),
                    itemBuilder: (context, index) {
                      var term = items[index];
                      return Container(
                        width: double.infinity, // Make each item take full width
                        child: TermAccordion(
                          termId: term["id"],
                          fallbackLabel: term["label"],
                          isEnglishUS: widget.isEnglishUS,
                          locale: widget.locale,
                          isAutoExpand: true,
                          isOffline: isAppOffline,
                        ),
                      );
                    },
                );
              },
            )
          ) : (
            FutureBuilder(
              future: Offline().getCFTerms(db, '0'),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error fetching child terms'));
                }
                List items = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: items.length,
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: ScrollPhysics(),
                  itemBuilder: (context, index) {
                    var term = items[index];
                    var title = term.containsKey('title') ? term['title'] : term['label'];
                    return SizedBox(
                      width: double.infinity, // Make each item take full width
                      child: TermAccordion(
                        termId: term["id"].toString(),
                        fallbackLabel: title,
                        isEnglishUS: widget.isEnglishUS,
                        locale: widget.locale,
                        isAutoExpand: true,
                        isOffline: isAppOffline,
                      ),
                    );
                  },
                );
              },
            )
          )
        ],
      ),
    );
  }
}

// each individual Conceptual Frameworks content node is expressed as a TermAccordion
class TermAccordion extends StatefulWidget {
  final String termId;
  final String fallbackLabel;
  final bool isEnglishUS;
  final String locale;
  final bool isAutoExpand;
  final bool isOffline;

  TermAccordion(
      {required this.termId,
      required this.fallbackLabel,
      required this.isEnglishUS,
      required this.locale,
      required this.isOffline,
      this.isAutoExpand = false});

  @override
  _TermAccordionState createState() => _TermAccordionState();
}

class _TermAccordionState extends State<TermAccordion> {
  Map<String, dynamic>? termContent;
  List childTerms = [];
  List<Map<String, dynamic>> userNotes = [];
  bool isLoading = true;
  bool _isInitialized = false;
  TableRow mainWidget = TableRow();
  bool isAppOffline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isAppOffline = widget.isOffline;
    if (!_isInitialized) {
      _isInitialized = true;
      fetchContentAndChildren();
    }
  }

  Future<void> fetchNotes(currentNodeId)  async {
    if (isAppOffline) {
      List<Map<String, dynamic>> notes = await Offline().getNotesByNode(int.parse(currentNodeId), db);
      setState(() {
        userNotes = notes;
        isLoading = false;
      });
    }
    else {
      await getUserID().then((currentUserId) async {
        final GraphQLClient graphQLClient = client.value;
        final QueryResult res = await graphQLClient.query(
            QueryOptions(document: gql(getNotesForNode),
                variables: {
                  'nodeId': currentNodeId.toString(),
                  'user_id': currentUserId
                })
        ).then((result) {
          List<Map<String, dynamic>> notes = List<Map<String, dynamic>>.from(
              result.data?['entityQuery']['items'] ?? []);
          setState(() {
            userNotes = notes;
            isLoading = false;
          });
          return result;
        });
      });
    }
  }

  // fetches the content under the current taxonomy term and child terms
  void fetchContentAndChildren() async {
    List foundItems = [];
    List childItems = [];
    if (isAppOffline) {
      foundItems = await Offline().getNodesByTaxonomyId(widget.termId, widget.locale, 'conceptual_framework', db);
      childItems = await Offline().getCFTerms(db, widget.termId);
    }
    else {
      final client = GraphQLProvider
          .of(context)
          .value;
      final termContentResult = await client.query(QueryOptions(
        document: gql(getCFNodesByTerm),
        variables: {"termId": widget.termId, 'langcode': widget.locale},
      ));

      final childTermsResult = await client.query(QueryOptions(
        document: gql(getChildCFTerms),
        variables: {
          "parentIds": [widget.termId]
        },
      ));
      foundItems = termContentResult.data?["entityQuery"]["items"] ?? [];
      childItems = childTermsResult.data?["entityQuery"]["items"] ?? [];
    }
    setState(() {
      List items = foundItems;
      termContent = items.isNotEmpty ? items[0] : null;
      childTerms = childItems;
    });
    await fetchNotes(termContent?['id'].toString() ?? '0');
  }

  String parseHtmlString(String htmlString) {
    String parsedText = htmlString;
    if (htmlString.endsWith(", full_html")) {
      parsedText = htmlString.substring(0, htmlString.length - 11);
    }

    return parsedText.trim();
  }

  @override
  Widget build(BuildContext context) {
    var widgetContent = (isAppOffline ? parseHtmlString(termContent?['body'] ?? '') : parseHtmlString(termContent?['translation']?['bodyRawField']
    ?['getString'] ??
        "No Content Available"));
    var termTitle = (isAppOffline ? (termContent?['label'] ?? termContent?['title']) : (termContent?['translation']?['titleRawField']
    ?['getString'] ??
        widget.fallbackLabel));
    mainWidget = TableRow(
        children: [
        ExpansionTile(
      title: isLoading
          ? Text("Loading...",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          : (widget.isAutoExpand ? Text('') : (Text(termTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
      children: [
        if (isLoading)
          Center(child: CircularProgressIndicator())
        else ...[
          if (termContent != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                color: Colors.white,
                child: SelectableAllenText(text: widgetContent, notes: userNotes, currentNodeId: termContent?['id'].toString() ?? '', isOffline: isAppOffline)
              )
            ),
          if (childTerms.isNotEmpty)
            Padding(
              padding: EdgeInsets.zero,
              child: Container(
                color: Colors.white,
                child: Column(
                children: childTerms.map((child) {
                  //recursively renders current widget/component to display child term content
                  var label = child.containsKey('label') ? child['label'] : child['title'];
                  return TermAccordion(
                      termId: child["id"].toString(),
                      fallbackLabel: label,
                      isEnglishUS: widget.isEnglishUS,
                      locale: widget.locale,
                      isOffline: isAppOffline,
                  );
                }).toList(),
              ),
            )),
        ],
      ],
    )]);
    if (widget.isAutoExpand) {
      mainWidget = TableRow(
        children: [
          Container(
           color: Colors.white,
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SelectableAllenText(
              text: parseHtmlString(widgetContent), notes: userNotes, currentNodeId: termContent?['id'].toString() ?? '', isOffline: isAppOffline
            ),
          ),
          if (childTerms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(1.0),
              child: Column(
                children: childTerms.map((child) {
                  var label = child.containsKey('label') ? child['label'] : child['title'];
                  //recursively renders current widget/component to display child term content
                  return TermAccordion(
                      termId: child["id"].toString(),
                      fallbackLabel: label,
                      isEnglishUS: widget.isEnglishUS,
                      locale: widget.locale,
                      isOffline: isAppOffline,
                  );
                }).toList(),
              ),
            ),
        ],
      ))]);
    }
    if (widget.isAutoExpand) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          //border: TableBorder.all(),
          columnWidths: {0: FlexColumnWidth()},
          children: [mainWidget],
        )
      );
    }
    else {
      return Table(
        //border: TableBorder.all(),
        columnWidths: {0: FlexColumnWidth()},
        children: [mainWidget],
      );
    }
  }
}
