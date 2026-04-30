import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'auth.dart';
import 'device_service.dart';
import 'package:http/http.dart' as http;
import '../Env.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'query.dart';

class Offline {

  Future<Database> initDatabase(bool isReOpen) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isLinux)) {
      sqfliteFfiInit();
    }
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    Database database = await openDatabase(join(await getDatabasesPath(), 'allen_app.db'), version: 1,
      onCreate: (Database db, int version) async {
        return db.execute('CREATE TABLE taxonomy (id INTEGER PRIMARY KEY, vid TEXT, parent_id INTEGER, title TEXT, weight INTEGER, colour TEXT, current INTEGER)').then((val) async {
          await db.execute('CREATE TABLE node (id INTEGER, node_type TEXT, title TEXT, body TEXT, content_type TEXT, langcode TEXT, activity_id INTEGER, last_updated INTEGER, PRIMARY KEY (id, langcode))');
          await db.execute('CREATE TABLE taxonomy_node (id INTEGER PRIMARY KEY, taxonomy_id INTEGER, node_id INTEGER, langcode TEXT)');
          await db.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, user_id INTEGER, node_id INTEGER, note TEXT, selected_text TEXT, start_position INTEGER, end_position INTEGER, is_synced INTEGER, upstream_id, INTEGER, current INTEGER)');
          await db.execute('CREATE TABLE activity_decision (id INTEGER PRIMARY KEY, node_id INTEGER, decision_labels TEXT, decision_targets TEXT, decision_taxonomy_ids TEXT, decision_body TEXT, last_updated INTEGER, langcode TEXT, current INTEGER)');
          await db.execute('CREATE TABLE device_cache (key TEXT PRIMARY KEY, value TEXT)');
        });
      },
      onOpen: (Database db) async {
        await getSourceData(db, isReOpen);
        dbIsReady = true;
      },
    );
    db = database;
    return database;
  }

  Future getSourceData(Database db, bool isReOpen) async {
    var token = await getAccessToken() ?? '';
    var urlParam = '';
    if (isReOpen) {
      await db.execute("DELETE FROM taxonomy");
      await db.execute("DELETE FROM node");
      await db.execute("DELETE FROM notes");
      await db.execute("DELETE FROM taxonomy_node");
      await db.execute("DELETE FROM activity_decision");
    }
    var isAppOffline = await getOfflineStatus();
    if (isAppOffline) {
      return;
    }
    var offlineDate = await getLastSyncDate() ?? 0;
    var now = DateTime.now();
    var check = now.subtract(const Duration(hours: 12));
    if (offlineDate > check.millisecondsSinceEpoch) {
      return;
    }
    var forceRefreshData = await getForceRefreshData();
    if (forceRefreshData) {
      urlParam = '?changed=0';
    }
    else {
      urlParam = '?changed=' + offlineDate.toString();
    }
    List<dynamic> nodeIds = [];
    List<dynamic> taxonomyIds = [];
    List<dynamic> notesIds = [];
    var nodeIdsResponse = await http.get(
      Uri.parse('https://' + Env.DRUPAL_URL + '/bmfeeds/node-id-feed'),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (nodeIdsResponse.statusCode == 200) {
      nodeIds = jsonDecode(nodeIdsResponse.body);
    }
    var taxonomyIdsResponse = await http.get(
      Uri.parse('https://' + Env.DRUPAL_URL + '/bmfeeds/taxonomy-id-feed'),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (taxonomyIdsResponse.statusCode == 200) {
      taxonomyIds = jsonDecode(taxonomyIdsResponse.body);
    }
    var taxonomyResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/taxonomy-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (taxonomyResponse.statusCode != 200) {
      return;
    }
    final taxonomyResponseJson = jsonDecode(taxonomyResponse.body) as List<dynamic>;
    for (var i = 0; i < taxonomyResponseJson.length; i++) {
      if (!isReOpen) {
        await db.delete('taxonomy',
            where: 'id = ?',
            whereArgs: [taxonomyResponseJson[i]['id']]
        );
      }
      await db.execute(
          'INSERT INTO taxonomy (id, vid, parent_id, title, weight, colour, current) VALUES (?, ?, ?, ?, ?, ?, 1)',
          [
            taxonomyResponseJson[i]['id'],
            taxonomyResponseJson[i]['vid'],
            taxonomyResponseJson[i]['parent_id'],
            taxonomyResponseJson[i]['title'],
            taxonomyResponseJson[i]['weight'],
            taxonomyResponseJson[i]['colour']
          ]);
    }
    await db.delete('taxonomy',
        where: 'id NOT IN (${List.filled(taxonomyIds.length, '?').join(',')})',
        whereArgs: taxonomyIds
    );
    var nodeResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/node-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (nodeResponse.statusCode != 200) {
      return;
    }
    final nodeResponseJson = jsonDecode(nodeResponse.body) as List<dynamic>;
    for (var i = 0; i < nodeResponseJson.length; i++) {
      if (!isReOpen) {
        await db.delete('node',
            where: 'id = ? AND langcode = ?',
            whereArgs: [nodeResponseJson[i]['id'], nodeResponseJson[i]['langcode']]
        );
      }
      await db.execute(
          'INSERT INTO node (id, node_type, title, body, langcode, content_type, activity_id, last_updated, current) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)',
          [
            nodeResponseJson[i]['id'],
            nodeResponseJson[i]['node_type'],
            nodeResponseJson[i]['title'],
            nodeResponseJson[i]['body'],
            nodeResponseJson[i]['langcode'],
            nodeResponseJson[i]['content_type'],
            nodeResponseJson[i]['activity_id'],
            nodeResponseJson[i]['last_updated']
          ]);
    }
    await db.delete('node',
        where: 'id NOT IN (${List.filled(nodeIds.length, '?').join(',')})',
        whereArgs: nodeIds
    );
    var nodeTaxonomyResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/node-taxonomy-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (nodeTaxonomyResponse.statusCode != 200) {
      return;
    }
    List<int> nodeIdsProcessed = [];
    final nodeTaxonomyResponseJson = jsonDecode(nodeTaxonomyResponse.body) as List<dynamic>;
    for (var i = 0; i < nodeTaxonomyResponseJson.length; i++) {
      if (!isReOpen && !nodeIdsProcessed.contains(int.parse(nodeTaxonomyResponseJson[i]['nid']))) {
        await db.delete('taxonomy_node',
            where: 'node_id = ?',
            whereArgs: [nodeTaxonomyResponseJson[i]['nid']]
        );
        nodeIdsProcessed.add(int.parse(nodeTaxonomyResponseJson[i]['nid']));
      }
      if (nodeTaxonomyResponseJson[i]['taxonomy_term_id'] != "null") {
        await db.execute(
          'INSERT INTO taxonomy_node (node_id, taxonomy_id, langcode) VALUES (?, ?, ?)',
          [
            nodeTaxonomyResponseJson[i]['nid'],
            nodeTaxonomyResponseJson[i]['taxonomy_term_id'],
            nodeTaxonomyResponseJson[i]['langcode']
          ]);
      }
    }
    // Cleanup the taxonomy node table of table that cannot be right.
    await db.delete('taxonomy_node',
        where: 'taxonomy_id NOT IN (${List.filled(taxonomyIds.length, '?').join(',')})',
        whereArgs: taxonomyIds
    );
    await db.delete('taxonomy_node',
        where: 'node_id NOT IN (${List.filled(nodeIds.length, '?').join(',')})',
        whereArgs: nodeIds
    );
    var decisionResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/decison-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (decisionResponse.statusCode != 200) {
      return;
    }
    final decisionResponseJson = jsonDecode(decisionResponse.body) as List<dynamic>;
    List<int> decisionNodeIdsProcessed = [];
    for (var i = 0; i < decisionResponseJson.length; i++) {
      if (!isReOpen && !decisionNodeIdsProcessed.contains(int.parse(decisionResponseJson[i]['nid']))) {
        await db.delete('activity_decision',
            where: 'node_id = ?',
            whereArgs: [decisionResponseJson[i]['nid']]
        );
        decisionNodeIdsProcessed.add(int.parse(decisionResponseJson[i]['nid']));
      }
      await db.execute(
          'INSERT INTO activity_decision (node_id, decision_labels, decision_targets, decision_taxonomy_ids, decision_body, langcode, last_updated) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            decisionResponseJson[i]['nid'],
            decisionResponseJson[i]['decision_label'],
            decisionResponseJson[i]['decision_target'],
            decisionResponseJson[i]['decision_taxonomy'],
            decisionResponseJson[i]['decision_body'],
            decisionResponseJson[i]['langcode'],
            decisionResponseJson[i]['last_updated']
          ]);
    }
    await db.delete('activity_decision',
        where: 'node_id NOT IN (${List.filled(nodeIds.length, '?').join(',')})',
        whereArgs: nodeIds
    );
    var notesResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/notes-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (notesResponse.statusCode != 200) {
      return;
    }
    final notesResponseJson = jsonDecode(notesResponse.body) as List<dynamic>;
    for (var i = 0; i < notesResponseJson.length; i++) {
      if (!isReOpen) {
        if (notesResponseJson[i]['id'] != null) {
          await db.delete('notes',
              where: 'upstream_id = ?',
              whereArgs: [notesResponseJson[i]['id']]
          );
        }
      }
      await db.execute(
          'INSERT INTO notes (upstream_id, node_id, note, selected_text, start_position, end_position, is_synced) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            notesResponseJson[i]['id'],
            notesResponseJson[i]['node_id'],
            notesResponseJson[i]['note'],
            notesResponseJson[i]['selected_text'],
            notesResponseJson[i]['note_start'],
            notesResponseJson[i]['note_end'],
            1,
          ]);
      await db.delete('notes',
          where: 'upstream_id NOT IN (${List.filled(notesIds.length, '?').join(',')})',
          whereArgs: notesIds
      );
      await setForceRefreshData(false);
      await setLastSyncDate(DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<List<Map<String, dynamic>>> getRootTaxonomy(Database? db, String vid) async {
    var terms =await db?.query('taxonomy',
      columns: ['id', 'parent_id', 'vid', 'weight', 'colour', 'title'],
      where: 'vid = ? AND parent_id = 0',
      whereArgs: [vid],
    );
    return terms ?? [];
  }

  Future<List<Map<String, dynamic>>> getACLTaxonomy(String? parentId, String? termId, Database? db) async {
    String whereClause = '';
    List WhereArguments = [];
    if ((parentId ?? '').isNotEmpty) {
      whereClause = 'parent_id = ? AND vid = ?';
      WhereArguments = [parentId, 'allen_cognitive_levels'];
    }
    if ((termId ?? '').isNotEmpty) {
      whereClause = 'id = ? AND vid = ?';
      WhereArguments = [termId, 'allen_cognitive_levels'];
    }
    List<Map<String,Object?>>? terms = [];
    if (whereClause.isNotEmpty) {
      terms = await db?.query('taxonomy',
          columns: ['id', 'parent_id', 'vid', 'weight', 'colour', 'title'],
          where: whereClause,
          whereArgs: WhereArguments,
          orderBy: 'weight DESC'
      );
    }
    else {
      terms = await db?.query('taxonomy',
          columns: ['id', 'parent_id', 'vid', 'weight', 'colour', 'title'],
          orderBy: 'weight DESC'
      );
    }
    return terms ?? [];
  }

  Future<List<Map<String, dynamic>>> getChildTaxonomy(String parentId, String vid, Database? db) async {
    String whereClause = '';
    List WhereArguments = [];
    whereClause = 'parent_id = ? AND vid = ?';
    WhereArguments = [parentId, vid];
    var terms = await db?.query('taxonomy',
        columns: ['id', 'parent_id', 'vid', 'weight', 'colour', 'title'],
        where: whereClause,
        whereArgs: WhereArguments,
        orderBy: 'weight DESC'
    );
    return terms ?? [];
  }

  Future<List<Map<String, dynamic>>> getNode(String? nodeTitle, String LanguageCode, String node_type, Database? db) async {
    if (db == null) {
      throw new Exception('No Database avalisable');
    }
    String whereClause = '';
    List whereArguments = [];
    if ((nodeTitle ?? '').isNotEmpty) {
      whereClause = 'title = ? AND langcode = ? AND node_type = ?';
      whereArguments = [nodeTitle, LanguageCode, node_type];
    }
    else {
      whereClause = 'langcode = ? AND node_type = ?';
      whereArguments = [LanguageCode, node_type];
    }
    var nodes = await db?.query('node',
      columns: ['id', 'title', 'body', 'activity_id'],
      where: whereClause,
      whereArgs: whereArguments,
    );
    print(db);
    var ids = await db.rawQuery("SELECT title, langcode FROM node WHERE node_type = 'allen_app_information'");
    print(whereClause);
    print(whereArguments);
    print(ids);
    return nodes ?? [];
  }

  Future<List<Map<String, dynamic>>> getNodesByTaxonomyId(String taxonomyId, String languageCode, String node_type, Database? db) async {
    var localeJoin = ((node_type == 'conceptual_framework' || node_type == 'acls_6') ? '' : 'AND tn.langcode = n.langcode');
    var sql = "SELECT n.id, n.body, n.title AS label, n.content_type FROM node n INNER JOIN taxonomy_node tn ON tn.node_id = n.id " + localeJoin + " WHERE tn.taxonomy_id = " + taxonomyId + " AND n.langcode = '" + languageCode + "' AND n.node_type = '" + node_type + "'";
    var nodes = await db?.rawQuery(sql);
    return nodes ?? [];
  }

  Future<List<Map<String, dynamic>>> getCFTerms(Database? db, String parentId) async {
    var terms = await db?.query('taxonomy',
      where: 'vid = ? AND parent_id = ?',
      whereArgs: ['conceptual_framework', parentId],
    );
    return terms ?? [];
  }

  Future<List<Map<String, dynamic>>> getActivities(String languageCode, Database? db, String? nodeId) async {
    var sql = "SELECT n.id, n.body, n.activity_id, n.title AS label, d.decision_labels, d.decision_targets, d.decision_taxonomy_ids, d.decision_body FROM node n LEFT JOIN activity_decision d ON d.node_id = n.id AND d.langcode = n.langcode WHERE n.langcode = '" + languageCode + "' AND n.node_type = 'acls_6_activities'";
    if ((nodeId ?? '').isNotEmpty) {
      sql = sql + ' AND n.id = ' + (nodeId ?? '');
    }
    var activities = await db?.rawQuery(sql);
    return activities ?? [];
  }

  Future <List<Map<String, dynamic>>> getParentTaxonomyTerm(String termId, Database? db) async {
    var sql = "SELECT parentTerm.* FROM taxonomy parentTerm INNER JOIN taxonomy term ON term.parent_id = parentTerm.id WHERE term.id = " + termId;
    var terms = await db?.rawQuery(sql);
    return terms ?? [];
  }

  Future <List<Map<String, dynamic>>> getUnsyncedNotes(Database? db) async {
    var terms = await db?.query('notes',
      where: 'is_synced = 0'
    );
    return terms ?? [];
  }

  Future saveNote(int node_id, String note, String selected_text, int note_start, int note_end, Database? db) async {
    var values = {
      'node_id': node_id,
      'note': note,
      'selected_text': selected_text,
      'start_position': note_start,
      'end_position': note_end,
      'is_synced': 0,
    };
    var savedNote = await db?.insert('notes', values);
    var offline = await getOfflineStatus() ?? false;
    if (!offline) {
      final GraphQLClient graphQLClient = client.value;
      var mutationResult = await graphQLClient.mutate(
        MutationOptions(document: gql(createHighlight),
          variables: {
            'node_id': node_id,
            'note': note,
            'highlighted_text': selected_text,
            'note_start': note_start,
            'note_end': note_end,
         })).then((result) async {
          await Offline().markNoteAsSynced(savedNote, db,
            result.data?['createCustomHighlight']['customHighlight']['id'] ?? '');
      });
    }
    return savedNote;
  }

  Future getNotesByNode(int node_id, Database? db) async {
    if (db == null) {
      return Error();
    }
    var items = await db.query('notes',
      where: 'node_id = ?',
      whereArgs: [node_id],
    );
    print(items);
    return items ?? [];
  }

  Future <List<Map<String, dynamic>>> getAllNotes(Database? db, String langcode) async {
    var sql = "SELECT no.*, n.node_type, n.title, n.body, tn.taxonomy_id FROM notes no INNER JOIN node n ON n.id = no.node_id INNER JOIN taxonomy_node tn ON tn.node_id = n.id AND n.langcode = ?";
    var notes = await db?.rawQuery(sql, [langcode]);
    return notes ?? [];
  }

  Future <List<Map<String, dynamic>>> search(Database? db, String langcode, String searchValue) async {
    var sql = "SELECT n.title, n.node_type, n.body, tn.taxonomy_id FROM node n LEFT JOIN taxonomy_node tn ON tn.node_id = n.id AND n.langcode = tn.langcode WHERE (n.title LIKE ? OR n.body LIKE ?) AND n.langcode = ?";
    var results = await db?.rawQuery(sql, ['%' + searchValue + '%', '%' + searchValue + '%', langcode]);
    return results ?? [];
  }

  Future markNoteAsSynced(noteId, Database? db, String upstreamNodeId) async {
    await db?.update('notes', {
        'is_synced': 1,
        'upstream_id': int.parse(upstreamNodeId),
        'current': 1
      },
      whereArgs: [noteId],
      where: 'id = ?'
    );
  }

  Future offlineDatabaseExists() async {
    return await databaseExists(join(await getDatabasesPath(), 'allen_app.db'));
  }

  /// Caches the current device info (id, type, threshold) into the local DB
  /// so that offline sessions can reference device data without network access.
  Future<void> cacheDeviceInfo(Database? db) async {
    if (db == null) return;
    final deviceService = DeviceService();
    final entries = {
      'device_id': deviceService.deviceId ?? '',
      'device_type': deviceService.deviceType ?? '',
      'device_threshold': deviceService.deviceThreshold.toString(),
    };
    for (final entry in entries.entries) {
      await db.insert(
        'device_cache',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Returns a map of cached device info from the local DB.
  Future<Map<String, String>> getCachedDeviceInfo(Database? db) async {
    if (db == null) return {};
    final rows = await db.query('device_cache');
    return {
      for (final row in rows)
        row['key'] as String: row['value'] as String,
    };
  }

}