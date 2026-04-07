/* HighlightedNote - a model class that stores a highlighted section of text within the app 
and the note associated with it

  start - an integer representing the starting index of the highlighted text
  end - an integer representing the ending index of the highlighted text
  selectedText - a string representing the highlighted text
  note - a string representing the note associated with the highlighted text
  nodeId - a number to allow location of the content node within Drupal
*/

class HighlightedNote {
  final int start;
  final int end;
  final String selectedText;
  final String note;
  final String nodeId;

  HighlightedNote(
      {required this.start,
      required this.end,
      required this.selectedText,
      required this.note,
      required this.nodeId});

  @override
  String toString() {
    return 'HighlightedNote{start: $start, end: $end, text: $selectedText, note: "$note", node id: $nodeId}';
  }
}
