import 'AppAccessBlocked.dart';

import 'home.dart';
import 'package:flutter/material.dart';
import 'language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/auth.dart';
import '../services/query.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'loginForm.dart';
import 'loadingScreen.dart';
import '../services/Offline.dart';

class FormData {
  String? username;
  String? password;
  FormData({this.username, this.password});
}

class LoginPage extends StatefulWidget {
  final bool authenticated;
  final bool forceLogin;

  const LoginPage({super.key, required this.title, required this.authenticated, this.forceLogin = false});

  final String title;

  @override
  State<LoginPage> createState() => _loginPageState();
}

class _loginPageState extends State<LoginPage> {
  String pin_code = '';
  bool loading = true;
  bool isAuthenticated = false;
  String locale = '';
  FormData formData = FormData();

  void initState() {
    super.initState();
    setState(() {
      isAuthenticated = widget.authenticated;
    });
    getLocale();
    getPinCode();
  }

  Future<void> getLocale() async {
    String storedLocale = await getLangaugeCode() ?? '';
    setState(() {
      locale = storedLocale;
    });
  }

  Future<void> _authenticate(BuildContext context, bool forceLogin) async {
    // Capture navigator reference FIRST, before any async operations
    final navigator = Navigator.of(context);

    int expiryTime = await getExpiry() ?? 0;
    var now = DateTime.now().millisecondsSinceEpoch;
    var isOffline = await getOfflineStatus() ?? false;
    var languageCode = await getLangaugeCode() ?? '';
    var database = db;

    if (!isOffline) {
      String? token = await getToken();

      if (token == null || token == '' || forceLogin) {
        if ((formData.username ?? '').isEmpty) {
          navigator.push(
            MaterialPageRoute(builder: (context) => LoginPage(title: 'Allen App', authenticated: true, forceLogin: true))
          );
          return;
        }
        var accessToken = await authenticateUser(formData.username, formData.password);
        if (accessToken == null || accessToken.isEmpty) {
          final snackBar = SnackBar(
            backgroundColor: Color.fromRGBO(213, 31, 39, 1),
            content: Row(
              children: [
                const Icon(Icons.error_outline_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Login Failed, please check your username and password and try again.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Helvetica, sans-serif',
                    ),
                  ),
                ),
              ],
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          return;
        }
        if (accessToken.isNotEmpty) {
          await saveToken(accessToken['access_token'] ?? '', 'access_token');
          await saveToken(accessToken['refresh_token'] ?? '', 'refresh_token');
          await saveToken(accessToken['expires_in'] ?? '', 'expires_in');
          token = accessToken['access_token'] ?? '';
          final GraphQLClient graphQLClient = client.value;
          var getCurrentUser = await graphQLClient.query(
              QueryOptions(document: gql(getLoggedInUser))
          );
          await saveToken(
              getCurrentUser.data?['currentUser']['id'] ?? '0', 'user_id');
          if (database == null || !database.isOpen) {
            await initDatabase(false);
          }
          else {
            await Offline().getSourceData(database, false);
          }
        }
      }
      else if (now >= expiryTime) {
        token = await getNewToken();
      }
      await setLastPinCodeRequest();

      // Consolidated online navigation logic
      if (pin_code.isEmpty) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => LoginPage(
              title: 'Allen App',
              authenticated: true,
              forceLogin: forceLogin,
            ),
          ),
        );
        return;
      }
      else if (languageCode.isNotEmpty) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => HomePage(
              isEnglishUS: (languageCode == 'EN'),
              locale: languageCode,
              isOffline: isOffline,
            ),
          ),
        );
        return;
      }
      else {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => LanguageSelectionPage(isOffline: isOffline),
          ),
        );
        return;
      }
    }
    else {
      // Offline mode logic
      int offlineDate = await getOfflineDate();
      var originalDateObject = DateTime.fromMillisecondsSinceEpoch(offlineDate);
      var expiryDate = originalDateObject.add(const Duration(days: 7));

      if (pin_code.isEmpty) {
        navigator.push(
          MaterialPageRoute(builder: (context) => LoginPage(title: 'Allen App', authenticated: true)),
        );
        return;
      }

      if (now >= expiryDate.millisecondsSinceEpoch) {
        await setLastPinCodeRequest();
        navigator.push(
          MaterialPageRoute(builder: (context) => AppAccessBlocked(locale: languageCode)),
        );
        return;
      }

      if (database == null || !database.isOpen) {
        await initDatabase(false);
      }
      else {
        await Offline().getSourceData(database, false);
      }
      await setLastPinCodeRequest();

      if (languageCode.isNotEmpty) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => HomePage(
              isEnglishUS: (languageCode == 'EN'),
              locale: languageCode,
              isOffline: isOffline,
            ),
          ),
        );
        return;
      }
      else {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => LanguageSelectionPage(isOffline: isOffline),
          ),
        );
        return;
      }
    }
  }

  Future<void> getPinCode() async {
    var storedPinCode = await getLoginCode() ?? '';
    setState((){
      pin_code = storedPinCode;
      isAuthenticated = (!isAuthenticated ? storedPinCode.isNotEmpty : isAuthenticated);
      loading = false;
    });
  }

  Future<void> savePinCode(code, context) async {
    setState(() {
      pin_code = code;
    });
    await storePinCode(code).then((result) {
      _authenticate(context, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final arguments = (ModalRoute.of(context)?.settings.arguments ?? <String, dynamic>{}) as Map;
    if (loading) {
      return loadingScreen(isEnglishUS: (pin_code.isEmpty ? true : (locale == 'EN')), locale: (pin_code.isEmpty ? 'EN' : locale));
    }
    if (!isAuthenticated || widget.forceLogin || (arguments['forceLogin'] ?? false)) {
      bool isEnglishUS = true;
      if (pin_code.isEmpty) {
        setState(() {
          locale = 'EN';
        });
      }
      else {
        isEnglishUS = (locale == 'EN');
      }
      return LoginForm(formData: formData, submitFunction: _authenticate, isEnglishUS: isEnglishUS, locale: locale);
    }
    else if (pin_code.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Image(image: AssetImage("images/Allen_App_title.png"), height: 50),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero
                  ),
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(40, 40),
                ),
                child: Text('Create Passcode'),
                onPressed: () => {
                  screenLockCreate(
                    context: context,
                    onConfirmed: (value) => savePinCode(value, context),
                  )
                }
              )
            ],
          ),
        )
      );
    }
    else {
      return Scaffold(
        appBar: AppBar(
          title: Image(image: AssetImage("images/Allen_App_title.png"), height: 50),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero
                  ),
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(40, 40),
                ),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) {
                    return ScreenLock(
                      correctString: pin_code,
                      onCancelled: Navigator.of(context).pop,
                      onUnlocked: () {
                        Navigator.of(context).pop();
                        _authenticate(context, false);
                      },
                    );
                  },
                ),
                child: const Text('Please Login',
                  style: TextStyle(fontFamily: 'helvetica,sans-serif',
                    color: Colors.white,
                    fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}