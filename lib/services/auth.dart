import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../Env.dart';
import 'Offline.dart';
import 'package:sqflite/sqflite.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'query.dart';


// AUTHENTICATION TOKEN
const storage = FlutterSecureStorage();

final drupalDomain = Env.DRUPAL_URL ?? '';
final oauthClientId = Env.OAUTH_CLIENT_ID ?? '';
final oauthClientSecret = Env.OAUTH_CLIENT_SECRET ?? '';
final authorizationEndPoint = Uri.parse('https://' + drupalDomain + '/oauth/authorize');
final tokenUrl = Uri.parse('https://' + drupalDomain + '/oauth/token');
final redirectUri = 'com.biggerminds.allenapp://oauth2redirect';
final customUriScheme = 'com.biggerminds.allenapp';
Database ?db;
Future<void> saveToken(String token, String key) async {
  await storage.write(key: key, value: token);
}

Future<String?> getToken() async {
  return await storage.read(key: 'access_token');
}

Future<String?> getRefreshToken() async {
  return await storage.read(key: 'refresh_token');
}

Future<int?> getExpiry() async {
  var expiry_time = await storage.read(key: 'expires_in') ?? '0';
  return int.parse(expiry_time);
}

Future<String> getUserID() async {
  return await storage.read(key: 'user_id') ?? '0';
}

Future<String?> getLoginCode() async {
  return await storage.read(key: 'pin_code');
}

Future<void> storePinCode(token) async {
  await storage.write(key: 'pin_code', value: token);
}

Future<void> storeLangaugeCode(language) async {
  await storage.write(key: 'language', value: language);
}

Future<String?> getLangaugeCode() async {
  return await storage.read(key: 'language');
}

Future<bool?> getOfflineStatus() async {
  return bool.parse(await storage.read(key: 'isOffline') ?? 'false');
}

Future<void> setOfflineStatus(bool offlineStatus, bool rebuildDatabase) async {
  if (offlineStatus) {
    var database = await Offline().initDatabase(rebuildDatabase);
    db = database;
  }
  else {
    if (db != null) {
      List nonSyncedNotes = await Offline().getUnsyncedNotes(db);
      final GraphQLClient graphQLClient = client.value;
      for (var note in nonSyncedNotes) {
        await graphQLClient.mutate(
          MutationOptions(document: gql(createHighlight),
            variables: {
              'node_id': note['node_id'],
              'note': note['note'],
              'highlighted_text': note['selected_text'],
              'note_start': note['start_position'],
              'note_end': note['end_position'],
            }));
        await Offline().markNoteAsSynced(note['id'], db);
      }
      await db?.close();
      db = null;
    }
  }
  await storage.write(key: 'isOffline', value: offlineStatus.toString());
}

Future<int> getOfflineDate() async {
  return int.parse(await storage.read(key: 'offlineDate') ?? '0');
}

Future<void> setOfflineDate(int offlineDate) async {
  return storage.write(key: 'offlineDate', value: offlineDate.toString());
}


Future<void> saveNote(note) async {
  final GraphQLClient graphQLClient = client.value;
  await graphQLClient.mutate(MutationOptions(document: gql(createHighlight), variables: {'node_id': note.node_id, 'note': note.note, 'highlighted_text': note.selected_text, 'note_start': note.start_position, 'note_end': note.end_position}));
}
Future<Map<String, String>?> authenticateUser(userName, password) async {
  var redirectUri = kIsWeb ? ((Uri.base.host == '127.0.0.1' || Uri.base.host == 'localhost') ? 'http://127.0.0.1:${Uri.base.port}/auth.html' : 'https://${Uri.base.host}/auth.html') : 'com.biggerminds.allenapp://test/';
  //final url = Uri.https(drupalDomain, '/oauth/authorize', {
  //  'response_type': 'code',
  //  'client_id': oauthClientId,
  //  'redirect_uri': redirectUri,
  //  'scope': 'content_editor',
  //});
  //final result = await FlutterWebAuth2.authenticate(url: url.toString(), callbackUrlScheme: 'com.biggerminds.allenapp');
  //final code = Uri.parse(result).queryParameters['code'];
  final tokenResponse = await http.post(tokenUrl, body: {
    'client_id': oauthClientId,
    //'redirect_uri': redirectUri,
    'username': userName,
    'password': password,
    'scope': 'content_editor',
    'grant_type': 'password',
    'client_secret': oauthClientSecret,
  });
  print(tokenResponse);
  final token_response = jsonDecode(tokenResponse.body);
  final access_token = token_response['access_token'] as String;
  final refresh_token = token_response['refresh_token'] as String;
  final expires_in = (DateTime.now().millisecondsSinceEpoch + Duration(seconds: token_response['expires_in']).inMilliseconds);
  final return_values = <String, String>{'access_token': access_token, 'refresh_token': refresh_token, 'expires_in': expires_in.toString()};
  return Map<String, String>.from(return_values);
}

Future<String?> getNewToken() async {
  final refreshToken = await getRefreshToken();
  print('refreshtoken');
  print(refreshToken);
  final tokenResponse = await http.post(Uri.parse(tokenUrl.toString() + '?refresh'), body: {
    'client_id': oauthClientId,
    'grant_type': 'refresh_token',
    'refresh_token': refreshToken,
    'client_secret': oauthClientSecret,
  });
  var token_response = jsonDecode(tokenResponse.body);
  if (token_response['error'] != null) {
    return '';
  }
  final access_token = token_response['access_token'] as String;
  final refresh_token = token_response['refresh_token'] as String;
  saveToken(access_token, 'access_token');
  saveToken(refresh_token, 'refresh_token');
  final expires_in = (DateTime.now().millisecondsSinceEpoch + Duration(seconds: token_response['expires_in']).inMilliseconds);
  saveToken(expires_in.toString(), 'expires_in');
  return access_token;
}

Future<String?> getAccessToken() async {
  int expiryTime = await getExpiry() ?? 0;
  var now = DateTime.now().millisecondsSinceEpoch;
  String? token;
  if (now >= expiryTime) {
    token = await getNewToken();
  }
  else {
    token = await getToken();
  }
  return token != null ? 'Bearer $token' : null;
}
