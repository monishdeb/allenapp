import '../models/footer.dart';
import 'package:flutter/material.dart';
import 'package:footer/footer_view.dart';
import 'detailscreen.dart';
import 'cf.dart';
import 'aclsdetails.dart';
import '../services/notes.dart';
import '../widgets/custom_app_bar.dart';
import '../models/left_drawer.dart';
import '../services/auth.dart';

// displays the results of search and allows user to press one of the results
class SearchResultsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> searchResults;
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;

  SearchResultsScreen({required this.searchResults, required this.isEnglishUS, required this.locale, required this.isOffline});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late bool isAppOffline;

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
      drawer: LeftNavDrawer(
        locale: widget.locale,
        isEnglishUS: widget.isEnglishUS,
        isOffline: isAppOffline,
      ),
      body: FooterView(footer: AllenAppFooter(locale: widget.locale, isEnglishUS: widget.isEnglishUS),
      children: [
        Container(
          color: Colors.grey[800],
          padding: EdgeInsets.symmetric(horizontal: 16),
          height: 56, // Same as AppBar height
          alignment: Alignment.center,
          child: Text(
            'Search Results',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          physics: ScrollPhysics(),
          itemCount: widget.searchResults.length,
          itemBuilder: (context, index) {
            final result = widget.searchResults[index];
            return Container(
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(result['label']),
                leading: Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 15.0,
                ),
                onTap: () {
                  if (result['node_type'] == 'web_app') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TaxonomyDetailScreen(
                              id: result['id'],
                              isEnglishUS: widget.isEnglishUS,
                              locale: widget.locale,
                              isOffline: isAppOffline,
                            ),
                      ),
                    );
                  }
                  else if (result['node_type'] == 'conceptual_framework') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ConceptualFrameworksScreen(isEnglishUS: widget.isEnglishUS, locale: widget.locale, isOffline: isAppOffline))
                    );
                  }
                  else if (result['node_type'] == 'acls_6_activities') {
                    fetchTargetData(context, result['id'], widget.locale, isAppOffline);
                  }
                  else if (result['node_type'] == 'acls6') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AclsDetailsScreen(
                            termId: result['id'],
                            body: result['body'],
                            nodeId: result['node_id'],
                            locale: widget.locale,
                            label: result['label'],
                            isEnglishUS: widget.isEnglishUS,
                            isOffline: isAppOffline
                        ))
                    );
                  }
                },
              ),
            );
          },
        ),
      )]),
    );
  }
}
