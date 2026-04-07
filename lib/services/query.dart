import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/auth.dart';
import 'package:flutter/material.dart';
import '../Env.dart';

final drupalDomain = Env.DRUPAL_URL ?? '';
// GRAPHQL
final HttpLink httpLink =
    HttpLink('https://' + drupalDomain + '/graphql');

final AuthLink authLink = AuthLink(
  getToken: () => getAccessToken(),
);

ValueNotifier<GraphQLClient> client = ValueNotifier(
  GraphQLClient(
    link: authLink.concat(httpLink),
    cache: GraphQLCache(),
    queryRequestTimeout: Duration(seconds: 30),
  ),
);

const String getParentTerms = r"""
  query getParentTerms {
    entityQuery(
      entityType: TAXONOMY_TERM
      limit: 1000
      filter: { conditions: [
      { field: "parent.target_id", value: "0" }
      { field: "vid.target_id", value: "allen_cognitive_levels" }
      ] }
    ) {
      items {
        label
        id
        ... on TaxonomyTermAllenCognitiveLevels {
          fieldLevelColourRawField{
            getString
          }
          weightRawField {
            getString
          }
        }
      }
    }
  }
""";

const String getChildTerms = r"""
query getChildTerms ($parentIds: [String!]) {
    entityQuery(
      entityType: TAXONOMY_TERM
      limit: 1000
      filter: { conditions: [
      { field: "parent.target_id", value: $parentIds }
      { field: "vid.target_id", value: "allen_cognitive_levels" }
      ] }
    ) {
      items {
        label
        id
        ... on TaxonomyTermAllenCognitiveLevels {
          fieldLevelColourRawField{
            getString
          }
          weightRawField {
            getString
          }
        }
      }
    }
  }
""";

const String getTaxonomyTerm = r"""
  query getTaxonomyTerm($termId: [String!]) {
    entityQuery(
      entityType: TAXONOMY_TERM
      limit: 1000
      filter: {conditions: [{field: "tid", value: $termId}]}
    ) {
      items {
        label
        id
      }
    }
  }
""";

const String getNodesByTerm = r"""
  query GetNodesByTerm ($termId: String!, $langcode: Langcode!) {
    entityQuery(
      entityType: NODE
      limit: 1000
      filter: {
        conditions: [
          { field: "field_allen_cognitive_level.target_id", value: [$termId] }
        ]
      }
    ) {
      items {
        label
        id
        ... on NodeAllenCognitiveLevels {
          fieldAllenCognitiveLevelRawField {
            getString
          }
          fieldContentTypeRawField {
            getString
          }
          translation(langcode: $langcode) {
            titleRawField {
              getString
            }
            bodyRawField {
              getString
            }
          }
        }
        ... on NodeConceptualFramework {
          fieldConceptualFrameworkRawField {
            getString
          }
          fieldContentTypeRawField {
            getString
          }
          translation(langcode: $langcode) {
            titleRawField {
              getString
            }
            bodyRawField {
              getString
            }
          }
        }
      }
    }
  }
""";

const String getParentCFTerms = r"""
query getParentCFTerms {
  entityQuery(
    entityType: TAXONOMY_TERM
    limit: 1000
    filter: {
      conditions: [
        { field: "vid.target_id", value: "conceptual_framework" }
        { field: "parent.target_id", value: "0" }
      ]
    }
  ) {
    items {
      label
      id
    }
  }
}
""";

const String getChildCFTerms = r"""
query getChildCFTerms($parentIds: [String!]) {
    entityQuery(
      entityType: TAXONOMY_TERM
      limit: 1000
      filter: { conditions: [
      { field: "parent.target_id", value: $parentIds }
      { field: "vid.target_id", value: "conceptual_framework" }
      ] }
    ) {
      items {
        label
        id
      }
    }
  }
  """;

const String getCFNodesByTerm = r"""
  query GetCFNodesByTerm($termId: String!, $langcode: Langcode!) {
    entityQuery(
      entityType: NODE
      limit: 1000
      filter: {
        conditions: [
          { field: "field_conceptual_framework.target_id", value: [$termId] }
        ]
      }
    ) {
      items {
        label
        id
        ... on NodeConceptualFramework {
          translation(langcode: $langcode) {
            titleRawField {
              getString
            }
            bodyRawField {
              getString
            }
          }
        }
      }
    }
  }
""";

