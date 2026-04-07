import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'services/query.dart';
import 'services/auth.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AllenApp());
}

class AllenApp extends StatelessWidget {
  const AllenApp({Key? key, this.loginCode}) : super(key: key);
  final String? loginCode;
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'Allen App',
        theme: ThemeData(
          primaryColor: Colors.white,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(backgroundColor: Colors.red[700]),
        ),
        routes: {
          '/': (context) => LoginPage(title: 'Allen app', authenticated: false),
        }
      ),
    );
  }
}
