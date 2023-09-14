library emoji_picker;

import 'dart:io';
import 'dart:math';

import 'package:costv_android/bean/exclusive_relation_bean.dart';
import 'package:costv_android/emoji/bean/emoji_bean.dart';
import 'package:costv_android/emoji/dialog/epamoji_unlock_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../style/elevated_button_style.dart';
import 'emoji_lists.dart' as emojiList;

/// All the possible categories that [Emoji] can be put into
///
/// All [Category] are shown in the keyboard bottombar with the exception of [Category.RECOMMENDED]
/// which only displays when keywords are given
enum Category { EPAMOJI, SMILEYS, ANIMALS, FOODS, TRAVEL, ACTIVITIES, OBJECTS, SYMBOLS, FLAGS }

/// Enum to alter the keyboard button style
enum ButtonMode {
  /// Android button style - gives the button a splash color with ripple effect
  MATERIAL,

  /// iOS button style - gives the button a fade out effect when pressed
  CUPERTINO
}

/// Callback function for when emoji is selected
///
/// The function returns the selected [Emoji] as well as the [Category] from which it originated
typedef void OnEmojiSelected(Emoji emoji, Category? category);
typedef void OnSelectCategoryChange(Category? selectedCategory);

/// The Emoji Keyboard widget
///
/// This widget displays a grid of [Emoji] sorted by [Category] which the user can horizontally scroll through.
///
/// There is also a bottombar which displays all the possible [Category] and allow the user to quickly switch to that [Category]
class EmojiPicker extends StatefulWidget {
  @override
  _EmojiPickerState createState() => new _EmojiPickerState();

  /// Number of columns in keyboard grid
  int columns;

  /// Number of rows in keyboard grid
  int rows;

  /// The currently selected [Category]
  ///
  /// This [Category] will have its button in the bottombar darkened
  Category? selectedCategory;

  /// The function called when the emoji is selected
  OnEmojiSelected onEmojiSelected;

  OnSelectCategoryChange onSelectCategoryChange;

  /// The background color of the keyboard
  Color bgColor;

  /// The color of the keyboard page indicator
  Color indicatorColor;

  Color _defaultBgColor = Color.fromRGBO(242, 242, 242, 1);

  /// Determines the icon to display for each [Category]
  CategoryIcons categoryIcons;

  /// Determines the style given to the keyboard keys
  ButtonMode buttonMode;

  String level;

  EmojiPicker({
    Key? key,
    required this.onEmojiSelected,
    required this.onSelectCategoryChange,
    this.columns = 7,
    this.rows = 3,
    this.selectedCategory,
    required this.bgColor,
    this.indicatorColor = Colors.blue,
    required this.categoryIcons,
    this.buttonMode = ButtonMode.MATERIAL,
    this.level = ExclusiveRelationItemBean.levelLock,
  }) : super(key: key) {
    if (selectedCategory == null) {
      if (level == ExclusiveRelationItemBean.levelLock) {
        selectedCategory = Category.SMILEYS;
      } else {
        selectedCategory = Category.EPAMOJI;
      }
    }
    if (this.bgColor == null) {
      bgColor = _defaultBgColor;
    }
    if (categoryIcons == null) {
      categoryIcons = CategoryIcons();
    }
  }
}

/// Class that defines the icon representing a [Category]
class CategoryIcon {
  /// The icon to represent the category
  IconData icon;

  /// The default color of the icon
  Color? color;

  /// The color of the icon once the category is selected
  Color? selectedColor;

  CategoryIcon({required this.icon, this.color, this.selectedColor}) {
    if (this.color == null) {
      this.color = Color.fromRGBO(211, 211, 211, 1);
    }
    if (this.selectedColor == null) {
      this.selectedColor = Color.fromRGBO(178, 178, 178, 1);
    }
  }
}

/// Class used to define all the [CategoryIcon] shown for each [Category]
///
/// This allows the keyboard to be personalized by changing icons shown.
/// If a [CategoryIcon] is set as null or not defined during initialization, the default icons will be used instead
class CategoryIcons {
  /// Widget for [Category.EPAMOJI]
  Widget? epamoji;

  /// Icon for [Category.SMILEYS]
  CategoryIcon? smileyIcon;

  /// Icon for [Category.ANIMALS]
  CategoryIcon? animalIcon;

  /// Icon for [Category.FOODS]
  CategoryIcon? foodIcon;

  /// Icon for [Category.TRAVEL]
  CategoryIcon? travelIcon;

  /// Icon for [Category.ACTIVITIES]
  CategoryIcon? activityIcon;

  /// Icon for [Category.OBJECTS]
  CategoryIcon? objectIcon;

  /// Icon for [Category.SYMBOLS]
  CategoryIcon? symbolIcon;

  /// Icon for [Category.FLAGS]
  CategoryIcon? flagIcon;

