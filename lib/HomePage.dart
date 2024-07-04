import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:noteable/CreateNote.dart';
import 'package:noteable/ViewNote.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late Color selectedColor = ColorSeed.baseColor.color;
  Brightness selectedBrightness = Brightness.light;
  late bool selectSort = false; //for the direction of the sort
  late bool setNoteLayout = true;
  BannerAd? _bannerAd;

  final adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  void _reset() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    BannerAd(
      adUnitId: adUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();

    preferencesData(); //Initialises the colour based on persisted data
  }

  void preferencesData() async {
    final prefs = await SharedPreferences.getInstance();

    //Sets the colour of theme based on saved values
    int? color = prefs.getInt('color') ??
        ColorSeed
            .baseColor.color.value; //gets int or if null sets to original value
    color.toInt();
    selectedColor = Color(color);

    bool? boolean = prefs.getBool('setNoteLayout');
    setNoteLayout = boolean ?? true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Note> notes = noteBox.getAll(); //Get all notes from ObjectBox DB
    late List<bool> checkFavourited = [];
    final ButtonStyle style = TextButton.styleFrom(
      //Style for the Icon button
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );

    /*Initialises the sort every build
     */
    void initNotes() {
      //Sets favourites to the front of each sort
      if (selectSort) {
        notes.sort((a, b) {
          if (a.favourited) {
            return 1;
          }
          return -1;
        });
      } else {
        notes.sort((a, b) {
          if (b.favourited) {
            return 1;
          }
          return -1;
        });
      }
    }

    initNotes();

    //Function to return sort direction
    void changeSortDirection() {
      if (selectSort == true) {
        selectSort = false;
      } else {
        selectSort = true;
      }
      setState(() {});
    }

    void addFavouritesToStart(int index) {
      if (notes[index].favourited == false) {
        notes[index].favourited = true;
        noteBox.put(notes[index]);
      } else {
        notes[index].favourited = false; //Sets the opposite value

        noteBox.put(notes[index]); //Updates the DB
      }
      setState(() {});
    }

    void removeNote(int id) {
      //Removing the entity at the aforementioned id value
      noteBox.remove(id);
      setState(() {});
    }

    void setColorPrefs(Color selectedColor) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('color', selectedColor.value);
    }

    Future<void> setNoteLayoutPrefs(bool boolLayout) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('setNoteLayout', boolLayout);
    }

    void changeNoteLayout() {
      if (setNoteLayout) {
        setNoteLayout = false;
      } else {
        setNoteLayout = true;
      }
      setNoteLayoutPrefs(setNoteLayout);
      setState(() {});
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: selectedColor,
          brightness: selectedBrightness,
        ),
      ),
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              Row(
                children: <Widget>[
                  MenuAnchor(
                    builder: (BuildContext context, MenuController controller,
                        Widget? widget) {
                      //Has a controller to go through the items in the menu list
                      return IconButton(
                        //Iconbutton to produce icon for the menu
                        icon: Icon(Icons.circle, color: selectedColor),
                        onPressed: () {
                          setState(() {
                            if (!controller.isOpen) {
                              //Checks if the menu is open
                              controller.open();
                            }
                          });
                        },
                      );
                    },
                    menuChildren: List<Widget>.generate(
                      //generates a list of items corresponding to color
                      ColorSeed.values
                          .length, //sets it to the length of the colorseed values
                      (int index) {
                        final Color itemColor = ColorSeed.values[index]
                            .color; //Sets a value of color to the icon in the list
                        return MenuItemButton(
                          leadingIcon: selectedColor ==
                                  ColorSeed.values[index].color
                              ? Icon(Icons.circle,
                                  color:
                                      itemColor) //the filled colour for the selected icon
                              : Icon(
                                  Icons
                                      .circle_outlined, //the rest of the colours get this outline
                                  color: itemColor),
                          onPressed: () {
                            const snackBarColour = SnackBar(
                              content: Text("Colour Selected"),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBarColour);
                            setState(() {
                              selectedColor =
                                  itemColor; //change state so item colour is built again
                            });
                            setColorPrefs(selectedColor);
                          },
                          child: Text(ColorSeed.values[index]
                              .label), //Adds a text to the side representing the colour
                        );
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      changeSortDirection();
                      const snackBarSort = SnackBar(
                        content: Text("Resorted"),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBarSort);
                    },
                    icon: const Icon(Icons.sort),
                  ),
                  IconButton(
                    //Icon on the App bar top left
                    style: style,
                    onPressed: () {
                      changeNoteLayout();
                    },
                    icon: const Icon(Icons.change_circle),
                  ),
                ],
              ),
            ],
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
          ),
          body: Center(
            child: Column(
              children: <Widget>[
                Expanded(
                  //For the main notes except the favourites
                  child: (setNoteLayout == true)
                      ? ListView.builder(
                          //Listview for all the notes on the page
                          itemCount: notes.length,
                          reverse: selectSort,
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
                                      height:
                                          MediaQuery.of(context).size.height,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                      ),
                                      child: GestureDetector(
                                        //Gesture for double tap to view the note in edit mode
                                        onDoubleTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ViewNotePage(
                                              title: 'Noteable Notes',
                                              quillControllerData:
                                                  newController(index,
                                                      notes[index].description),
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
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .inversePrimary,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: <Widget>[
                                                    IconButton(
                                                      onPressed: () =>
                                                          addFavouritesToStart(
                                                              index),
                                                      icon: Icon(
                                                        Icons.star,
                                                        color: notes[index]
                                                                .favourited
                                                            ? Colors.amberAccent
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        notes[index].title,
                                                        textAlign:
                                                            TextAlign.left,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                        onPressed:
                                                            () => showDialog<
                                                                    String>(
                                                                  context:
                                                                      context,
                                                                  builder: (BuildContext
                                                                          context) =>
                                                                      AlertDialog(
                                                                    title: const Text(
                                                                        'Delete Note'),
                                                                    content:
                                                                        const Text(
                                                                            'Do you want to delete this note?'),
                                                                    actions: <Widget>[
                                                                      TextButton(
                                                                        onPressed:
                                                                            () =>
                                                                                {
                                                                          removeNote(
                                                                              notes[index].id),
                                                                          Navigator.of(context)
                                                                              .pop(),
                                                                        },
                                                                        child: const Text(
                                                                            'YES'),
                                                                      ),
                                                                      TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        },
                                                                        child: const Text(
                                                                            'NO'),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                        icon: const Icon(
                                                            Icons.delete))
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 9,
                                              child: QuillEditor.basic(
                                                //Contains the editor that holds the note
                                                configurations:
                                                    QuillEditorConfigurations(
                                                  expands: false,
                                                  controller: newController(
                                                      index,
                                                      notes[index].description),
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
                        )
                      : Align(
                          alignment: Alignment.topCenter,
                          child: ListView.builder(
                            //Listview for all the notes on the page
                            itemCount: notes.length,
                            shrinkWrap: true,
                            reverse: selectSort,
                            scrollDirection: Axis.vertical,
                            itemBuilder: (BuildContext context, int index) {
                              return Column(
                                children: <Widget>[
                                  Card(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    child: ListTile(
                                      dense: true,
                                      leading: IconButton(
                                        onPressed: () =>
                                            addFavouritesToStart(index),
                                        icon: Icon(
                                          Icons.star,
                                          color: notes[index].favourited
                                              ? Colors.amberAccent
                                              : Colors.white,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        onPressed: () => showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              AlertDialog(
                                            title: const Text('Delete Note'),
                                            content: const Text(
                                                'Do you want to delete this note?'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () => {
                                                  removeNote(notes[index].id),
                                                  Navigator.of(context).pop(),
                                                },
                                                child: const Text('YES'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('NO'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        icon: const Icon(Icons.delete),
                                      ),
                                      title: Text(notes[index].title),
                                      subtitle: QuillEditor.basic(
                                        //Contains the editor that holds the note
                                        configurations:
                                            QuillEditorConfigurations(
                                          expands: false,
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              15,
                                          controller: newController(
                                              index, notes[index].description),
                                          sharedConfigurations:
                                              const QuillSharedConfigurations(
                                            locale: Locale('en'),
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
                ),
                SafeArea(
                  child: SizedBox(
                    width: AdSize.banner.width.toDouble(),
                    height: AdSize.banner.height.toDouble(),
                    child: _bannerAd == null
                        // Nothing to render yet.
                        ? const SizedBox()
                        // The actual ad.
                        : AdWidget(ad: _bannerAd!),
                  ),
                )
              ],
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
        ),
      ),
    );
  }
}

enum ColorSeed {
  baseColor('Purple', Color(0xff6750a4)),
  indigo('Indigo', Colors.indigo),
  blue('Blue', Colors.blue),
  teal('Teal', Colors.teal),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  orange('Orange', Colors.orange),
  deepOrange('Deep Orange', Colors.deepOrange),
  pink('Pink', Colors.pink),
  brightBlue('Bright Blue', Color(0xFF0000FF)),
  brightGreen('Bright Green', Color(0xFF00FF00)),
  brightRed('Bright Red', Color(0xFFFF0000));

  const ColorSeed(this.label, this.color);
  final String label;
  final Color color;
}
