import 'AppAccessBlocked.dart';

import 'home.dart';
import 'package:flutter/material.dart';
import 'language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/auth.dart';
import '../services/query.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'loginForm.dart';

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
  FormData formData = FormData();

  void initState() {
    super.initState();
    setState(() {
      isAuthenticated = widget.authenticated;
    });
    getPinCode();
  }

  Future<void> _authenticate(BuildContext context) async {
    int expiryTime = await getExpiry() ?? 0;
    var now = DateTime.now().millisecondsSinceEpoch;
    var isOffline = await getOfflineStatus() ?? false;
    var languageCode = await getLangaugeCode() ?? '';
    if (!isOffline) {
      String? token = await getToken();
      if (token == null || token == '') {
        if ((formData.username ?? '').isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage(title: 'Allen App', authenticated: true, forceLogin: true))
          );
        }
        var accessToken = await authenticateUser(formData.username, formData.password);
        if (accessToken != null) {
          await saveToken(accessToken['access_token'] ?? '', 'access_token');
          await saveToken(accessToken['refresh_token'] ?? '', 'refresh_token');
          await saveToken(accessToken['expires_in'] ?? '', 'expires_in');
          token = await getToken();
          final GraphQLClient graphQLClient = client.value;
          var getCurrentUser = await graphQLClient.query(
              QueryOptions(document: gql(getLoggedInUser))
          );
          await saveToken(
              getCurrentUser.data?['currentUser']['id'] ?? '0', 'user_id');
        }
      }
      else if (now >= expiryTime) {
        token = await getNewToken();
      }
    }
    else {
      int offlineDate = await getOfflineDate();
      var originalDateObject = DateTime.fromMillisecondsSinceEpoch(offlineDate);
      var expiryDate = originalDateObject.add(const Duration(days: 7));
      if (pin_code.isEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage(title: 'Allen App', authenticated: true))
        );
      }
      if (now >= expiryDate.millisecondsSinceEpoch) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AppAccessBlocked(locale: languageCode))
        );
      }
      else if (languageCode.isNotEmpty) {
        await setOfflineStatus(true, false);
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage(isEnglishUS: (languageCode == 'EN_US'), locale: languageCode, isOffline: isOffline))
        );
      }
      else {
        await setOfflineStatus(true, false);
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LanguageSelectionPage(isOffline: isOffline),
            )
        );
      }
    }
    if (pin_code.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(title: 'Allen App', authenticated: true))
      );
    }
    else if (languageCode.isNotEmpty && !isOffline) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage(isEnglishUS: (languageCode == 'EN_US'), locale: languageCode, isOffline: isOffline))
      );
    }
    else if (!isOffline) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LanguageSelectionPage(isOffline: isOffline),
        )
      );
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
      _authenticate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
          appBar: AppBar(
            title: Text(
              'Allen App',
              style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)
            ),
            centerTitle: true
          ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!isAuthenticated || widget.forceLogin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true
        ),
        body: LoginForm(formData: formData, submitFunction: _authenticate),
      );
    }
    else if (pin_code.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: TextStyle(fontFamily: 'helvetica,sans-serif', color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true
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
                  minimumSize: const Size(40, 40), //////// HERE
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
            title: Text(
                widget.title,
                style: TextStyle(fontFamily: 'helvetica,sans-serif',
                    color: Colors.white,
                    fontWeight: FontWeight.bold)
            ),
            centerTitle: true
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
                  minimumSize: const Size(40, 40), //////// HERE
                ),
                onPressed: () =>
                    showDialog<void>(
                      context: context,
                      builder: (context) {
                        return ScreenLock(
                          correctString: pin_code,
                          onCancelled: Navigator
                              .of(context)
                              .pop,
                          onUnlocked: () => {_authenticate(context)},
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