  CategoryIcons(
      {this.epamoji,
      this.smileyIcon,
      this.animalIcon,
      this.foodIcon,
      this.travelIcon,
      this.activityIcon,
      this.objectIcon,
      this.symbolIcon,
      this.flagIcon}) {
    if (smileyIcon == null) {
      smileyIcon = CategoryIcon(icon: Icons.tag_faces);
    }
    if (animalIcon == null) {
      animalIcon = CategoryIcon(icon: Icons.pets);
    }
    if (foodIcon == null) {
      foodIcon = CategoryIcon(icon: Icons.fastfood);
    }
    if (travelIcon == null) {
      travelIcon = CategoryIcon(icon: Icons.location_city);
    }
    if (activityIcon == null) {
      activityIcon = CategoryIcon(icon: Icons.directions_run);
    }
    if (objectIcon == null) {
      objectIcon = CategoryIcon(icon: Icons.lightbulb_outline);
    }
    if (symbolIcon == null) {
      symbolIcon = CategoryIcon(icon: Icons.euro_symbol);
    }
    if (flagIcon == null) {
      flagIcon = CategoryIcon(icon: Icons.flag);
    }
  }
}

/// A class to store data for each individual emoji
class Emoji {
  /// The name or description for this emoji
  final String name;

  /// The unicode string for this emoji
  ///
  /// This is the string that should be displayed to view the emoji
  final String emoji;

  Emoji({required this.name, required this.emoji});

  @override
  String toString() {
    return "Name: " + name + ", Emoji: " + emoji;
  }
}

class _EmojiPickerState extends State<EmojiPicker> {
  static const platform = const MethodChannel("emoji_picker");

  List<Widget> pages = [];

  int epamojiPagesNum = 0;
  int smileyPagesNum = 0;
  int animalPagesNum = 0;
  int foodPagesNum = 0;
  int travelPagesNum = 0;
  int activityPagesNum = 0;
  int objectPagesNum = 0;
  int symbolPagesNum = 0;
  int flagPagesNum = 0;
  List<String> allNames = [];

  Map<String, EmojiBean> epamojiMap = new Map();
  Map<String, String> smileyMap = new Map();
  Map<String, String> animalMap = new Map();
  Map<String, String> foodMap = new Map();
  Map<String, String> travelMap = new Map();
  Map<String, String> activityMap = new Map();
  Map<String, String> objectMap = new Map();
  Map<String, String> symbolMap = new Map();
  Map<String, String> flagMap = new Map();

  bool loaded = false;
  EpamojiUnlockDialog? _epamojiUnlockDialog;

  @override
  void initState() {
    super.initState();
    updateEmojis().then((_) {
      loaded = true;
    });
  }

  Future<bool> _isEmojiAvailable(String emoji) async {
    if (Platform.isAndroid) {
      bool isAvailable;
      try {
        isAvailable = await platform.invokeMethod("isAvailable", {"emoji": emoji});
      } on PlatformException catch (_) {
        isAvailable = false;
      }
      return isAvailable;
    } else {
      return true;
    }
  }

  Future<Map<String, String>> getAvailableEmojis(Map<String, String> map) async {
    Map<String, String> newMap = Map<String, String>();

    for (String key in map.keys) {
      var value = map[key];
      if (value == null) continue;
      bool isAvailable = await _isEmojiAvailable(value);
      if (isAvailable) {
        newMap[key] = value;
      }
    }

    return newMap;
  }

