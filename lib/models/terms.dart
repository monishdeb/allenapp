/* Term - a model class that stores a allen cognitive level taxonomy term from Drupal site

  id - a number to allow location of the taxonomy term within Drupal
  label - a string representing the label of the term as in Drupal
  colour - a string representing the hex code associated with the term for display on chart
*/

class Term {
  final String id;
  String label;
  String colour;

  Term({required this.id, required this.label, required this.colour});

  // constructor to map GraphQL response object to Term object
  factory Term.fromMap(Map<String, dynamic> map, bool isOffline) {
    String termColour;
    if (!isOffline) {
      termColour = map['fieldLevelColourRawField']?['getString'];
    }
    else {
      termColour = map['colour'] ?? '';
    }

    // colour is defaulted to white if not found in GraphQL response
    if (termColour.isEmpty) {
      termColour = "#ffffff";
    }
    if (isOffline) {
      return Term(
        id: map['id'].toString(),
        label: map['title'].toString(),
        colour: termColour,
      );
    }
    else {
      return Term(
        id: map['id'] as String,
        label: map['label'] as String,
        colour: termColour,
      );
    }
  }
}
