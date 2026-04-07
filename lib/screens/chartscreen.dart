import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import '../models/terms.dart';
import 'detailscreen.dart';
import '../models/menu.dart';
import '../models/custom_appbar.dart';
import '../models/footer.dart';
import 'package:footer/footer_view.dart';
import '../services/auth.dart';
import '../services/Offline.dart';
import 'loadingScreen.dart';

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
  void navigateToDetail(BuildContext context, Term term) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TaxonomyDetailScreen(id: term.id, isEnglishUS: widget.isEnglishUS, locale: widget.locale, isOffline: isAppOffline),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var menu = Menu(scaffoldKey: _scaffoldKey, locale: widget.locale, isEnglishUS: widget.isEnglishUS, isOffline: isAppOffline, onOfflineChange: _onChangeOffline);
    if (isLoading) {
      return loadingScreen();
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
      endDrawer: menu,
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
              'Allen Cognitive Levels',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 550,
            child: Column(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        // iterates through parent terms and displays them in one table with 6 rows on the left side
                        children: List.generate(
                          6,
                          (index) {
                            if (count1 < parentTerms.length) {
                              Term term = parentTerms[count1];
                              count1++;
                              return Table(
                                border: TableBorder.all(),
                                columnWidths: {
                                  0: FlexColumnWidth(),
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      GestureDetector(
                                        onTap: () => navigateToDetail(context, term),
                                        child: Container(
                                          height: 64.0,
                                          alignment: Alignment.center,
                                          color: Color(int.parse(
                                            '0xFF${term.colour.substring(1)}')),
                                          child: Text(
                                            term.label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                         ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              return SizedBox();
                            }
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: List.generate(
                          // displays 11 tables on the right side, alternating between displaying child terms and mode terms
                          11,
                          (index) {
                            // makes sure the last table is displayed differently from the others
                            if (index == 10) {
                              Term term = (count2 < childTerms.length)
                                ? childTerms[count2++]
                                : Term(id: '', label: 'N/A', colour: '#FFFFFF');
                              return Table(
                                border: TableBorder.all(),
                                columnWidths: {0: FlexColumnWidth()},
                                children: [
                                  TableRow(
                                    children: [
                                      GestureDetector(
                                        onTap: () => navigateToDetail(context, term),
                                        child: Container(
                                          height: 64.0,
                                          alignment: Alignment.center,
                                          color: Color(int.parse(
                                            '0xFF${term.colour.substring(1)}')),
                                          child: Text(
                                            term.label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            // table display for the other terms on the right side
                            // uses current index to determine if the table being generated is for child terms or mode terms (2 cols or 5 cols)
                            List<Widget> columns = [];
                            for (int colIndex = 0;
                              colIndex < (index % 2 == 0 ? 2 : 5);
                              colIndex++) {
                              Term term;
                              if (index % 2 == 0) {
                                if (count2 < childTerms.length) {
                                  term = childTerms[count2];
                                  count2++;
                                } else {
                                  term = childTerms.last;
                                }
                              } else {
                                if (count3 < modeTerms.length) {
                                  term = modeTerms[count3];
                                  count3++;
                                } else {
                                  term = modeTerms.last;
                                }
                              }
                              columns.add(
                                GestureDetector(
                                  onTap: () => navigateToDetail(context, term),
                                  child: Container(
                                    height: 32.0,
                                    alignment: Alignment.center,
                                    color: Color(int.parse(
                                       '0xFF${term.colour.substring(1)}')),
                                    child: Text(
                                      term.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Table(
                              border: TableBorder.all(),
                              columnWidths: Map.fromIterable(
                                List.generate(
                                  index % 2 == 0 ? 2 : 5, (index) => index),
                                key: (index) => index,
                                value: (index) => FlexColumnWidth(),
                              ),
                              children: [
                                TableRow(children: columns),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]))
      ]),
    );
  }
}
