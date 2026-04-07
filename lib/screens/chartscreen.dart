import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import '../models/terms.dart';
import 'detailscreen.dart';
import '../models/menu.dart';
import '../models/footer.dart';
import 'package:footer/footer_view.dart';
import '../services/auth.dart';
import '../services/Offline.dart';
import 'loadingScreen.dart';
import 'home.dart';

// screen that renders when user selected Allen Cognitive Levels
class TaxonomyHierarchyScreen extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;

  TaxonomyHierarchyScreen({required this.isEnglishUS, required this.locale, required this.isOffline});

  @override
  _TaxonomyHierarchyScreenState createState() =>
      _TaxonomyHierarchyScreenState();
}

List<Term> parentTerms = [];
List<Term> childTerms = [];
List<Term> modeTerms = [];

class _TaxonomyHierarchyScreenState extends State<TaxonomyHierarchyScreen> {
  bool isLoading = true;
  bool isAppOffline = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // counters to keep track of index when displaying taxonomy terms
  int count1 = 0;
  int count2 = 0;
  int count3 = 0;
  final Map<String, Map<String, String>> siblings = {};

  @override
  void initState() {
    super.initState();
    isLoading = true;
    isAppOffline = widget.isOffline;
    fetchParentTerms();
  }

  // queries for parent allen cognitive level taxonomy terms
  Future<void> fetchParentTerms() async {
    parentTerms = [];
    if (isAppOffline) {
      var database = db;
      final parentResult = await Offline().getRootTaxonomy(database, 'allen_cognitive_levels');
      parentTerms = List<Term>.from((parentResult ?? []).map((item) => Term.fromMap(item, isAppOffline)));
    }
    else {
      final GraphQLClient graphQLClient = client.value;

      final parentResult = await graphQLClient.query(
        QueryOptions(document: gql(getParentTerms)),
      );
      if (parentResult.hasException) {
        print(
            "Error fetching parent terms: ${parentResult.exception
                .toString()}");
        print(
            "GraphQL Error Details: ${parentResult.exception?.graphqlErrors}");
        return;
      }

      parentTerms = List<Term>.from(
          (parentResult.data?['entityQuery']['items'] ?? [])
              .map((item) => Term.fromMap(item, isAppOffline)));
    }
    List<String> parentIds = parentTerms
        .map((t) => t.id)
        .toList(); // adds the ids of the parent terms into list

    await fetchChildTerms(parentIds);
  }

  // queries for child terms given the parent term ids from above function
  Future<void> fetchChildTerms(List<String> parentIds) async {
    List items = [];
    if (parentIds.isEmpty) return;
    if (isAppOffline) {
      var database = db;
      for (var parentId in parentIds) {
        var parentResult = await Offline().getACLTaxonomy(parentId, null, database);
        items = items + parentResult;
      }
    }
    else {
      final GraphQLClient graphQLClient = client.value;
      final childResult = await graphQLClient.query(
        QueryOptions(
            document: gql(getChildTerms), variables: {'parentIds': parentIds}),
      );
      items = childResult.data?['entityQuery']['items'] ?? [];
    }
    List<Term> fetchedChildTerms = [];

    RegExp regExp = RegExp(r'^(\d+)\s([LH])$');

    for (var item in items) {
      Term term = Term.fromMap(item, isAppOffline);
      // only adds terms that are in the form of a number followed by L or H
      // excludes modes
      if (regExp.hasMatch(term.label)) {
        fetchedChildTerms.add(term);
      }
    }
    // sorts them by number and then L, H for display on chart
    fetchedChildTerms.sort((a, b) {
      var matchA = regExp.firstMatch(a.label)!;
      var matchB = regExp.firstMatch(b.label)!;

      int numA = int.parse(matchA.group(1)!);
      int numB = int.parse(matchB.group(1)!);
      String letterA = matchA.group(2)!;
      String letterB = matchB.group(2)!;

      if (numA == numB) {
        return (letterA == 'L' ? -1 : 1) - (letterB == 'L' ? -1 : 1);
      }
      return numA.compareTo(numB);
    });

    setState(() {
      childTerms = fetchedChildTerms;
    });

    List<String> childIds =
        childTerms.map((t) => t.id).toList(); // stores child term ids in list
    await fetchModeTerms(childIds);
  }

