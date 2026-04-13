import 'package:allenapp/services/Offline.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'query.dart';
import 'package:flutter/material.dart';
import '../screens/activitystart.dart';
import '../screens/activitydetail.dart';
import 'auth.dart';

Future<void> fetchTargetData(BuildContext context, String targetId, locale, isOffline) async {
  List items = [];
  items = await Offline().getActivities(locale, db, targetId);
  final RegExp activityPattern = RegExp(r'^(100|[1-9]?[0-9])$');
  if (items.isNotEmpty) {
    final item = items[0];
    // exception handling, leads back to activitystart screen if the decision target is a main activity node
    if (activityPattern.hasMatch(item['activity_id'] ?? ''
        .trim()
        .split(' ')
        .last)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityStartScreen(
            label: item['label'],
            body: item['body'],
            activityId: item['activity_id'],
            isEnglishUS: (locale == 'EN'),
            locale: locale,
            isOffline: isOffline
          ),
        ),
      );
    } else {
      // else navigates back to ActivityDetailsScreen with new details from decision target (recursive)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityDetailsScreen(
            nodeId: item['id'].toString() ?? '',
            label: item['label'],
            body: item['body'],
            decisionBody: item['decision_body'] ?? '',
            activityId: item['activity_id'] ?? '',
            decisionLabel: item['decision_labels'] ?? '',
            decisionTarget: item['decision_targets'] ?? '',
            decisionTaxonomy: item['decision_taxonomy_ids'] ?? '',
            isEnglishUS: (locale == 'EN'),
            locale: locale,
            isOffline: isOffline
          ),
        ),
      );
    }
  } else {
    print("No data found for target $targetId");
  }
}
