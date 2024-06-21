import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:noteable/CreateNote.dart';
import 'package:noteable/ViewNote.dart';

import 'ObjectBoxEntity.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  final noteBox = objectbox.store.box<Note>();
  final List<QuillController> _quillscontroller = [];

  void _reset() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final notes = noteBox.getAll(); //Get all notes from ObjectBox DB
    final ButtonStyle style = TextButton.styleFrom(
      //Style for the Icon button
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );

    void removeNote(int id) {
      //Removing the entity at the aforementioned id value
      setState(() {
        noteBox.remove(id);
      });

      Navigator.of(context).pop();
    }

    //Creates a new controller for each Note to be displayed and drops the document data for each in the designated controller
    QuillController newController(int index, String description) {
      _quillscontroller.add(QuillController.basic());

      var jsonText = jsonDecode(description);
      Document docData = Document.fromJson(jsonText);
      _quillscontroller[index].document = docData;
      _quillscontroller[index].readOnly = true;
      return _quillscontroller[index];
    }

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            //Icon on the App bar top left
            style: style,
            onPressed: () {
              _reset();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView.builder(
          //Listview for all the notes on the page
          itemCount: notes.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (BuildContext context, int index) {
            return Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Container(
                      //Contains the overall note
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                      child: GestureDetector(
                        //Gesture for double tap to view the note in edit mode
                        onDoubleTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewNotePage(
                              title: 'Noteable Notes',
                              quillControllerData: newController(
                                  index, notes[index].description),
                              indexData: notes[index].id,
                              noteTitle: notes[index].title,
                            ),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Container(
                                //Contains the title
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Flexible(
                                      child: Text(
                                        notes[index].title,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                        onPressed: () => showDialog<String>(
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  AlertDialog(
                                                title:
                                                    const Text('Delete Note'),
                                                content: const Text(
                                                    'Do you want to delete this note?'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () => removeNote(
                                                        notes[index].id),
                                                    child: const Text('YES'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('NO'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        icon: const Icon(Icons.delete))
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 9,
                              child: QuillEditor.basic(
                                //Contains the editor that holds the note
                                configurations: QuillEditorConfigurations(
                                  expands: false,
                                  controller: newController(
                                      index, notes[index].description),
                                  sharedConfigurations:
                                      const QuillSharedConfigurations(
                                    locale: Locale('en'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _reset();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const CreateNotePage(title: 'Noteable Notes'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
