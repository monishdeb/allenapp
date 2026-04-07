import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import 'searchresults.dart';
import '../services/Offline.dart';
import '../services/auth.dart';

// search bar component
class CustomSearchBar extends StatefulWidget {
  final bool isEnglishUS;
  final String locale;
  final bool isOffline;

  CustomSearchBar({required this.isEnglishUS, required this.locale, required this.isOffline});

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];

  // implements custom search function because search api not compatible with graphql 4.x
  void search() async {
    String searchTerm = _controller.text.trim();
    if (searchTerm.isEmpty) {
      print("Search term is empty. No results.");
      return;
    }

    searchResults.clear();

    if (widget.isOffline) {
      List result = await Offline().search(db, widget.locale, searchTerm) ?? [];
      setState(() {
        searchResults = result.map((item) {
          return {
            'label': item['title'],
            'id': item['taxonomy_id'].toString() ?? '',
            'node_type': item['node_type'],
            'node_id': item['id'].toString() ?? '',
            'body': item['body'],
          };
        }).toList();
      });
    } else {
      final QueryResult result = await client.value.query(
        QueryOptions(
          document: gql(getSearchResults),
          variables: {'searchTerm': searchTerm, 'langcode': widget.locale},
        ),
      );

      if (!result.hasException) {
        List<dynamic> items = result.data?['entityQuery']['items'] ?? [];
        setState(() {
          searchResults = items.map((item) {
            final fallbackLabel = item['label'] ?? 'No Label';
            String translatedTitle = item['translation']?['titleRawField']
            ?['getString'] ??
                fallbackLabel;

            return {
              'label': translatedTitle,
              'id': item.containsKey('fieldAllenCognitiveLevelRawField')
                  ? item['fieldAllenCognitiveLevelRawField']['getString']
                  : item.containsKey('fieldConceptualFrameworkRawField')
                  ? item['fieldConceptualFrameworkRawField']['getString']
                  : 'No data',
              'node_type': item['entityBundle'],
              'node_id': item['id'],
              'body': item['translation']?['bodyRawField']['getString'] ?? '',
            };
          }).toList();
        });
      }
      else {
        print('Error: ${result.exception.toString()}');
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
          SearchResultsScreen(
            searchResults: searchResults,
            isEnglishUS: widget.isEnglishUS,
            locale: widget.locale,
            isOffline: widget.isOffline,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: search,
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