  // fetches mode terms given child term ids from above function
  Future<void> fetchModeTerms(List<String> childIds) async {
    List items = [];
    final GraphQLClient graphQLClient = client.value;
    var database = db;
    if (childIds.isEmpty) return;
    if (isAppOffline) {
      for (var childId in childIds) {
        var modeResult = await Offline().getACLTaxonomy(childId, null, database);
        items = items + modeResult;
      }
    }
    else {
      final modeResult = await graphQLClient.query(
        QueryOptions(
            document: gql(getChildTerms), variables: {'parentIds': childIds}),
      );
      items = modeResult.data?['entityQuery']['items'] ?? [];
    }
    List<Term> fetchedModeTerms = [];

    for (var item in items) {
      Term term = Term.fromMap(item, isAppOffline);

      // gets the umbrella terms that all the modes are under (e.g. 5 L M --> 5 L M 5.0)
      // once it finds the umbrella terms, queries for the child terms under that to find the actual mode terms
      List childItems = [];
      if (term.label.contains('M')) {
        if (isAppOffline) {
          childItems = await Offline().getACLTaxonomy(term.id, null, database);
        }
        else {
          final childResult = await graphQLClient.query(
            QueryOptions(
              document: gql(getChildTerms),
              variables: {
                'parentIds': [term.id]
              },
            ),
          );
          childItems = childResult.data?['entityQuery']['items'] ?? [];
        }
        for (var childItem in childItems) {
          Term childTerm = Term.fromMap(childItem, isAppOffline);
          childTerm.label = childTerm.label.substring(childTerm.label.length -
              3); // extracts part of the label for display on chart (e.g. 5 L M 5.0 --> 5.0)
          fetchedModeTerms.add(childTerm);
        }
      }
    }

    // sorts the modes in ascending order
    fetchedModeTerms.sort((a, b) => a.label.compareTo(b.label));

    setState(() {
      modeTerms = fetchedModeTerms;
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
    count1 = 0;
    count2 = 0;
    count3 = 0;
    fetchParentTerms();
  }

  // helper function to navigate to detail screen to display details of each taxonomy term when user presses a node on the chart
  void navigateToDetail(BuildContext context, Term term, {Map<String, Map<String, String>>? siblings}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TaxonomyDetailScreen(id: term.id, isEnglishUS: widget.isEnglishUS, locale: widget.locale, isOffline: isAppOffline, siblings: siblings ?? {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var menu = Menu(scaffoldKey: _scaffoldKey, locale: widget.locale, isEnglishUS: widget.isEnglishUS, isOffline: isAppOffline, onOfflineChange: _onChangeOffline);
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoading) {
      return loadingScreen(isEnglishUS: widget.isEnglishUS, locale: widget.locale);
    }
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading:  IconButton(
          icon: Icon(
            Icons.home,
            color: Colors.white.withOpacity(0.85),
            size: 20,
          ),
          onPressed: () => Navigator.push(
            context, MaterialPageRoute(
              builder: (context) => HomePage(isEnglishUS: widget.isEnglishUS, locale: widget.locale, isOffline: isAppOffline)
            )
          )
        ),
        title: Image(image: AssetImage("images/Allen_App_title.png"), height: 50),
        actions: [
          IconButton(onPressed: menu.openEndDrawer, icon: Icon(Icons.menu)),
        ]
      ),
      endDrawer: menu,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title bar
            Container(
                color: Colors.grey[800],
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 56, // Same as AppBar height
                alignment: Alignment.center,
                child: Text(
                  'Allen Cognitive Levels',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Container(
                  color: Colors.white,
                  child: SizedBox(
                    height: 610,
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN — SMALL (1–6)
                            SizedBox(
                              width: 100,
                              child: Column(
                                children: List.generate(6, (index) {
                                  if (count1 < parentTerms.length) {
                                    Term term = parentTerms[count1];
                                    count1++;
                                    return Table(
                                      border: TableBorder.all(),
                                      columnWidths: const {
                                        0: FlexColumnWidth(1),
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            GestureDetector(
                                              onTap: () => navigateToDetail(context, term),
                                              child: Container(
                                                height: 100,
                                                alignment: Alignment.center,
                                                color: Color(
                                                  int.parse('0xFF${term.colour.substring(1)}'),
                                                ),
                                                child: Text(
                                                  term.label,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                }),
                              ),
                            ),
                            // RIGHT COLUMN — WIDE (L / H / Modes)
                            Expanded(
                              child: Column(
                                children: List.generate(11, (index) {
                                  if (index == 10) {
                                    Term term = (count2 < childTerms.length)
                                        ? childTerms[count2++]
                                        : Term(id: '', label: 'N/A', colour: '#FFFFFF');
                                    return Table(
                                      border: TableBorder.all(),
                                      columnWidths: const {0: FlexColumnWidth()},
                                      children: [
                                        TableRow(
                                          children: [
                                            GestureDetector(
                                              onTap: () => navigateToDetail(context, term, siblings: siblings),
                                              child: Container(
                                                height: 100,
                                                alignment: Alignment.center,
                                                color: Color(
                                                  int.parse('0xFF${term.colour.substring(1)}'),
                                                ),
                                                child: Text(
                                                  term.label,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  List<Widget> columns = [];
                                  String? currentKey;
                                  int columnCount = index.isEven ? 2 : 5;

                                  for (int colIndex = 0; colIndex < columnCount; colIndex++) {
                                    Term term;
                                    if (index.isEven) {
                                      // Use childTerms for even index
                                      term = (count2 < childTerms.length) ? childTerms[count2++] : childTerms.last;

                                      // Set current key
                                      currentKey = term.label;

                                      // Safely initialize inner map only if not already present
                                      siblings.putIfAbsent(term.label[0], () => <String, String>{});
                                      siblings[term.label[0]]![term.label] = term.id;
                                      siblings.putIfAbsent(currentKey, () => <String, String>{});
                                    } else {
                                      // Use modeTerms for odd index
                                      term = (count3 < modeTerms.length) ? modeTerms[count3++] : modeTerms.last;

                                      // Safely add to inner map
                                      if (term.label.isNotEmpty) {
                                        String parentLevel;
                                        if (colIndex < 3) {
                                          parentLevel = term.label[0] + ' L';
                                        }
                                        else {
                                          parentLevel = term.label[0] + ' H';
                                        }
                                        // Ensure inner map exists
                                        siblings.putIfAbsent(parentLevel, () => <String, String>{});
                                        siblings[parentLevel]![term.label] = term.id;
                                      }
                                    }

                                    columns.add(
                                      GestureDetector(
                                        onTap: () => navigateToDetail(context, term, siblings: siblings),
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          color: Color(
                                            int.parse('0xFF${term.colour.substring(1)}'),
                                          ),
                                          child: Text(
                                            term.label,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    );
                                  }


                                  return Table(
                                    border: TableBorder.all(),
                                    columnWidths: columnCount == 2
                                        ? const {
                                            0: FlexColumnWidth(3),
                                            1: FlexColumnWidth(2),
                                          }
                                        : {
                                            for (int i = 0; i < columnCount; i++)
                                              i: const FlexColumnWidth(),
                                          },
                                    children: [
                                      TableRow(children: columns),
                                    ],
                                  );
                                }),
                              ),
                            ),

                          ],
                        )
                      )
                    ),
                  )
                )
              ),
              // Footer now scrolls with content (no whitespace EVER)
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
