/* Menu is a drawer that is used to be shared across all screens and is a "end drawer"
 */
import 'package:flutter/material.dart';
import '../screens/language.dart';
import '../screens/search.dart';
import '../screens/Notes.dart';

class Menu extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String locale;
  final bool isEnglishUS;
  final bool isOffline;
  final void Function(bool?) onOfflineChange;

  const Menu({required this.scaffoldKey, required this.locale, required this.isEnglishUS, required this.isOffline, required this.onOfflineChange});

  void openEndDrawer() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  void _closeEndDrawer(context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    bool isAppOffline = isOffline;
    return Drawer(
    child: Container(
      color: Colors.white,
      child: ListView(
        children: [
          Column(
            children: [
              CustomSearchBar(
                isEnglishUS: isEnglishUS,
                locale: locale,
                isOffline: isAppOffline,
              ),
              SizedBox(height: 40),
              Text('Allen App Settings'),
              SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotesPage(locale: locale, isOffline: isAppOffline,),
                  )
                ),
                child: Row(children: [
                  SizedBox(width: 20),
                  Text('Saved Notes', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  Icon(
                    Icons.notes,
                    size: 20.0,
                  ),
                ])
              ),
              SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LanguageSelectionPage(selectedLanguage: locale, isOffline: isAppOffline),
                  )
                ),
                child: Row(children: [
                  SizedBox(width: 20),
                  Text('Change Language', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_ios_outlined,
                    size: 20.0,
                  ),
                ])
              ),
              SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CheckboxListTile(
                    value: isAppOffline,
                    title: Text('Is App in Offline Mode?'),
                    onChanged: (bool? value) async {
                      onOfflineChange(value);
                      _closeEndDrawer(context);
                    }
                  )
              ),
              SizedBox(height: 20),
              Text('App Version: 1.0.0'),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero
                  ),
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(40, 40), //////// HERE
                ),
                onPressed: () => {_closeEndDrawer(context)},
                child: Text('Close Menu',
                  style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)
                )
              )
            ],
          )
        ],
      )
    )
    );
  }
}