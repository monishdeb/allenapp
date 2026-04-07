import 'package:flutter/material.dart';
import 'services/AllenAppLifeCycleDisplay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AllenApp());
}

class AllenApp extends StatelessWidget {
  const AllenApp({Key? key, this.loginCode}) : super(key: key);
  final String? loginCode;
  @override
  Widget build(BuildContext context) {
    return AllenAppLifeCycleDisplay();
  }
}
