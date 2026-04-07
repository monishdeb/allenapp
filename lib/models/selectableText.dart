import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/query.dart';
import '../models/highlights.dart';
import '../services/auth.dart';
import '../services/Offline.dart';

class SelectableAllenText extends StatefulWidget {
  final String? currentNodeId;
  final String text;
  final List<Map<String, dynamic>> notes;
  final bool isOffline;

  const SelectableAllenText({
    Key? key,
    required this.text,
    this.currentNodeId,
    required this.notes,
    required this.isOffline,
  }): super(key: key);

  @override
  _SelectableAllenTextState createState() => _SelectableAllenTextState();
}

class _SelectableAllenTextState extends State<SelectableAllenText> {
  List<Map<String, dynamic>> notes = [];
  final SelectionListenerNotifier _selectionNotifier = SelectionListenerNotifier();
  SelectableRegionSelectionStatus? _selectableRegionStatus;
  ValueListenable<SelectableRegionSelectionStatus>? _selectableRegionScope;
  String selectedText = '';
  bool isAppOffline = false;
  String widgetText = '';

  @override
  void initState() {
    isAppOffline = widget.isOffline;
    notes = widget.notes;
    widgetText = widget.text;
    super.initState();
  }
  void _handleOnSelectableRegionChanged() {
    if (_selectableRegionScope == null) {
      return;
    }
    _handleOnSelectionStateChanged.call(_selectableRegionScope!.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectableRegionScope?.removeListener(_handleOnSelectableRegionChanged);
    _selectableRegionScope = SelectableRegionSelectionStatusScope.maybeOf(context);
    _selectableRegionScope?.addListener(_handleOnSelectableRegionChanged);
  }

  @override
  void dispose() {
    _selectableRegionStatus = null;
    _selectableRegionScope?.removeListener(_handleOnSelectableRegionChanged);
    _selectableRegionScope = null;
    _selectionNotifier.dispose();
    super.dispose();
  }

  void _handleOnSelectionStateChanged(SelectableRegionSelectionStatus status) {
    setState(() {
      _selectableRegionStatus = status;
    });
  }

  Future<void> saveHighlightedNote(HighlightedNote highlightedNote) async {
    List<Map<String, dynamic>> newNotes = List.from(notes);
    if (isAppOffline) {
      await Offline().saveNote(int.parse(highlightedNote.nodeId), highlightedNote.note, highlightedNote.selectedText, highlightedNote.start, highlightedNote.end, db).then((result) {
        Map<String, dynamic> newNote = {
          'id': result,
          'start_position': highlightedNote.start,
          'end_position': highlightedNote.end,
          'note': highlightedNote.note,
          'selected_text': highlightedNote.selectedText,
        };
        newNotes.add(newNote);
        setState(() {
          notes = newNotes;
        });
      });
    }
    else {
      final GraphQLClient graphQLClient = client.value;
      await graphQLClient.mutate(MutationOptions(document: gql(createHighlight),
          variables: {
            'node_id': int.parse(highlightedNote.nodeId),
            'note': highlightedNote.note,
            'highlighted_text': highlightedNote.selectedText,
            'note_start': highlightedNote.start,
            'note_end': highlightedNote.end
          })).then((result) {
        Map<String, dynamic> newNote = {
          'id': result.data?['createCustomHighlight']['customHighlight']['id'],
          'noteStartRawField': {'getString': highlightedNote.start.toString()},
          'noteEndRawField': {'getString': highlightedNote.end.toString()},
          'label': highlightedNote.note,
          'highlighted_text': highlightedNote.selectedText,
        };
        newNotes.add(newNote);
        setState(() {
          notes = newNotes;
        });
      });
    }
  }

  // function that shows popup when user is adding a note to highlighted text
  void _showNoteDialog(
      BuildContext context, String currentNodeId, originalText) {
    final TextEditingController noteController = TextEditingController();
    int start = _selectionNotifier.selection.range?.startOffset ?? 0;
    int end = _selectionNotifier.selection.range?.endOffset ?? 0;
    String text = selectedText;
    var actualStart = originalText.indexOf(selectedText) ?? 0;
    int difference = 0;
    if (start < actualStart) {
      difference = actualStart - start;
    }
    else {
      difference = int.parse((start - actualStart).toString());
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Note'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(hintText: 'Enter your note here'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String note = noteController.text;
                final HighlightedNote highlightedNote = HighlightedNote(
                  start: start + difference,
                  end: end + difference,
                  selectedText: text,
                  note: note,
                  nodeId: currentNodeId,
                );
                saveHighlightedNote(highlightedNote);
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showNote(BuildContext context, String? noteId) {
    if ((noteId ?? '').isNotEmpty) {
      for (var i = 0; i < notes.length; i++) {
        if (notes[i]['id'].toString() == noteId) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Saved Note"),
                content: Text((isAppOffline ? notes[i]['note'] : notes[i]['label']) ?? ''),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  )
                ]
              );
            }
          );
        }
      }
    }
  }

  _addNotesToText(text) {
    var finalText = '';
    var start = 0;
    if (notes.length > 0) {
      var originalText = text;
      for (var i = 0; i < notes.length; i++) {
        if (isAppOffline) {
          if (notes[i]['start_position'] != '' && (notes[i]['start_position'] ?? 1) > 0) {
            var note_start = notes[i]['start_position'] ?? 1;
            var note_end = notes[i]['end_position'] ?? 1;
            if (note_end > originalText.length) {
              note_end = originalText.length;
            }
            if (note_start > originalText.length) {
              note_start = originalText.length;
            }
            var workInProgressText = originalText.substring(start, note_start) +
              '<span class="icon" id="' + notes[i]['id'].toString() +
              '"></span><span class="selected">' + originalText.substring(note_start, note_end) +
              '</span>' + originalText.substring(note_end);
            originalText = workInProgressText;
          }
        }
        else {
          if (notes[i]['noteStartRawField']['getString'] != '' &&
              int.parse(notes[i]['noteStartRawField']['getString'] ?? '0') > 0) {
            var note_start = int.parse(notes[i]['noteStartRawField']['getString'] ?? '1');
            var note_end = int.parse(
                notes[i]['noteEndRawField']['getString'] ?? '0');
            if (note_end > originalText.length) {
              note_end = originalText.length;
            }
            if (note_start > originalText.length) {
              note_start = originalText.length;
            }
            var workInProgressText = originalText.substring(start,
                note_start) +
                '<span class="icon" id="' + notes[i]['id'] +
                '"></span><span class="selected">' + originalText.substring(
                note_start,
                note_end) +
                '</span>' + originalText.substring(note_end);
            originalText = workInProgressText;
          }
        }
      }
      finalText = originalText;
    }
    else {
      finalText = text;
    }
    setState(() {
      widgetText = finalText;
    });
    return finalText;
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: SelectionListener(
        selectionNotifier: _selectionNotifier,
          child: HtmlWidget(
            _addNotesToText(widget.text),
            customStylesBuilder: (element) {
              if (element.classes.contains('selected')) {
                return {'background-color': 'rgb(255,255,0,0.2)',};
              }
              return null;
            },
            customWidgetBuilder: (element) {
              if (element.classes.contains('icon')) {
                return InlineCustomWidget(child: SizedBox(height: 20, width: 24, child: IconButton(onPressed: () => {_showNote(context, element.attributes['id'])}, icon: Icon(Icons.info), iconSize: 14)));
              }
            },
            textStyle: TextStyle(fontSize: 18),
          )
        ),
        onSelectionChanged: (text) {
          setState(() {
            selectedText = text?.plainText ?? '';
          });
        },
        contextMenuBuilder: (
          context,
          selectableRegionState
        ) {
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: selectableRegionState.contextMenuAnchors,
            buttonItems: <ContextMenuButtonItem>[
              ...selectableRegionState.contextMenuButtonItems,
              ContextMenuButtonItem(
                label: 'Add Note',
                onPressed: () {
                  _showNoteDialog(context, widget.currentNodeId ?? '0', widgetText);
                }
              )
            ],
          );
        }
    );
  }

}