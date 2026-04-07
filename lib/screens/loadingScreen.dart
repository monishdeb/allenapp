import 'package:flutter/material.dart';
import '../models/footer.dart';

class loadingScreen extends StatelessWidget {
  final bool isEnglishUS;
  final String locale;

  const loadingScreen(
  {Key? key, required this.isEnglishUS, required this.locale});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Image(image: AssetImage("images/Allen_App_title.png"), height: 50),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
           height: 600,
           child:Container(
              color: Colors.white,
              child: Center(child: CircularProgressIndicator()),
            )
          ),
          AllenAppFooter(
            locale: locale,
            isEnglishUS: isEnglishUS,
          ),
        ]
      )
    );
  }
}
