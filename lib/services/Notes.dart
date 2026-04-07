import 'package:allenapp/services/Offline.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'query.dart';
import 'package:flutter/material.dart';
import '../screens/activitystart.dart';
import '../screens/activitydetail.dart';
import 'auth.dart';

Future<void> fetchTargetData(BuildContext context, String targetId, locale, isOffline) async {
  List items = [];
  if (!isOffline) {
    final GraphQLClient graphQLClient = GraphQLProvider
        .of(context)
        .value;

    final result = await graphQLClient.query(
      QueryOptions(
        document: gql(getTarget),
        variables: {'id': targetId, 'langcode': locale},
      ),
    );

    if (result.hasException) {
      print(
          'Error fetching data for target $targetId: ${result.exception
              .toString()}');
      return;
    }

    items = result.data?['entityQuery']['items'] ?? [];
  }
  else {
    items = await Offline().getActivities(locale, db, targetId);
  }
  final RegExp activityPattern = RegExp(r'^(100|[1-9]?[0-9])$');

  if (items.isNotEmpty) {
    final item = items[0];
    // exception handling, leads back to activitystart screen if the decision target is a main activity node
    if (activityPattern.hasMatch((isOffline ? (item['activity_id'] ?? '') : item['translation']['fieldActivityIdRawField']['getString'])
        .trim()
        .split(' ')
        .last)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityStartScreen(
            label: (isOffline ? item['label'] : item['translation']['label']),
            body: (isOffline ? item['body'] : item['translation']['bodyRawField']['getString']),
            activityId: (isOffline ? item['activity_id'] : item['translation']['fieldActivityIdRawField']['getString']),
            isEnglishUS: (locale == 'en_US'),
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
            label: (isOffline ? item['label'] : item['translation']['label']),
            body: (isOffline ? item['body'] : item['translation']['bodyRawField']['getString']),
            decisionBody: (isOffline ? (item['decision_body'] ?? '')  : item['translation']['fieldDecisionBodyRawField']['getString']),
            activityId: (isOffline ? (item['activity_id'] ?? '') : item['translation']['fieldActivityIdRawField']['getString']),
            decisionLabel: (isOffline ? (item['decision_labels'] ?? '') : item['translation']['fieldDecisionLabelRawField']['getString']),
            decisionTarget: (isOffline ? (item['decision_targets'] ?? '') : item['translation']['fieldDecisionTargetRawField']['getString']),
            decisionTaxonomy: (isOffline ? (item['decision_taxonomy_ids'] ?? '')  : item['translation']['fieldDecisionTaxonomyRawField']
            ['getString']),
            isEnglishUS: (locale == 'en_US'),
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