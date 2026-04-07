import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import '../services/query.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'home.dart';
import '../models/footer.dart';
import 'package:footer/footer_view.dart';
import '../services/auth.dart';

// screen renders when app is first started
class LanguageSelectionPage extends StatefulWidget {
  final String? selectedLanguage;
  final bool isOffline;
  const LanguageSelectionPage({Key? key, this.selectedLanguage, required this.isOffline}): super(key: key);
  @override
  _LanguageSelectionPageState createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  bool isLoading = true;
  List appLanguages = [];
  String? _selectedLanguage;

  Future saveLanguage(language) async {
    await storeLangaugeCode(language);
  }

  Future getLocales() async {
    var locales = [];
    var standard_locales = [
      {
        'id': 'en',
        'label': 'English (UK)',
        'langcode': 'EN',
      },
      {
        'id': 'en_us',
        'label': 'English (US)',
        'langcode': 'EN_US',
      },
    ];
    final GraphQLClient graphQLClient = client.value;
    var languages = await graphQLClient.query(
      QueryOptions(document: gql(getLanguages)));
    if (languages.hasException) {
      print(languages.exception.toString());
      //await FlutterPlatformAlert.showAlert(windowTitle: "GraphQL Error", text: languages.exception.toString());
    }
    for (var locale in languages.data?['entityQuery']['items'] ?? standard_locales) {
      if (locale['id'] != "und" && locale['id'] != "zxx") {
        var term = {
          'langcode': locale['langcode'].toUpperCase().replaceAll('-', '_'),
          'label': locale['label']
        };
        locales.add(term);
      }
    }
    setState(() {
      isLoading = false;
      appLanguages = locales;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedLanguage == null || _selectedLanguage == '') {
      _selectedLanguage = widget.selectedLanguage ?? 'EN_US';
    }
    if (isLoading) {
      getLocales();
      return Scaffold(
        appBar: AppBar(title: Text('Allen App')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    List<TableRow> LanguageWidgets = [];
     LanguageWidgets.add(TableRow(children: [
         Padding(
           padding: const EdgeInsets.all(8.0),
           child: Text(
             'Welcome to the Allen App. Here you will find all of my (Claudia Kay Allen) latest publications on the Allen Cognitive Disability Model.',
             style: TextStyle(fontSize: 16),
           ),
         ),
     ]));
     LanguageWidgets.add(TableRow(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                'Languages',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700]),
            ),
          ),
      ]));
    if (appLanguages.isNotEmpty) {
      for (var appLanguage in appLanguages) {
        var iconcode = (appLanguage['langcode'] == 'EN_US' ? 'us' : 'gb');
        var subtext = (appLanguage['langcode'] == 'EN_US' ? ' - imperial units' : ' - metric units');
        LanguageWidgets.add(
            TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: RadioListTile<String>(
                      activeColor: Colors.red,
                      title: Row(
                        children: <Widget>[
                            Image.asset('icons/flags/png100px/' + iconcode + '.png', package: 'country_icons', height: 20),
                            SizedBox(width: 10),
                            Text(
                                appLanguage['label'] + subtext,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 5,
                                style: TextStyle(color: Colors.black, fontSize: 16.0),
                            ),
                          ],
                      ),
                      value: appLanguage['langcode'].toString(),
                      groupValue: _selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          _selectedLanguage = value.toString();
                        });
                      },
                   )
                  ),
                ]
              )
            );
      }
    }
    LanguageWidgets.add(TableRow(children: [
     Padding(
       padding: const EdgeInsets.all(8.0),
       child: Text(
         'Ensure that you have selected correct language before continuing.',
         style: TextStyle(fontSize: 16),
       ),
     ),
    ]));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Allen App',
           style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true
      ),
      body: FooterView(
        footer: AllenAppFooter(locale: _selectedLanguage ?? 'EN_US', isEnglishUS: (_selectedLanguage == 'EN_US')),
        flex: 1,
        children:<Widget>[
          Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  child: Table(
                    columnWidths: const {0: FlexColumnWidth(),},
                    children: LanguageWidgets
                  )
                ),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero
                      ),
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(40, 40), //////// HERE
                    ),
                    onPressed: () {
                      bool isEnglishUS = _selectedLanguage == 'EN_US';
                      saveLanguage(_selectedLanguage);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                           builder: (context) => HomePage(isEnglishUS: isEnglishUS, locale: _selectedLanguage ?? 'EN_US', isOffline: widget.isOffline)
                        ),
                      );
                    },
                    child: const Text('Next',
                      style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  )
                )
              ]
            ),
          ),
        ],
      )
    );
  }
}
