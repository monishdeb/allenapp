import 'package:flutter/material.dart';

class loadingScreen extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Allen App',
          style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}