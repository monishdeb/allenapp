import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/login.dart';
import 'query.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'auth.dart';

class AllenAppLifeCycleDisplay extends StatefulWidget {
  const AllenAppLifeCycleDisplay({super.key});

  @override
  State<AllenAppLifeCycleDisplay> createState() => _AllenAppLifeCycleDisplayState();
}

class _AllenAppLifeCycleDisplayState extends State<AllenAppLifeCycleDisplay> {
  late final AppLifecycleListener _listener;
  late AppLifecycleState? _state;
  int now = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _state = SchedulerBinding.instance.lifecycleState;
    _listener = AppLifecycleListener(
      onResume: () => {
        checkToNavigateToHome()
      },
      onInactive: () => {
        checkToNavigateToHome()
      },
      onRestart: () => {
        checkToNavigateToHome()
      }
    );
  }

  void checkToNavigateToHome() async {
    int? last_pin_request = await getLastPinCodeRequest();
    if (!kIsWeb && (Platform.isAndroid || Platform.isLinux)) {
      navigatorKey.currentState?.pushNamed('/', arguments: {'forceLogin': false});
    }
    else if (kIsWeb) {
      if (last_pin_request <= now) {
        navigatorKey.currentState?.pushNamed(
            '/', arguments: {'forceLogin': false});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
          title: 'Allen App',
          theme: ThemeData(
            primaryColor: Colors.white,
            scaffoldBackgroundColor: Colors.white,

            // GLOBAL APP BAR SETTINGS
            appBarTheme: AppBarTheme(
              backgroundColor: Color.fromRGBO(213, 31, 39, 1),
              centerTitle: true,
              iconTheme: const IconThemeData(
                color: Colors.white,
              ),
              titleTextStyle: const TextStyle(
                fontFamily: 'helvetica,sans-serif',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: Color.fromRGBO(213, 31, 39, 1),
            ),
          ),
          navigatorKey: navigatorKey,
          routes: {
            '/': (context) => LoginPage(title: 'Allen app', authenticated: false),
          }
      ),
    );
  }
}
