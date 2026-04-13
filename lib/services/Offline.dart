import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'auth.dart';
import 'package:http/http.dart' as http;
import '../Env.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'query.dart';

class Offline {

  Future initDatabase(bool isReOpen) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isLinux)) {
      sqfliteFfiInit();
    }
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    var database = await openDatabase(join(await getDatabasesPath(), 'allen_app.db'), version: 1,
      onCreate: (Database db, int version) async {
        return db.execute('CREATE TABLE taxonomy (id INTEGER PRIMARY KEY, vid TEXT, parent_id INTEGER, title TEXT, weight INTEGER, colour TEXT, current INTEGER)').then((val) async {
          await db.execute('CREATE TABLE node (id INTEGER, node_type TEXT, title TEXT, body TEXT, content_type TEXT, langcode TEXT, activity_id INTEGER, last_updated INTEGER, current INTEGER, PRIMARY KEY (id, langcode))');
          await db.execute('CREATE TABLE taxonomy_node (id INTEGER PRIMARY KEY, taxonomy_id INTEGER, node_id INTEGER, langcode TEXT, current INTEGER)');
          await db.execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, user_id INTEGER, node_id INTEGER, note TEXT, selected_text TEXT, start_position INTEGER, end_position INTEGER, is_synced INTEGER, upstream_id, INTEGER, current INTEGER)');
          await db.execute('CREATE TABLE activity_decision (id INTEGER PRIMARY KEY, node_id INTEGER, decision_labels TEXT, decision_targets TEXT, decision_taxonomy_ids TEXT, decision_body TEXT, last_updated INTEGER, langcode TEXT, current INTEGER)');
        });
      },
      onOpen: (Database db) async {
        await getSourceData(db, isReOpen);
        dbIsReady = true;
        await setLastSyncDate(DateTime.now().millisecondsSinceEpoch);
      },
    );
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
    var offlineDate = await getLastSyncDate() ?? 0;
    var now = DateTime.now();
    var check = now.subtract(const Duration(hours: 12));
    if (offlineDate > check.millisecondsSinceEpoch) {
      return;
    }
    urlParam = '?changed=' + offlineDate.toString();
    var taxonomyResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/taxonomy-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (taxonomyResponse.statusCode != 200) {
      return;
    }
    final taxonomyResponseJson = jsonDecode(taxonomyResponse.body) as List<dynamic>;
    await db.execute("UPDATE taxonomy SET current = 0");
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
        where: 'current = 0'
    );
    var nodeResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/node-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (nodeResponse.statusCode != 200) {
      return;
    }
    final nodeResponseJson = jsonDecode(nodeResponse.body) as List<dynamic>;
    await db.execute("UPDATE node SET current = 0");
    for (var i = 0; i < nodeResponseJson.length; i++) {
      if (!isReOpen) {
        await db.delete('notes',
            where: 'id = ?',
            whereArgs: [nodeResponseJson[i]['id']]
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
        where: 'current = 0'
    );
    var nodeTaxonomyResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/node-taxonomy-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (nodeTaxonomyResponse.statusCode != 200) {
      return;
    }
    await db.execute("UPDATE taxonomy_node SET current = 0");
    final nodeTaxonomyResponseJson = jsonDecode(nodeTaxonomyResponse.body) as List<dynamic>;
    for (var i = 0; i < nodeTaxonomyResponseJson.length; i++) {
      if (!isReOpen) {
        await db.delete('taxonomy_node',
            where: 'id = ?',
            whereArgs: [i]
        );
      }
      if (nodeTaxonomyResponseJson[i]['taxonomy_term_id'] != "null") {
        await db.execute(
          'INSERT INTO taxonomy_node (id, node_id, taxonomy_id, langcode, current) VALUES (?, ?, ?, ?, 1)',
          [
            i,
            nodeTaxonomyResponseJson[i]['nid'],
            nodeTaxonomyResponseJson[i]['taxonomy_term_id'],
            nodeTaxonomyResponseJson[i]['langcode']
          ]);
      }
    }
    await db.delete('taxonomy_node',
        where: 'current = 0'
    );
    var decisionResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/decison-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (decisionResponse.statusCode != 200) {
      return;
    }
    await db.execute("UPDATE activity_decision SET current = 0");
    final decisionResponseJson = jsonDecode(decisionResponse.body) as List<dynamic>;
    for (var i = 0; i < decisionResponseJson.length; i++) {
      if (!isReOpen) {
        await db.delete('activity_decision',
            where: 'id = ?',
            whereArgs: [i]
        );
      }
      await db.execute(
          'INSERT INTO activity_decision (id, node_id, decision_labels, decision_targets, decision_taxonomy_ids, decision_body, langcode, last_updated, current) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)',
          [
            i,
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
        where: 'current = 0'
    );
    var notesResponse = await http.get(
      Uri.parse('https://' +  Env.DRUPAL_URL + '/bmfeeds/notes-feed' + urlParam),
      headers: {HttpHeaders.authorizationHeader: token},
    );
    if (decisionResponse.statusCode != 200) {
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
          'INSERT INTO notes (upstream_id, node_id, note, selected_text, start_position, end_position, is_synced, current) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            notesResponseJson[i]['id'],
            notesResponseJson[i]['node_id'],
            notesResponseJson[i]['note'],
            notesResponseJson[i]['selected_text'],
            notesResponseJson[i]['note_start'],
            notesResponseJson[i]['note_end'],
            1,
            1
          ]);
      await db.delete('notes',
          where: 'is_synced = 1 AND current = 0'
      );
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
    var terms = await db?.query('taxonomy',
        columns: ['id', 'parent_id', 'vid', 'weight', 'colour', 'title'],
        where: whereClause,
        whereArgs: WhereArguments,
        orderBy: 'weight DESC'
    );
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
    var items = await db?.query('notes',
      where: 'node_id = ?',
      whereArgs: [node_id],
    );
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

}