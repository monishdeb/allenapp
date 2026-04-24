import 'package:allenapp/services/Offline.dart';

import '../services/auth.dart';
import 'package:flutter/material.dart';
import '../screens/home.dart';
import 'package:flutter/rendering.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import '../models/highlights.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../models/footer.dart';
import 'package:footer/footer_view.dart';
import '../models/arrow_label.dart';
import '../models/selectableText.dart';
import '../Env.dart';
import 'loadingScreen.dart';
import 'chartscreen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/left_drawer.dart';
import '../services/HtmlParser.dart';

// screen renders when user selects one of the Allen Cognitive Level terms on chart screen
class TaxonomyDetailScreen extends StatefulWidget {
  final String id;
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;
  final Map<String, Map<String, String>> siblings;

  const TaxonomyDetailScreen(
      {Key? key, required this.id, required this.isEnglishUS, required this.locale, required this.isOffline, this.siblings = const {}})
      : super(key: key);

  @override
  _TaxonomyDetailScreenState createState() => _TaxonomyDetailScreenState();
}

class _TaxonomyDetailScreenState extends State<TaxonomyDetailScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> childTermContent = [];
  List<Map<String, dynamic>> contentNodes = [];
  List<Map<String, dynamic>> modes = [];
  List<dynamic> profiles = [];
  List<Map<String, dynamic>> userNotes = [];
  String? previousNode;
  String previousNodeLabel = '';
  String childTerm = '';
  String? parentTerm;
  String childLabel = '';
  String parentLabel = '';
  String? rootTerm;
  String rootLabel = '';
  String currentTitle = '';
  String originalTitle = '';
  String selectedText = '';
  String? currentNodeId;
  bool isAppOffline = false;
  String currentLocale = 'EN';
  String labelKey = 'title';
  final TextEditingController _controller = TextEditingController();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }
    currentLocale = widget.locale;
    isAppOffline = widget.isOffline;

    // Use an async initializer so exceptions are easier to catch and we can await sequentially.
    _initAsync();
  }

  void _onLocaleChange(String newLocale) async {
    setState(() {
      currentLocale = newLocale;
    });
    await fetchTermContent(widget.id);
    await fetchNavigationTerms(widget.id);
    await fetchChildTermsAndContent(widget.id);
    await fetchNotes();
  }

  Future<void> _initAsync() async {
    try {
      var database = db;
      if (database == null || !database.isOpen) {
        database = await initDatabase(false);
      }
      else {
        await Offline().getSourceData(database, false);
      }
      await fetchTermContent(widget.id);
      await fetchNavigationTerms(widget.id);
      await fetchChildTermsAndContent(widget.id);
      await fetchNotes();
    } catch (e, st) {
      debugPrint('Initialization error: $e\n$st');
      // Keep loading false so UI doesn't hang indefinitely.
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onChangeOffline(bool? isOffline) async {
    setState(() {
      isLoading = true;
    });
    try {
      await setOfflineStatus(isOffline ?? false, true);
      await setOfflineDate(DateTime.now().millisecondsSinceEpoch);
      if (!mounted) return;
      setState(() {
        isAppOffline = isOffline ?? false;
      });
      await fetchTermContent(widget.id);
      await fetchNavigationTerms(widget.id);
      await fetchChildTermsAndContent(widget.id);
      await fetchNotes();
    } catch (e, st) {
      debugPrint('_onChangeOffline error: $e\n$st');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Replace only the fetchNavigationTerms implementation with the following.

Future<void> fetchNavigationTerms(String termId) async {
  try {
    String termTitle = '';
    var currentTermResult = await Offline().getACLTaxonomy(null, termId, db);
    if (currentTermResult.isNotEmpty) {
      termTitle = currentTermResult[0][labelKey] ?? '';
    }

    var currentTermId = termId;
    originalTitle = fixLabel(termTitle);

    // If on a subpage (e.g. "4 H 1" or "4.6") try to normalise to the parent term id we've stored
    if (isSubPage(fixLabel(termTitle))) {
      var parentTermResult = await Offline().getParentTaxonomyTerm(termId, db);
      if (parentTermResult.isNotEmpty) {
        currentTermId = parentTermResult[0]['id'].toString();
        if ('.'.allMatches(fixLabel(termTitle)).length >= 3) {
          var previousParentTermResult = await Offline().getParentTaxonomyTerm(currentTermId, db);
          if (previousParentTermResult.isNotEmpty) {
            currentTermId = (previousParentTermResult[0]['id'] ?? currentTermId).toString();
          }
        }
      }
    }

    String nextChildTermId = '';
    String? previousParentId;
    String? realParentId;
    String? rootParentTermId;
    String rootTitle = '';
    String parentTitle = '';
    String? parentTermId;
    List<Map<String, dynamic>> items = [];
    List childTaxonomyTerms = [];

    items = await Offline().getACLTaxonomy(null, currentTermId, db);
    parentTermId = items.isNotEmpty ? items[0]['parent_id'].toString() : null;
    termTitle = items.isNotEmpty ? items[0][labelKey] : termTitle;

    currentTitle = fixLabel(termTitle);
    if (items.isEmpty) {
      return;
    }

    Map<dynamic, dynamic> childTerms = {};
    Map<dynamic, dynamic> childLabels = {};

    if (parentTermId != null) {
      var parentTaxonomy = await Offline().getACLTaxonomy(null, parentTermId, db);
      if (parentTaxonomy.isNotEmpty) {
        parentTitle = parentTaxonomy[0][labelKey] ?? '';
        if (parentTitle.contains('M') || parentTitle.endsWith('H') || parentTitle.endsWith('L')) {
          var trueParent = await Offline().getParentTaxonomyTerm(parentTermId, db);
          if (trueParent.isNotEmpty) {
            realParentId = trueParent[0]['id'].toString();
            parentTitle = trueParent[0][labelKey] ?? parentTitle;
            childLabels[realParentId] = parentTitle;
          }
        }
      }

      var actualParentId = (realParentId != null ? realParentId : parentTermId);

      // Get the Previous parent e.g. 4 for 4 H
      var previousParent = await Offline().getParentTaxonomyTerm(actualParentId, db);
      if (previousParent.isNotEmpty) {
        previousParentId = previousParent[0]['id'].toString();
        if (previousParentId != "0") {
          var rootTaxonomy = await Offline().getACLTaxonomy(null, previousParentId, db);
          if (rootTaxonomy.isNotEmpty) {
            rootTitle = fixLabel(rootTaxonomy[0][labelKey] ?? '');
          }
        }
      }
      childTaxonomyTerms = await Offline().getACLTaxonomy(parentTermId, null, db);

      for (var childTermEntry in childTaxonomyTerms) {
        final id = childTermEntry['id'].toString();
        childLabels[id] = childTermEntry[labelKey];
        childTerms[id] = childTermEntry['weight'].toString() ?? '';
      }

      // --- Numeric successor lookup (if no child already resolved) ---
      String numericFoundChildLabel = '';
      try {
        if (nextChildTermId.isEmpty && RegExp(r'^\d+$').hasMatch(currentTitle)) {
          final int currentNum = int.parse(currentTitle);
          final int nextNum = currentNum + 1;

          String? foundId;
          String? foundLabel;

          try {
            final offlineList = await Offline().getACLTaxonomy(null, null, db);
            for (var pi in offlineList) {
              final rawLabel = (pi[labelKey] ?? '').toString().trim();
              final normalized = fixLabel(rawLabel);
              if (normalized == nextNum.toString()) {
                foundId = (pi['id'] ?? '').toString();
                foundLabel = normalized;
                break;
              }
            }
          } catch (e, st) {
            debugPrint('Offline getParentTerms lookup failed: $e\n$st');
          }

          if (foundId != null) {
            nextChildTermId = foundId;
            numericFoundChildLabel = foundLabel ?? '';
          }
        }
      } catch (e, st) {
        debugPrint('numeric next-child resolution error: $e\n$st');
      }

      // --- Numeric predecessor lookup: find "parent" numeric (e.g. parent of 3 is 2) ---
      String? numericParentId;
      String numericParentLabel = '';
      try {
        if (RegExp(r'^\d+$').hasMatch(currentTitle)) {
          final int currentNum = int.parse(currentTitle);
          if (currentNum > 1) {
            final int prevNum = currentNum - 1;
            String? foundParentId;
            String? foundParentLabel;
            try {
              final offlineList = await Offline().getACLTaxonomy(null, null, db);
              for (var pi in offlineList) {
                final rawLabel = (pi[labelKey] ?? '').toString().trim();
                final normalized = fixLabel(rawLabel);
                if (normalized == prevNum.toString()) {
                  foundParentId = (pi['id'] ?? '').toString();
                  foundParentLabel = normalized;
                  break;
                }
              }
            } catch (e, st) {
              debugPrint('Offline getParentTerms parent lookup failed: $e\n$st');
            }

            if (foundParentId != null) {
              numericParentId = foundParentId;
              numericParentLabel = foundParentLabel ?? '';
            }
          }
        }
      } catch (e, st) {
        debugPrint('numeric parent resolution error: $e\n$st');
      }

      // existing label normalisation and final assignments
      var finalChildLabelFromMap = childLabels[nextChildTermId] ?? '';
      finalChildLabelFromMap = fixLabel(childLabels[nextChildTermId] ?? '');
      var finalParentLabelFromMap = parentTitle;
      finalParentLabelFromMap = fixLabel(parentTitle);

      // prefer label found by numeric lookup for child, otherwise fall back to childLabels map
      final String finalChildLabel = numericFoundChildLabel.isNotEmpty ? numericFoundChildLabel : finalChildLabelFromMap;

      // prefer numericParentId (predecessor) as the parent shown on the left, otherwise use the usual actualParentId
      final String? chosenParentId = numericParentId ?? actualParentId;
      final String chosenParentLabel = numericParentId != null ? numericParentLabel : finalParentLabelFromMap;

      if (!mounted) return;
      setState(() {
        childTerm = nextChildTermId;
        parentTerm = chosenParentId;
        rootTerm = (previousParentId == '0' ? null : previousParentId);
        childLabel = finalChildLabel;
        parentLabel = chosenParentLabel;
        rootLabel = rootTitle;
      });
    }
  } catch (e, st) {
    debugPrint('fetchNavigationTerms error: $e\n$st');
  }
}

  String fixLabel(String currentLabel) {
    var finalLabel = currentLabel;
    if (currentLabel.indexOf('M') != -1) {
      try {
        finalLabel = currentLabel.substring(currentLabel.indexOf('M') + 2);
      } on RangeError catch (e) {
        finalLabel = currentLabel;
      }
    }
    return finalLabel;
  }

  bool isSubPage(String pageTitle) {
    return (((pageTitle.contains('H') || pageTitle.contains('L')) && !pageTitle.endsWith('H') && !pageTitle.endsWith('L')) || '.'.allMatches(pageTitle).length >= 2);
  }

  // queries for the content nodes associated with the current taxonomy term
  Future<void> fetchTermContent(String termId) async {
    try {
      List<Map<String, dynamic>> items = [];
      items = await Offline().getNodesByTaxonomyId(termId, currentLocale, 'allen_cognitive_levels', db);
      if (!mounted) return;
      setState(() {
        contentNodes = [...items];
        if (contentNodes.isNotEmpty) {
          currentNodeId = contentNodes[0]['id']?.toString();
          _controller.text = HtmlParser().parseHtmlString(contentNodes[0]['body'] ?? '');
        }
      });
    } catch (e, st) {
      debugPrint('fetchTermContent error: $e\n$st');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchNotes()  async {
    try {
      int? nodeId = currentNodeId != null ? int.tryParse(currentNodeId!) : null;
      if (nodeId == null) {
        if (mounted) {
          setState(() {
            userNotes = [];
            isLoading = false;
          });
        }
        return;
      }
      List<Map<String, dynamic>> notes = await Offline().getNotesByNode(nodeId, db);
      if (!mounted) return;
      setState(() {
        userNotes = notes;
        isLoading = false;
      });
    } catch (e, st) {
      debugPrint('fetchNotes error: $e\n$st');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // queries for the child terms under the current taxonomy term and the content nodes associated with them
  Future<void> fetchChildTermsAndContent(String parentId) async {
    try {
      List<Map<String, dynamic>> fetchedChildTermContent = [];
      List<Map<String, dynamic>> modeTerms = [];
      List childTerms = [];
      List modeItems = [];
      List profileItems = [];
      childTerms = await Offline().getChildTaxonomy(parentId, 'allen_cognitive_levels', db);

      for (var childTerm in childTerms) {
        String childId = childTerm['id'].toString();
        String childLabel = childTerm[labelKey] ?? '';

        // if finds umbrella term for mode terms, queries again for the actual modes
        if (childLabel.endsWith('L') || childLabel.endsWith('H')) {
          List<Map<String, dynamic>> contentItems = [];
          contentItems = await Offline().getNodesByTaxonomyId(childId.toString(), currentLocale, 'allen_cognitive_levels', db);

          for (var content in contentItems) {
            profileItems.add({
              'termId': childId,
              'termLabel': (content['label'] ?? ''),
            });
          }
          List hlChildTerms = [];
          hlChildTerms = await Offline().getChildTaxonomy(parentId, 'allen_cognitive_levels', db);
          for (var hlChildTerm in hlChildTerms) {
            if (hlChildTerm[labelKey].endsWith('M')) {
              childId = hlChildTerm['id'].toString();
              childLabel = hlChildTerm[labelKey] ?? '';
            }
          }
        }
        if (childLabel.endsWith('M')) {
          modeItems = await Offline().getChildTaxonomy(childId, 'allen_cognitive_levels', db);
          for (var item in modeItems) {
            List<Map<String, dynamic>> contentItems = [];
            contentItems = await Offline().getNodesByTaxonomyId(item['id'].toString(), currentLocale, 'allen_cognitive_levels', db);
            for (var content in contentItems) {
              modeTerms.add({
                'termId': item['id'].toString(),
                'termLabel': (content['label'] ?? ''),
                'contentId': content['id'].toString(),
                'body': (content['body'] ?? ''),
              });
            }
            modeTerms.sort((a, b) {
              final double aValue = _extractAclValue(a['termLabel']);
              final double bValue = _extractAclValue(b['termLabel']);
              return aValue.compareTo(bValue);
            });
          }
        } else {
          List<Map<String, dynamic>> items = [];
          items = await Offline().getNodesByTaxonomyId(childId, currentLocale, 'allen_cognitive_levels', db);
          List<Map<String, dynamic>> allItems = [...items];

          for (var item in allItems) {
            fetchedChildTermContent.add({
              'termId': childId,
              'termLabel': childLabel,
              'contentLabel': (item['label'] ?? ''),
              'contentId': item['id'],
              'body': (item['body'] ?? ''),
              'contentType': (item['content_type'] ?? ''),
            });
          }
        }
      }

      if (!mounted) return;
      setState(() {
        childTermContent = fetchedChildTermContent;
        modes = modeTerms;
        profiles = profileItems;
      });
    } catch (e, st) {
      debugPrint('fetchChildTermsAndContent error: $e\n$st');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double _extractAclValue(String label) {
    // Expected format: "ACL 1.6: Trunk Control"
    final RegExp regex = RegExp(r'ACL\s+([\d.]+)');
    final Match? match = regex.firstMatch(label);

    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }

    // Fallback if label is empty or malformed
    return 0.0;
  }

  void handleMenuClick(taxonomyTermId) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TaxonomyDetailScreen(id: taxonomyTermId, isEnglishUS: (currentLocale == 'EN'), locale: currentLocale, isOffline: isAppOffline, siblings: widget.siblings))
    );
  }

  @override
  Widget build(BuildContext context) {
    var appbar = CustomAppBar(
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
    );
    var left_drawer = LeftNavDrawer(
      locale: currentLocale,
      isEnglishUS: (currentLocale == 'EN'),
      isOffline: isAppOffline,
    );
    var settings_drawer = SettingsDrawer(
      locale: currentLocale,
      isEnglishUS: (currentLocale == 'EN'),
      isOffline: isAppOffline,
      onOfflineChange: _onChangeOffline,
      onLocaleChange: _onLocaleChange,
    );
    if (isLoading) {
      return loadingScreen(isEnglishUS: (currentLocale == 'EN'), locale: currentLocale);
    }
    if (contentNodes.isEmpty && childTermContent.isEmpty) {
      return Scaffold(
        appBar: appbar,
        endDrawer: settings_drawer,
        drawer: left_drawer,
        body: SizedBox.shrink(),
      );
    }

    List<Widget> leadingWidgets = [];
    List<Widget> leadingActions = [];

    var rootTermPresent = false;
    var parentTermPresent = false;
    if (rootTerm != null && rootTerm != '0') {
      rootTermPresent = true;
      leadingActions.add(GestureDetector(onTap: () => handleMenuClick(rootTerm),
        //child: Padding(
        //padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: ArrowLabel(
        isFirst: true,
        color: Color.fromRGBO(213, 31, 39, 1),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Text(
            rootLabel,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 23,
              backgroundColor: Color.fromRGBO(255, 0, 0, 1),
              height: 1.3,
            )
          ),
        ),
      //)));
      ));
    }

    if (parentTerm != null && parentTerm != '0') {
      parentTermPresent = true;
      bool isFirst = rootTerm == null ? true : false;
      leadingActions.add(GestureDetector(onTap: () => handleMenuClick(parentTerm),
      //child: Padding(
      //padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ArrowLabel(
        isFirst: isFirst,
        color: Color.fromRGBO(213, 31, 39, 1),
        child: Text(
              parentLabel,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 23,
                backgroundColor: Color.fromRGBO(255, 0, 0, 1),
                height: 1.3,
              )
            ),
          ),
        ));
    }
    if (previousNode != null) {
      leadingActions.add(GestureDetector(onTap: () => handleMenuClick(previousNode),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ArrowLabel(
        color: Color.fromRGBO(213, 31, 39, 1),
        child: Text(
            previousNodeLabel,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 23,
              backgroundColor: Color.fromRGBO(255, 0, 0, 1),
              height: 1.4,
            )
          ),
        ),
      )));
    }

    bool parentKeyFound = false;
    Widget? back;
    widget.siblings.forEach((parentKey, childMap) {
      childMap.forEach((childKey, id) {
        if (childKey == currentTitle) {
          parentKeyFound = true;
        }
        else if (!parentKeyFound) {
          if (!childKey.contains('.') && currentTitle.contains('.')) {
            return;
          }
          if (childKey.contains('.') && !currentTitle.contains('.')) {
            return;
          }
          if ((!currentTitle.contains('L') && !currentTitle.contains('H')) && (childKey.contains('H') || childKey.contains('L'))) {
            return;
          }
          back = GestureDetector(
           onTap: () => handleMenuClick(id),
           child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: ArrowLabel(
              color: Color.fromRGBO(213, 31, 39, 1),
              child: Text(
                  childKey,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 23,
                    backgroundColor: Color.fromRGBO(255, 0, 0, 1),
                    height: 1.3
                  )
                ),
              )
            )
          );
        }
      });
    });

    if (back != null) {
      leadingActions.add(back!);
    }


    if (rootTermPresent && parentTermPresent) {
       leadingWidgets.add(SizedBox(width: 20));
    }
    else if (rootTermPresent || parentTermPresent) {
       leadingWidgets.add(SizedBox(width: 60));
    }
    else if (!rootTermPresent && !parentTermPresent) {
       leadingWidgets.add(SizedBox(width: 70));
    }

    List<Widget> actions = [];
    bool childKeyFound = false;
    widget.siblings.forEach((parentKey, childMap) {
      childMap.forEach((childKey, id) {
        if (childKeyFound) {
          if (!childKey.contains('.') && currentTitle.contains('.')) {
            return;
          }
          if (childKey.contains('.') && !currentTitle.contains('.')) {
            return;
          }
          actions.add(GestureDetector(
            onTap: () => handleMenuClick(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child:
              ArrowLabel(
                arrowDirection: TagArrowDirection.right,
                color: Color.fromRGBO(213, 31, 39, 1),
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Text(
                    childKey,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                      backgroundColor: Color.fromRGBO(255, 0, 0, 1),
                      height: 1.3,
                    )
                  ),
                )
             )
          ));
          childKeyFound = false;
        }
        else if (childKey == currentTitle) {
          childKeyFound = true;
        }
      });
    });

    if (childTerm.isNotEmpty) {
      actions.add(GestureDetector(
        onTap: () => handleMenuClick(childTerm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child:
          ArrowLabel(
            arrowDirection: TagArrowDirection.right,
            color: Color.fromRGBO(208, 0, 0, 1),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Text(
                childLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                  backgroundColor: Color.fromRGBO(255, 0, 0, 1),
                  height: 1.3,
                )
              ),
            )
         )
      ));
    }

    //actions.add(IconButton(onPressed: menu.openEndDrawer, icon: Icon(Icons.menu)));
    if (userNotes.isNotEmpty) {
      List<Widget> tiles= [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text('Saved Notes'),
        ),
      ];
      for (var userNote in userNotes) {
        tiles.add(Material(
          child: ListTile(
            title: Text(userNote['note']),
            onTap: () {
              SelectWordSelectionEvent(globalPosition: (userNote['start_position']));
              FlutterPlatformAlert.showAlert(
                windowTitle: 'Saved Note',
                text: (userNote['note']),
              );
            }
          )
        ));
      }
      tiles.add(Material(
        child: ListTile(
          title: Text('Close Drawer'),
          onTap: () {
            Navigator.pop(context);

          },
        )
      ));
      var drawer = Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
            children: tiles,
        )
      );
    }
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[200],
      appBar: appbar,
      endDrawer: settings_drawer,
      drawer: left_drawer,
      body: SingleChildScrollView(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
          children: [
            Container(
              color: Color.fromRGBO(86, 86, 86, 1),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min, // important: don't take extra space
                        children: leadingActions.map((widget) => Padding(
                          padding: const EdgeInsets.only(right: 0.0), // small gap
                          child: widget,
                        )).toList(),
                      ),
                      // LEFT: leadingWidgets (tight arrows)
                      Row(
                        mainAxisSize: MainAxisSize.min, // tight spacing
                        children: leadingWidgets.map((widget) => Padding(
                          padding: const EdgeInsets.only(right: 4.0), // spacing between arrows
                          child: widget,
                        )).toList(),
                      ),

                      // MIDDLE: flexible space (optional)
                      Expanded(child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(right: 100.0),
                        child: Text(
                          'ACL $currentTitle',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )),
                      // Right: action widgets
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions.map((widget) => Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: widget,
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                color: Colors.white,
                child: Table(
                  columnWidths: {0: FlexColumnWidth()},
                  children: [
                    if (isSubPage(originalTitle)) ...[
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 0.2),
                        ),
                        children: [
                        Padding(
                         padding: const EdgeInsets.all(1.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                              label: Text(
                                'ACL ' + originalTitle.substring(0, 3) + (contentNodes.isNotEmpty ? ': ' + (contentNodes[0]['label'] ?? '') : ''),
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: const Color.fromARGB(255, 255, 17, 0),
                                ),
                              ), style: TextButton.styleFrom(padding: EdgeInsets.zero, iconColor: const Color.fromARGB(255, 255, 17, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap)
                            ),
                          )),
                        ],
                      ),
                    ],
                    if (!isSubPage(originalTitle)) ...[
                      TableRow(
                        children: [
                        Padding(
                         padding: const EdgeInsets.all(10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              (contentNodes.isNotEmpty ? (contentNodes[0]['label'] ?? '') : ''),
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: const Color.fromARGB(255, 255, 17, 0),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                    if (contentNodes.isNotEmpty) ...[
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 0.2),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SelectableAllenText(
                              text: HtmlParser().parseHtmlString((contentNodes[0]['body'] ?? '')),
                              notes: userNotes,
                              currentNodeId: currentNodeId,
                              isOffline: isAppOffline,
                            )
                          ),
                        ],
                      ),
                    ],
                    ...childTermContent.map((item) {
                      // determines if content should open up in new page or in an accordion
                      bool isNavigable = item['contentType'] == 'P';
                      bool isAccordion = item['contentType'] == 'A';
                      return TableRow(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 0.2),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: isNavigable
                              ? (
                              profiles.isEmpty ?
                              ListTile(
                                contentPadding: EdgeInsets.only(left: 8.0),
                                title: Text(
                                  item['contentLabel'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    size: 16, // optional: iOS-style smaller arrow
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                          // recursively navigates to new detail screen with new id passed in
                                          TaxonomyDetailScreen(
                                            id: item['termId'],
                                            isEnglishUS: (currentLocale == 'EN'),
                                            locale: currentLocale,
                                            isOffline: isAppOffline,
                                            siblings: widget.siblings
                                          ),
                                        ),
                                      );
                                    },
                                  ) :
                                   SizedBox(height: 1)
                                  )
                                : isAccordion
                                  ? ExpansionTile(
                                    tilePadding: EdgeInsets.only(left: 8.0),
                                    title: Text(
                                      item['contentLabel'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                            child: HtmlWidget(HtmlParser().parseHtmlString(
                                              item['body'] ?? '')),
                                          ),
                                        ],
                                      )
                                    : SizedBox.shrink(),
                          ),
                        ],
                      );
                    }).toList(),
                    // displays all mode terms under another accordion
                    if (profiles.isNotEmpty) ...[
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 0.2),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.only(left: 8.0),
                              title: Text(
                                'Profiles',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              children: profiles.map((profile) {
                                return ListTile(
                                  contentPadding: EdgeInsets.only(left: 8.0),
                                  title: Text(profile['termLabel'], style: TextStyle(fontSize: 18)),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    size: 16, // optional: iOS-style smaller arrow
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TaxonomyDetailScreen(
                                          id: profile['termId'],
                                          isEnglishUS: (currentLocale == 'EN'),
                                          locale: currentLocale,
                                          isOffline: isAppOffline,
                                          siblings: widget.siblings
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (modes.isNotEmpty) ...[
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 0.2),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.only(left: 8.0),
                              title: Text(
                                'Modes',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              children: modes.map((mode) {
                                return ListTile(
                                  contentPadding: EdgeInsets.only(left: 8.0),
                                  title: Text(mode['termLabel'], style: TextStyle(fontSize: 18)),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    size: 16, // optional: iOS-style smaller arrow
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TaxonomyDetailScreen(
                                          id: mode['termId'],
                                          isEnglishUS: (currentLocale == 'EN'),
                                          locale: currentLocale,
                                          isOffline: isAppOffline,
                                          siblings: widget.siblings
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ),
            AllenAppFooter(
              locale: currentLocale,
              isEnglishUS: (currentLocale == 'EN'),
            ),
          ],
        )],
      )),
    );
  }
}