// add conceptual frameworks to the conditional
const String getSearchResults = r"""
query getSearchResults($searchTerm: String!, $langcode: Langcode!) {
  entityQuery(
    entityType: NODE
    limit: 1000
    filter: {
      groups: [
        {
          conjunction: OR
          conditions: [
            { field: "title", operator: CONTAINS, value: [$searchTerm] }
            { field: "body", operator: CONTAINS, value: [$searchTerm] }
          ]
        }
        {
          conjunction: OR
          conditions: [
            { field: "type.target_id", operator: IN, value: ["conceptual_framework"] }
            { field: "type.target_id", operator: IN, value: ["web_app"] }
            { field: "type.target_id", operator: IN, value: ["acls_6_activities"] }
            { field: "type.target_id", operator: IN, value: ["acls6"] }
            { field: "type.target_id", operator: IN, value: ["allen_cognitive_levels"] }
          ]
        }
      ]
    }
  ) {
    items {
      label
      id
      entityBundle
      ... on NodeAllenCognitiveLevels {
        fieldAllenCognitiveLevelRawField {
          getString
        }
        translation(langcode: $langcode) {
          titleRawField {
            getString
          }
          bodyRawField,{
            getString
          }
        }
      }
      ... on NodeConceptualFramework {
        fieldConceptualFrameworkRawField {
          getString
        }
        translation(langcode: $langcode) {
          titleRawField {
            getString
          }
          bodyRawField {
            getString
          }
        }
      }
      ... on NodeAcls6 {
        titleRawField {
          getString
        }
        bodyRawField {
          getString
        }
      }
      ... on NodeAcls6Activities {
        translation(langcode: $langcode) {
          titleRawField {
            getString
          }
          bodyRawField {
            getString
          }
        }
      }
    }
  }
}
""";

const String getParentID = r"""
query getParentID($termId: String!) {
    entityQuery(
      entityType: TAXONOMY_TERM
      limit: 1000
      filter: { conditions: [
      { field: "tid", value: [$termId] }
      { field: "vid.target_id", value: "allen_cognitive_levels" }
      ] }
    ) {
      items {
        ... on TaxonomyTermAllenCognitiveLevels {
        parentRawField {
            getString
          }
      }
      }
    }
  }
""";

const String getParentTermsACLS = r"""
  query getParentTermsACLS {
    entityQuery(
      entityType: TAXONOMY_TERM
      limit: 1000
      filter: { conditions: [
      { field: "parent.target_id", value: "0" }
      { field: "vid.target_id", value: "acls_6" }
      ] }
    ) {
      items {
        id
      }
    }
  }
""";

final String getChildTermsACLS = r"""
    query getChildTermsACLS($parentIds: [String!]) {
      entityQuery(
        entityType: TAXONOMY_TERM
        limit: 1000
        filter: {
          conditions: [
            { field: "parent.target_id", value: $parentIds }
            { field: "vid.target_id", value: "acls_6" }
          ]
        }
      ) {
        items {
          id
        }
      }
    }
  """;

const String getNodeACLS = r"""
query GetNodesACLS ($termId: String!) {
    entityQuery(
      entityType: NODE
      limit: 1000
      filter: {
        conditions: [
          { field: "field_acls_6.target_id", value: [$termId] }
        ]
      }
    ) {
      items {
        label
        id
        ... on NodeAcls6 {
          bodyRawField {
            getString
          }
          fieldContentTypeRawField{
            getString
          }
        }
      }
    }
  }
""";

const String getActivities = r"""
  query GetActivities($langcode: Langcode!) {
    entityQuery(
      entityType: NODE
      limit: 1000
      filter: {
        conditions: [
          { field: "type.target_id", value: "acls_6_activities" }
        ]
      }
    ) {
      items {
        ... on NodeAcls6Activities{
          id
          label
          bodyRawField{
            getString
          }
          fieldDecisionBodyRawField {getString}
          fieldActivityIdRawField {
            getString
          }
          fieldDecisionLabelRawField {
            getString
          }
          fieldDecisionTargetRawField {
            getString
          }
          fieldDecisionTaxonomyRawField {
            getString
          }
          translation(langcode: $langcode) {
            titleRawField{
              getString
            }
            bodyRawField {
              getString
            }
            fieldDecisionBodyRawField {getString}
            fieldActivityIdRawField {
              getString
            }
            fieldDecisionLabelRawField {
              getString
            }
            fieldDecisionTargetRawField {
              getString
            }
            fieldDecisionTaxonomyRawField {
              getString
            }
          }
        }
      }
    }
  }
""";

