import '../models/footer.dart';
import 'package:flutter/material.dart';
import 'package:footer/footer_view.dart';
import 'detailscreen.dart';
import 'cf.dart';
import 'aclsdetails.dart';
import '../services/notes.dart';

// displays the results of search and allows user to press one of the results
class SearchResultsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;

  SearchResultsScreen({required this.searchResults, required this.isEnglishUS, required this.locale, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Allen App'
        )
      ),
      body: FooterView(footer: AllenAppFooter(locale: locale, isEnglishUS: isEnglishUS),
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
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final result = searchResults[index];
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
                              isEnglishUS: isEnglishUS,
                              locale: locale,
                              isOffline: isOffline,
                            ),
                      ),
                    );
                  }
                  else if (result['node_type'] == 'conceptual_framework') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ConceptualFrameworksScreen(isEnglishUS: isEnglishUS, locale: locale, isOffline: isOffline))
                    );
                  }
                  else if (result['node_type'] == 'acls_6_activities') {
                    fetchTargetData(context, result['id'], locale, isOffline);
                  }
                  else if (result['node_type'] == 'acls6') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AclsDetailsScreen(
                            termId: result['id'],
                            body: result['body'],
                            nodeId: result['node_id'],
                            locale: locale,
                            label: result['label'],
                            isEnglishUS: isEnglishUS,
                            isOffline: isOffline
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
