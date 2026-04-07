import 'package:flutter/material.dart';
import '../services/auth.dart';
import 'home.dart';
import 'language.dart';

class AppAccessBlocked extends StatelessWidget {
  String locale;
  AppAccessBlocked({required this.locale});

  void _setAppOnline() {
    setOfflineDate(0);
    setOfflineStatus(false, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Image(image: AssetImage("images/Allen_App_title.png"), height: 50)),
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Text('This application has been disabled as it has been more than 7 days since it was online, please change it to be online to restore access'),
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
                  _setAppOnline();
                  if (locale.isNotEmpty) {
                    bool isEnglishUS = (locale == 'EN_US');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              HomePage(isEnglishUS: isEnglishUS,
                                  locale: locale ?? 'EN_US',
                                  isOffline: false)
                      ),
                    );
                  }
                  else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LanguageSelectionPage(isOffline: false))
                    );
                  }
                },
                child: const Text('Next',
                  style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)
                ),
              )
            )
          ],
        )
      ),
    );
  }
}