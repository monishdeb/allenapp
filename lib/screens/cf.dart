import 'dart:io';

import 'package:allenapp/services/Offline.dart';

import '../models/selectableText.dart';
import '../models/footer.dart';
import '../services/query.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/left_drawer.dart';

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
        currentScreen: 'conceptual_framework',
      ),
      body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar
          Container(
            color: Colors.grey[800],
            padding: EdgeInsets.symmetric(horizontal: 16),
            height: 56,
            alignment: Alignment.center,
            child: Text(
              'Conceptual Framework',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.zero,
            child: Container(
              padding: EdgeInsets.zero,
              color: Colors.white,
              child: FutureBuilder(
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
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: ListView.builder(
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
                  ));
                },
              )
            )
          ),
          AllenAppFooter(
            locale: widget.locale,
            isEnglishUS: widget.isEnglishUS,
          ),
        ],
        )
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
    List<Map<String, dynamic>> notes = await Offline().getNotesByNode(int.parse(currentNodeId), db);
    setState(() {
      userNotes = notes;
      isLoading = false;
    });
  }

  // fetches the content under the current taxonomy term and child terms
  void fetchContentAndChildren() async {
    List foundItems = [];
    List childItems = [];
    foundItems = await Offline().getNodesByTaxonomyId(widget.termId, widget.locale, 'conceptual_framework', db);
    childItems = await Offline().getCFTerms(db, widget.termId);
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
    var widgetContent = parseHtmlString(termContent?['body'] ?? '');
    var termTitle = (termContent?['label'] ?? termContent?['title']);
    mainWidget = TableRow(
        children: [
        ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 8.0),
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
                padding: const EdgeInsets.only(left: 8.0),
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
            padding: const EdgeInsets.only(left: 8.0),
            child: SelectableAllenText(
              text: widgetContent, notes: userNotes, currentNodeId: termContent?['id'].toString() ?? '', isOffline: isAppOffline
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
        padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
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