  Future updateEmojis() async {
    if (widget.level != ExclusiveRelationItemBean.levelLock) {
      epamojiMap.clear();
      epamojiMap.addAll(emojiList.epamojis);
      if (widget.level == ExclusiveRelationItemBean.levelUnlockOne) {
        epamojiMap['epamoji_smile_hearts']?.isLock = false;
      } else if (widget.level == ExclusiveRelationItemBean.levelUnlockAll) {
        epamojiMap.forEach((key, emojiBean) {
          emojiBean.isLock = false;
        });
      }
      allNames.addAll(epamojiMap.keys);
    }
    smileyMap = await getAvailableEmojis(emojiList.smileys);
    animalMap = await getAvailableEmojis(emojiList.animals);
    foodMap = await getAvailableEmojis(emojiList.foods);
    travelMap = await getAvailableEmojis(emojiList.travel);
    activityMap = await getAvailableEmojis(emojiList.activities);
    objectMap = await getAvailableEmojis(emojiList.objects);
    symbolMap = await getAvailableEmojis(emojiList.symbols);
    flagMap = await getAvailableEmojis(emojiList.flags);

    allNames.addAll(smileyMap.keys);
    allNames.addAll(animalMap.keys);
    allNames.addAll(foodMap.keys);
    allNames.addAll(travelMap.keys);
    allNames.addAll(activityMap.keys);
    allNames.addAll(objectMap.keys);
    allNames.addAll(symbolMap.keys);
    allNames.addAll(flagMap.keys);

    if (context == null) {
      return;
    }
    List<Widget> epamojiPages = [];
    if (widget.level != ExclusiveRelationItemBean.levelLock) {
      epamojiPagesNum = 1;
      epamojiPages.add(Container(
        color: widget.bgColor,
        alignment: Alignment.center,
        child: GridView.count(
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          primary: true,
          crossAxisCount: 4,
          children: List.generate(epamojiMap.length, (index) {
            if (index < epamojiMap.values.toList().length) {
              EmojiBean emojiBean = epamojiMap.values.toList()[index];
              String imgUrl;
              if (emojiBean.isLock) {
                imgUrl = emojiBean.imgUrlLock;
              } else {
                imgUrl = emojiBean.imgUrl;
              }
              return InkWell(
                onTap: () {
                  if (emojiBean.isLock) {
                    if (_epamojiUnlockDialog == null) {
                      _epamojiUnlockDialog = EpamojiUnlockDialog();
                    }
                    _epamojiUnlockDialog!.showEpamojiUnlockDialog(context);
                  } else {
                    widget.onEmojiSelected(
                        Emoji(name: epamojiMap.keys.toList()[index], emoji: epamojiMap.values.toList()[index].value), widget.selectedCategory);
                  }
                },
                child: Center(
                  child: Image.asset(imgUrl, width: MediaQuery.of(context).size.width / 6, fit: BoxFit.fitWidth),
                ),
              );
            } else {
              return Container();
            }
          }),
        ),
      ));
    } else {
      epamojiPagesNum = 0;
    }

    if (context == null) {
      return;
    }
    smileyPagesNum = (smileyMap.values.toList().length / (widget.rows * widget.columns)).ceil();
    List<Widget> smileyPages = [];
    for (var i = 0; i < smileyPagesNum; i++) {
      smileyPages.add(Container(
        color: widget.bgColor,
        alignment: Alignment.center,
        child: GridView.count(
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          primary: true,
          crossAxisCount: widget.columns,
          children: List.generate(widget.rows * widget.columns, (index) {
            if (index + (widget.columns * widget.rows * i) < smileyMap.values.toList().length) {
              String emojiTxt = smileyMap.values.toList()[index + (widget.columns * widget.rows * i)];

              switch (widget.buttonMode) {
                case ButtonMode.MATERIAL:
                  return Center(
                      child: ElevatedButton(
                    child: Center(
                      child: Text(
                        emojiTxt,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: smileyMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: smileyMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                case ButtonMode.CUPERTINO:
                  return Center(
                      child: CupertinoButton(
                    pressedOpacity: 0.4,
                    padding: EdgeInsets.all(0),
                    child: Center(
                      child: Text(
                        emojiTxt,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: smileyMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: smileyMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                default:
                  return Container();
              }
            } else {
              return Container();
            }
          }),
        ),
      ));
    }

    if (context == null) {
      return;
    }
    animalPagesNum = (animalMap.values.toList().length / (widget.rows * widget.columns)).ceil();
    List<Widget> animalPages = [];
    for (var i = 0; i < animalPagesNum; i++) {
      animalPages.add(Container(
        color: widget.bgColor,
        alignment: Alignment.center,
        child: GridView.count(
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          primary: true,
          crossAxisCount: widget.columns,
          children: List.generate(widget.rows * widget.columns, (index) {
            if (index + (widget.columns * widget.rows * i) < animalMap.values.toList().length) {
              switch (widget.buttonMode) {
                case ButtonMode.MATERIAL:
                  return Center(
                      child: ElevatedButton(
                    child: Center(
                      child: Text(
                        animalMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: animalMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: animalMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                case ButtonMode.CUPERTINO:
                  return Center(
                      child: CupertinoButton(
                    pressedOpacity: 0.4,
                    padding: EdgeInsets.all(0),
                    child: Center(
                      child: Text(
                        animalMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: animalMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: animalMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                default:
                  return Container();
                  break;
              }
            } else {
              return Container();
            }
          }),
        ),
      ));
    }

    if (context == null) {
      return;
    }
    foodPagesNum = (foodMap.values.toList().length / (widget.rows * widget.columns)).ceil();
    List<Widget> foodPages = [];
    for (var i = 0; i < foodPagesNum; i++) {
      foodPages.add(Container(
        color: widget.bgColor,
        alignment: Alignment.center,
        child: GridView.count(
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          primary: true,
          crossAxisCount: widget.columns,
          children: List.generate(widget.rows * widget.columns, (index) {
            if (index + (widget.columns * widget.rows * i) < foodMap.values.toList().length) {
              switch (widget.buttonMode) {
                case ButtonMode.MATERIAL:
                  return Center(
                      child: ElevatedButton(
                    child: Center(
                      child: Text(
                        foodMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: foodMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: foodMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                case ButtonMode.CUPERTINO:
                  return Center(
                      child: CupertinoButton(
                    pressedOpacity: 0.4,
                    padding: EdgeInsets.all(0),
                    child: Center(
                      child: Text(
                        foodMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: foodMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: foodMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                default:
                  return Container();
                  break;
              }
            } else {
              return Container();
            }
          }),
        ),
      ));
    }

    if (context == null) {
      return;
    }
    travelPagesNum = (travelMap.values.toList().length / (widget.rows * widget.columns)).ceil();
    List<Widget> travelPages = [];
    for (var i = 0; i < travelPagesNum; i++) {
      travelPages.add(Container(
        color: widget.bgColor,
        alignment: Alignment.center,
        child: GridView.count(
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          primary: true,
          crossAxisCount: widget.columns,
          children: List.generate(widget.rows * widget.columns, (index) {
            if (index + (widget.columns * widget.rows * i) < travelMap.values.toList().length) {
              switch (widget.buttonMode) {
                case ButtonMode.MATERIAL:
                  return Center(
                      child: ElevatedButton(
                    child: Center(
                      child: Text(
                        travelMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: travelMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: travelMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                case ButtonMode.CUPERTINO:
                  return Center(
                      child: CupertinoButton(
                    pressedOpacity: 0.4,
                    padding: EdgeInsets.all(0),
                    child: Center(
                      child: Text(
                        travelMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: travelMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: travelMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                default:
                  return Container();
                  break;
              }
            } else {
              return Container();
            }
          }),
        ),
      ));
    }

    if (context == null) {
      return;
    }
    activityPagesNum = (activityMap.values.toList().length / (widget.rows * widget.columns)).ceil();
    List<Widget> activityPages = [];
    for (var i = 0; i < activityPagesNum; i++) {
      activityPages.add(Container(
        color: widget.bgColor,
        alignment: Alignment.center,
        child: GridView.count(
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          primary: true,
          crossAxisCount: widget.columns,
          children: List.generate(widget.rows * widget.columns, (index) {
            if (index + (widget.columns * widget.rows * i) < activityMap.values.toList().length) {
              String emojiTxt = activityMap.values.toList()[index + (widget.columns * widget.rows * i)];

              switch (widget.buttonMode) {
                case ButtonMode.MATERIAL:
                  return Center(
                      child: ElevatedButton(
                    child: Center(
                      child: Text(
                        activityMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: activityMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: activityMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                case ButtonMode.CUPERTINO:
                  return Center(
                      child: CupertinoButton(
                    pressedOpacity: 0.4,
                    padding: EdgeInsets.all(0),
                    child: Center(
                      child: Text(
                        emojiTxt,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: activityMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: activityMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                default:
                  return Container();
                  break;
              }
            } else {
              return Container();
            }
          }),
        ),
      ));
    }

    if (context == null) {
      return;
    }
    objectPagesNum = (objectMap.values.toList().length / (widget.rows * widget.columns)).ceil();
    List<Widget> objectPages = [];
    for (var i = 0; i < objectPagesNum; i++) {
      objectPages.add(Container(
        color: widget.bgColor,
        alignment: Alignment.center,
        child: GridView.count(
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          primary: true,
          crossAxisCount: widget.columns,
          children: List.generate(widget.rows * widget.columns, (index) {
            if (index + (widget.columns * widget.rows * i) < objectMap.values.toList().length) {
              switch (widget.buttonMode) {
                case ButtonMode.MATERIAL:
                  return Center(
                      child: ElevatedButton(
                    child: Center(
                      child: Text(
                        objectMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: objectMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: objectMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                case ButtonMode.CUPERTINO:
                  return Center(
                      child: CupertinoButton(
                    pressedOpacity: 0.4,
                    padding: EdgeInsets.all(0),
                    child: Center(
                      child: Text(
                        objectMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: objectMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: objectMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                default:
                  return Container();
                  break;
              }
            } else {
              return Container();
            }
          }),
        ),
      ));
    }

    if (context == null) {
      return;
    }
    symbolPagesNum = (symbolMap.values.toList().length / (widget.rows * widget.columns)).ceil();
    List<Widget> symbolPages = [];
    for (var i = 0; i < symbolPagesNum; i++) {
      symbolPages.add(Container(
        color: widget.bgColor,
        alignment: Alignment.center,
        child: GridView.count(
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          primary: true,
          crossAxisCount: widget.columns,
          children: List.generate(widget.rows * widget.columns, (index) {
            if (index + (widget.columns * widget.rows * i) < symbolMap.values.toList().length) {
              switch (widget.buttonMode) {
                case ButtonMode.MATERIAL:
                  return Center(
                      child: ElevatedButton(
                    child: Center(
                      child: Text(
                        symbolMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: symbolMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: symbolMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                case ButtonMode.CUPERTINO:
                  return Center(
                      child: CupertinoButton(
                    pressedOpacity: 0.4,
                    padding: EdgeInsets.all(0),
                    child: Center(
                      child: Text(
                        symbolMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: symbolMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: symbolMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                default:
                  return Container();
                  break;
              }
            } else {
              return Container();
            }
          }),
        ),
      ));
    }

    if (context == null) {
      return;
    }
    flagPagesNum = (flagMap.values.toList().length / (widget.rows * widget.columns)).ceil();
    List<Widget> flagPages = [];
    for (var i = 0; i < flagPagesNum; i++) {
      flagPages.add(Container(
        color: widget.bgColor,
        alignment: Alignment.center,
        child: GridView.count(
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          primary: true,
          crossAxisCount: widget.columns,
          children: List.generate(widget.rows * widget.columns, (index) {
            if (index + (widget.columns * widget.rows * i) < flagMap.values.toList().length) {
              switch (widget.buttonMode) {
                case ButtonMode.MATERIAL:
                  return Center(
                      child: ElevatedButton(
                    child: Center(
                      child: Text(
                        flagMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: flagMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: flagMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                case ButtonMode.CUPERTINO:
                  return Center(
                      child: CupertinoButton(
                    pressedOpacity: 0.4,
                    padding: EdgeInsets.all(0),
                    child: Center(
                      child: Text(
                        flagMap.values.toList()[index + (widget.columns * widget.rows * i)],
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    onPressed: () {
                      widget.onEmojiSelected(
                          Emoji(
                              name: flagMap.keys.toList()[index + (widget.columns * widget.rows * i)],
                              emoji: flagMap.values.toList()[index + (widget.columns * widget.rows * i)]),
                          widget.selectedCategory);
                    },
                  ));
                  break;
                default:
                  return Container();
                  break;
              }
            } else {
              return Container();
            }
          }),
        ),
      ));
    }

    if (widget.level != ExclusiveRelationItemBean.levelLock) {
      pages.addAll(epamojiPages);
    }
    pages.addAll(smileyPages);
    pages.addAll(animalPages);
    pages.addAll(foodPages);
    pages.addAll(travelPages);
    pages.addAll(activityPages);
    pages.addAll(objectPages);
    pages.addAll(symbolPages);
    pages.addAll(flagPages);
  }

  Widget defaultImageButton(Widget? img) {
    int buttonNumber = 9;
    if (widget.level == ExclusiveRelationItemBean.levelLock) {
      buttonNumber = 8;
    }
    return SizedBox(
      width: MediaQuery.of(context).size.width / buttonNumber,
      height: MediaQuery.of(context).size.width / buttonNumber,
      child: Container(
        color: widget.bgColor,
        child: Center(
          child: img,
        ),
      ),
    );
  }

  Widget defaultButton(CategoryIcon? categoryIcon) {
    int buttonNumber = 9;
    if (widget.level == ExclusiveRelationItemBean.levelLock) {
      buttonNumber = 8;
    }
    return SizedBox(
      width: MediaQuery.of(context).size.width / buttonNumber,
      height: MediaQuery.of(context).size.width / buttonNumber,
      child: Container(
        color: widget.bgColor,
        child: Center(
          child: Icon(
            categoryIcon?.icon,
            size: 22,
            color: categoryIcon?.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loaded) {
      late PageController pageController;
      if (widget.level != ExclusiveRelationItemBean.levelLock && widget.selectedCategory == Category.EPAMOJI) {
        pageController = PageController(initialPage: 0);
      } else if (widget.selectedCategory == Category.SMILEYS) {
        pageController = PageController(initialPage: epamojiPagesNum);
      } else if (widget.selectedCategory == Category.ANIMALS) {
        pageController = PageController(initialPage: smileyPagesNum + epamojiPagesNum);
      } else if (widget.selectedCategory == Category.FOODS) {
        pageController = PageController(initialPage: smileyPagesNum + animalPagesNum + epamojiPagesNum);
      } else if (widget.selectedCategory == Category.TRAVEL) {
        pageController = PageController(initialPage: smileyPagesNum + animalPagesNum + foodPagesNum + epamojiPagesNum);
      } else if (widget.selectedCategory == Category.ACTIVITIES) {
        pageController = PageController(initialPage: smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum + epamojiPagesNum);
      } else if (widget.selectedCategory == Category.OBJECTS) {
        pageController =
            PageController(initialPage: smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum + activityPagesNum + epamojiPagesNum);
      } else if (widget.selectedCategory == Category.SYMBOLS) {
        pageController = PageController(
            initialPage: smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum + activityPagesNum + objectPagesNum + epamojiPagesNum);
      } else if (widget.selectedCategory == Category.FLAGS) {
        pageController = PageController(
            initialPage: smileyPagesNum +
                animalPagesNum +
                foodPagesNum +
                travelPagesNum +
                activityPagesNum +
                objectPagesNum +
                symbolPagesNum +
                epamojiPagesNum);
      }

      pageController.addListener(() {
        setState(() {});
      });
      List<Widget> listWidgetButton = [];
      int buttonNumber = 9;
      if (widget.level != ExclusiveRelationItemBean.levelLock) {
        listWidgetButton.add(SizedBox(
          width: MediaQuery.of(context).size.width / 9,
          height: MediaQuery.of(context).size.width / 9,
          child: widget.buttonMode == ButtonMode.MATERIAL
              ? ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.EPAMOJI ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: widget.categoryIcons.epamoji,
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.EPAMOJI) {
                      return;
                    }
                    pageController.jumpToPage(0);
                  },
                )
              : CupertinoButton(
            pressedOpacity: 0.4,
                  padding: EdgeInsets.all(0),
                  color: widget.selectedCategory == Category.EPAMOJI ? Colors.black12 : Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  child: Center(
                    child: widget.categoryIcons.epamoji,
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.EPAMOJI) {
                      return;
                    }

                    pageController.jumpToPage(0);
                  },
                ),
        ));
      } else {
        buttonNumber = 8;
      }
      listWidgetButton.addAll([
        SizedBox(
          width: MediaQuery.of(context).size.width / buttonNumber,
          height: MediaQuery.of(context).size.width / buttonNumber,
          child: widget.buttonMode == ButtonMode.MATERIAL
              ? ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.SMILEYS ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.smileyIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.SMILEYS
                          ? widget.categoryIcons.smileyIcon?.selectedColor
                          : widget.categoryIcons.smileyIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.SMILEYS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum);
                  },
                )
              : ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.SMILEYS ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.smileyIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.SMILEYS
                          ? widget.categoryIcons.smileyIcon?.selectedColor
                          : widget.categoryIcons.smileyIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.SMILEYS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum);
                  },
                ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / buttonNumber,
          height: MediaQuery.of(context).size.width / buttonNumber,
          child: widget.buttonMode == ButtonMode.MATERIAL
              ? ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.ANIMALS ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.animalIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.ANIMALS
                          ? widget.categoryIcons.animalIcon?.selectedColor
                          : widget.categoryIcons.animalIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.ANIMALS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum);
                  },
                )
              : CupertinoButton(
            pressedOpacity: 0.4,
                  padding: EdgeInsets.all(0),
                  color: widget.selectedCategory == Category.ANIMALS ? Colors.black12 : Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.animalIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.ANIMALS
                          ? widget.categoryIcons.animalIcon?.selectedColor
                          : widget.categoryIcons.animalIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.ANIMALS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum);
                  },
                ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / buttonNumber,
          height: MediaQuery.of(context).size.width / buttonNumber,
          child: widget.buttonMode == ButtonMode.MATERIAL
              ? ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.FOODS ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.foodIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.FOODS
                          ? widget.categoryIcons.foodIcon?.selectedColor
                          : widget.categoryIcons.foodIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.FOODS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum + animalPagesNum);
                  },
                )
              : CupertinoButton(
            pressedOpacity: 0.4,
                  padding: EdgeInsets.all(0),
                  color: widget.selectedCategory == Category.FOODS ? Colors.black12 : Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.foodIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.FOODS
                          ? widget.categoryIcons.foodIcon?.selectedColor
                          : widget.categoryIcons.foodIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.FOODS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum + animalPagesNum);
                  },
                ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / buttonNumber,
          height: MediaQuery.of(context).size.width / buttonNumber,
          child: widget.buttonMode == ButtonMode.MATERIAL
              ? ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.TRAVEL ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.travelIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.TRAVEL
                          ? widget.categoryIcons.travelIcon?.selectedColor
                          : widget.categoryIcons.travelIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.TRAVEL) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum);
                  },
                )
              : CupertinoButton(
            pressedOpacity: 0.4,
                  padding: EdgeInsets.all(0),
                  color: widget.selectedCategory == Category.TRAVEL ? Colors.black12 : Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.travelIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.TRAVEL
                          ? widget.categoryIcons.travelIcon?.selectedColor
                          : widget.categoryIcons.travelIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.TRAVEL) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum);
                  },
                ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / buttonNumber,
          height: MediaQuery.of(context).size.width / buttonNumber,
          child: widget.buttonMode == ButtonMode.MATERIAL
              ? ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.ACTIVITIES ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.activityIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.ACTIVITIES
                          ? widget.categoryIcons.activityIcon?.selectedColor
                          : widget.categoryIcons.activityIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.ACTIVITIES) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum);
                  },
                )
              : CupertinoButton(
            pressedOpacity: 0.4,
                  padding: EdgeInsets.all(0),
                  color: widget.selectedCategory == Category.ACTIVITIES ? Colors.black12 : Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.activityIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.ACTIVITIES
                          ? widget.categoryIcons.activityIcon?.selectedColor
                          : widget.categoryIcons.activityIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.ACTIVITIES) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum);
                  },
                ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / buttonNumber,
          height: MediaQuery.of(context).size.width / buttonNumber,
          child: widget.buttonMode == ButtonMode.MATERIAL
              ? ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.OBJECTS ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.objectIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.OBJECTS
                          ? widget.categoryIcons.objectIcon?.selectedColor
                          : widget.categoryIcons.objectIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.OBJECTS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + activityPagesNum + travelPagesNum);
                  },
                )
              : CupertinoButton(
            pressedOpacity: 0.4,
                  padding: EdgeInsets.all(0),
                  color: widget.selectedCategory == Category.OBJECTS ? Colors.black12 : Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.objectIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.OBJECTS
                          ? widget.categoryIcons.objectIcon?.selectedColor
                          : widget.categoryIcons.objectIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.OBJECTS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + activityPagesNum + travelPagesNum);
                  },
                ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / buttonNumber,
          height: MediaQuery.of(context).size.width / buttonNumber,
          child: widget.buttonMode == ButtonMode.MATERIAL
              ? ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.SYMBOLS ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.symbolIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.SYMBOLS
                          ? widget.categoryIcons.symbolIcon?.selectedColor
                          : widget.categoryIcons.symbolIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.SYMBOLS) {
                      return;
                    }

                    pageController.jumpToPage(
                        epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + activityPagesNum + travelPagesNum + objectPagesNum);
                  },
                )
              : CupertinoButton(
            pressedOpacity: 0.4,
                  padding: EdgeInsets.all(0),
                  color: widget.selectedCategory == Category.SYMBOLS ? Colors.black12 : Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.symbolIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.SYMBOLS
                          ? widget.categoryIcons.symbolIcon?.selectedColor
                          : widget.categoryIcons.symbolIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.SYMBOLS) {
                      return;
                    }

                    pageController.jumpToPage(
                        epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + activityPagesNum + travelPagesNum + objectPagesNum);
                  },
                ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width / buttonNumber,
          height: MediaQuery.of(context).size.width / buttonNumber,
          child: widget.buttonMode == ButtonMode.MATERIAL
              ? ElevatedButton(
                  style: emoji_build_button_style.copyWith(
                    backgroundColor: MaterialStatePropertyAll(widget.selectedCategory == Category.FLAGS ? Colors.black12 : Colors.transparent),
                  ),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.flagIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.FLAGS
                          ? widget.categoryIcons.flagIcon?.selectedColor
                          : widget.categoryIcons.flagIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.FLAGS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum +
                        smileyPagesNum +
                        animalPagesNum +
                        foodPagesNum +
                        activityPagesNum +
                        travelPagesNum +
                        objectPagesNum +
                        symbolPagesNum);
                  },
                )
              : CupertinoButton(
            pressedOpacity: 0.4,
                  padding: EdgeInsets.all(0),
                  color: widget.selectedCategory == Category.FLAGS ? Colors.black12 : Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                  child: Center(
                    child: Icon(
                      widget.categoryIcons.flagIcon?.icon,
                      size: 22,
                      color: widget.selectedCategory == Category.FLAGS
                          ? widget.categoryIcons.flagIcon?.selectedColor
                          : widget.categoryIcons.flagIcon?.color,
                    ),
                  ),
                  onPressed: () {
                    if (widget.selectedCategory == Category.FLAGS) {
                      return;
                    }

                    pageController.jumpToPage(epamojiPagesNum +
                        smileyPagesNum +
                        animalPagesNum +
                        foodPagesNum +
                        activityPagesNum +
                        travelPagesNum +
                        objectPagesNum +
                        symbolPagesNum);
                  },
                ),
        ),
      ]);
      return Column(
        children: <Widget>[
          SizedBox(
            height: 210,
            width: MediaQuery.of(context).size.width,
            child: PageView(
                children: pages,
                controller: pageController,
                onPageChanged: (index) {
                  if (widget.level != ExclusiveRelationItemBean.levelLock && index < epamojiPagesNum) {
                    widget.selectedCategory = Category.EPAMOJI;
                  } else if (index < epamojiPagesNum + smileyPagesNum) {
                    widget.selectedCategory = Category.SMILEYS;
                  } else if (index < epamojiPagesNum + smileyPagesNum + animalPagesNum) {
                    widget.selectedCategory = Category.ANIMALS;
                  } else if (index < epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum) {
                    widget.selectedCategory = Category.FOODS;
                  } else if (index < epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum) {
                    widget.selectedCategory = Category.TRAVEL;
                  } else if (index < epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum + activityPagesNum) {
                    widget.selectedCategory = Category.ACTIVITIES;
                  } else if (index <
                      epamojiPagesNum + smileyPagesNum + animalPagesNum + foodPagesNum + travelPagesNum + activityPagesNum + objectPagesNum) {
                    widget.selectedCategory = Category.OBJECTS;
                  } else if (index <
                      epamojiPagesNum +
                          smileyPagesNum +
                          animalPagesNum +
                          foodPagesNum +
                          travelPagesNum +
                          activityPagesNum +
                          objectPagesNum +
                          symbolPagesNum) {
                    widget.selectedCategory = Category.SYMBOLS;
                  } else {
                    widget.selectedCategory = Category.FLAGS;
                  }
                  widget.onSelectCategoryChange(widget.selectedCategory);
                }),
          ),
          Container(
              color: widget.bgColor,
              height: 6,
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.only(top: 4, bottom: 0, right: 2, left: 2),
              child: CustomPaint(
                painter: _ProgressPainter(
                    context,
                    pageController,
                    Map.fromIterables([
                      Category.EPAMOJI,
                      Category.SMILEYS,
                      Category.ANIMALS,
                      Category.FOODS,
                      Category.TRAVEL,
                      Category.ACTIVITIES,
                      Category.OBJECTS,
                      Category.SYMBOLS,
                      Category.FLAGS
                    ], [
                      epamojiPagesNum,
                      smileyPagesNum,
                      animalPagesNum,
                      foodPagesNum,
                      travelPagesNum,
                      activityPagesNum,
                      objectPagesNum,
                      symbolPagesNum,
                      flagPagesNum
                    ]),
                    widget.selectedCategory,
                    widget.indicatorColor),
              )),
          Container(
              height: 50,
              color: widget.bgColor,
              child: Row(
                children: listWidgetButton,
              ))
        ],
      );
    } else {
      List<Widget> listButton;
      if (widget.level != ExclusiveRelationItemBean.levelLock) {
        listButton = [
          defaultImageButton(widget.categoryIcons.epamoji),
          defaultButton(widget.categoryIcons.smileyIcon),
          defaultButton(widget.categoryIcons.animalIcon),
          defaultButton(widget.categoryIcons.foodIcon),
          defaultButton(widget.categoryIcons.travelIcon),
          defaultButton(widget.categoryIcons.activityIcon),
          defaultButton(widget.categoryIcons.objectIcon),
          defaultButton(widget.categoryIcons.symbolIcon),
          defaultButton(widget.categoryIcons.flagIcon),
        ];
      } else {
        listButton = [
          defaultButton(widget.categoryIcons.smileyIcon),
          defaultButton(widget.categoryIcons.animalIcon),
          defaultButton(widget.categoryIcons.foodIcon),
          defaultButton(widget.categoryIcons.travelIcon),
          defaultButton(widget.categoryIcons.activityIcon),
          defaultButton(widget.categoryIcons.objectIcon),
          defaultButton(widget.categoryIcons.symbolIcon),
          defaultButton(widget.categoryIcons.flagIcon),
        ];
      }
      return Column(
        children: <Widget>[
          SizedBox(
            height: 210,
            width: MediaQuery.of(context).size.width,
            child: Container(
              color: widget.bgColor,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          Container(
            height: 6,
            width: MediaQuery.of(context).size.width,
            color: widget.bgColor,
            padding: EdgeInsets.only(top: 4, left: 2, right: 2),
            child: Container(
              color: widget.indicatorColor,
            ),
          ),
          Container(
            height: 50,
            child: Row(
              children: listButton,
            ),
          )
        ],
      );
    }
  }
}

class _ProgressPainter extends CustomPainter {
  final BuildContext context;
  final PageController pageController;
  final Map<Category, int> pages;
  final Category? selectedCategory;
  final Color indicatorColor;

  _ProgressPainter(this.context, this.pageController, this.pages, this.selectedCategory, this.indicatorColor);

  @override
  void paint(Canvas canvas, Size size) {
    double actualPageWidth = MediaQuery.of(context).size.width;
    double offsetInPages = 0;
    if (selectedCategory == Category.EPAMOJI) {
      offsetInPages = pageController.offset / actualPageWidth;
    } else if (selectedCategory == Category.SMILEYS) {
      offsetInPages = (pageController.offset - (pages[Category.EPAMOJI]! * actualPageWidth)) / actualPageWidth;
    } else if (selectedCategory == Category.ANIMALS) {
      offsetInPages = (pageController.offset - ((pages[Category.EPAMOJI]! + pages[Category.SMILEYS]!) * actualPageWidth)) / actualPageWidth;
    } else if (selectedCategory == Category.FOODS) {
      offsetInPages = (pageController.offset - ((pages[Category.EPAMOJI]! + pages[Category.SMILEYS]! + pages[Category.ANIMALS]!) * actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.TRAVEL) {
      offsetInPages = (pageController.offset -
              ((pages[Category.EPAMOJI]! + pages[Category.SMILEYS]! + pages[Category.ANIMALS]! + pages[Category.FOODS]!) * actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.ACTIVITIES) {
      offsetInPages = (pageController.offset -
          ((pages[Category.EPAMOJI]! + pages[Category.SMILEYS]! + pages[Category.ANIMALS]! + pages[Category.FOODS]! + pages[Category.TRAVEL]!) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.OBJECTS) {
      offsetInPages = (pageController.offset -
              ((pages[Category.EPAMOJI]! +
                      pages[Category.SMILEYS]! +
                      pages[Category.ANIMALS]! +
                      pages[Category.FOODS]! +
                      pages[Category.TRAVEL]! +
                      pages[Category.ACTIVITIES]!) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.SYMBOLS) {
      offsetInPages = (pageController.offset -
              ((pages[Category.EPAMOJI]! +
                      pages[Category.SMILEYS]! +
                      pages[Category.ANIMALS]! +
                      pages[Category.FOODS]! +
                      pages[Category.TRAVEL]! +
                      pages[Category.ACTIVITIES]! +
                      pages[Category.OBJECTS]!) *
                  actualPageWidth)) /
          actualPageWidth;
    } else if (selectedCategory == Category.FLAGS) {
      offsetInPages = (pageController.offset -
              ((pages[Category.EPAMOJI]! +
                      pages[Category.SMILEYS]! +
                      pages[Category.ANIMALS]! +
                      pages[Category.FOODS]! +
                      pages[Category.TRAVEL]! +
                      pages[Category.ACTIVITIES]! +
                      pages[Category.OBJECTS]! +
                      pages[Category.SYMBOLS]!) *
                  actualPageWidth)) /
          actualPageWidth;
    }
    double indicatorPageWidth = size.width / pages[selectedCategory]!;

    Rect bgRect = Offset(0, 0) & size;

    Rect indicator = Offset(max(0, offsetInPages * indicatorPageWidth), 0) &
        Size(
            indicatorPageWidth -
                max(0, (indicatorPageWidth + (offsetInPages * indicatorPageWidth)) - size.width) +
                min(0, offsetInPages * indicatorPageWidth),
            size.height);

    canvas.drawRect(bgRect, Paint()..color = Colors.black12);
    canvas.drawRect(indicator, Paint()..color = indicatorColor);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