const String getTarget = r"""
query GetActivities($id: [String], $langcode: Langcode!) {
  entityQuery(
    entityType: NODE
    limit: 1000
    filter: {
      conditions: [
        { field: "type.target_id", value: "acls_6_activities" }
        { field: "nid.value", value: $id }
      ]
    }
  ) {
    items {
      ... on NodeAcls6Activities{
        translation(langcode: $langcode) {
          label
          bodyRawField{
            getString
          }
          fieldDecisionBodyRawField {getString}
          fieldActivityIdRawField {
            getString
          }
          fieldDecisionLabelRawField {
            getString
          }
          fieldDecisionTargetRawField {
            getString
          }
          fieldDecisionTaxonomyRawField {
            getString
          }
        }
      }
    }
  }
}

""";

const String createHighlight = r"""
  mutation CreateHighlight($note: String!, $node_id: Float!, $highlighted_text: String!, $note_start: Int!, $note_end: Int!) {
    createCustomHighlight(
      data: {note: $note, node_id: $node_id, highlighted_text: $highlighted_text, note_start: $note_start, note_end: $note_end}
    ) {
      customHighlight {
        id
        label
        nodeIdRawField {
          getString
        }
        noteEndRawField {
          getString
        }
        noteStartRawField {
          getString
        }
      }
    }
  }
""";


const String getLoggedInUser = r"""
  query getCurrentUser {
    currentUser {
      id
      label
    }
  }
""";

const getNotesForNode = r"""
  query getNotes($nodeId: [String], $user_id: [String]) {
    entityQuery(
      entityType: CUSTOM_HIGHLIGHT
      limit: 1000
      filter: {
        conditions: [
          { field: "node_id", value: $nodeId}
          { field: "uid", value: $user_id }
        ]
      }
    ) {
      items {
        ... on CustomHighlight {
          id
          label
          noteStartRawField {
            getString
          }
          noteEndRawField {
            getString
          }
          noteRawField {
            getString
          }
        }
      }
    }
  }
""";

const getUserNotes = r"""
query getUserNotes($user_id: [String]) {
  entityQuery(
    entityType: CUSTOM_HIGHLIGHT
    limit: 1000
    filter: {conditions: [{field: "uid", value: $user_id}]}
  ) {
    items {
      ... on CustomHighlight {
        id
        label
        nodeIdRawField {
          getString
          entity {
            referencedEntities {
              entityTypeId
              id
              entityBundle
            }
          }
        }
        noteStartRawField {
          getString
        }
        noteEndRawField {
          getString
        }
        noteRawField {
          getString
        }
        referencedEntities {
          id
          label
          entityTypeId
          entityBundle
        }
      }
    }
  }
}
""";

const getLanguages = r"""
  query getLangauges {
    entityQuery(entityType: CONFIGURABLE_LANGUAGE) {
      items {
        langcode
        label
        id
      }
    }
  }
""";

const getSinglePage = r"""
  query getSinglePage($langcode: Langcode!, $nodeTitle: [String]!) {
    entityQuery(
      entityType: NODE
      limit: 1000
      filter: {
        conditions: [
          { field: "type.target_id", value: "allen_app_information" }
          { field: "title", value: $nodeTitle }
       ]
      }
    ) {
      items {
        ... on NodeAllenAppInformation {
          translation(langcode: $langcode) {
            label
            bodyRawField{
              getString
            }
          }
        }
      }
    }
  }

""";

const getNode = r"""
  query getNode($nodeId: [String]!) {
  entityQuery(
    entityType: NODE
    filter: {conditions: {field: "nid", value: $nodeId}}
  ) {
    items {
      id
      ... on NodeAllenCognitiveLevels {

        fieldAllenCognitiveLevelRawField {
          getString
        }
      }
      ... on NodeConceptualFramework {
        fieldConceptualFrameworkRawField {
          getString
        }
      }
      ... on NodeAcls6 {
        fieldAcls6RawField {
          getString
        }
        label
        bodyRawField {
          getString
        }
      }
      ... on NodeAcls6Activities {
        fieldActivityIdRawField {
          getString
        }
        label
        bodyRawField {
          getString
        }
      }
    }
  }
}
""";
