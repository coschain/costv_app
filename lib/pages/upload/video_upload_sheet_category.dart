import 'package:costv_android/language/international_localizations.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';

class VideoCategorySheet extends StatefulWidget {
  final List categories;
  final int? firstCategory;
  final int? secondCategory;

  VideoCategorySheet({required this.categories, this.firstCategory, this.secondCategory});

  @override
  _VideoCategorySheetState createState() => _VideoCategorySheetState();
}

class _VideoCategorySheetState extends State<VideoCategorySheet> {
  late int firstCategory;
  late int secondCategory;
  late List<int> selected;
  late GlobalKey firstKey;
  late GlobalKey secondKey;
  late ScrollController firstController;
  late ScrollController secondController;

  _VideoCategorySheetState();

  @override
  void initState() {
    super.initState();
    firstCategory = widget.firstCategory ?? 0;
    secondCategory = widget.secondCategory ?? 0;
    selected = [widget.firstCategory ?? 0, widget.secondCategory ?? 0];
    firstKey = GlobalKey();
    firstController = ScrollController();
    secondKey = GlobalKey();
    secondController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          bottom: 0,
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: Material(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                color: AppThemeUtil.setDifferentModeColor(
                  lightColor: AppColors.color_f6f6f6,
                  darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
                            color: AppThemeUtil.setDifferentModeColor(
                              lightColor: Color(0xffe7e7e7),
                              darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(height: 15),
                              Container(
                                height: 340,
                                width: MediaQuery.of(context).size.width * 0.3,
                                child: ListView(
                                  cacheExtent: 1000,
                                  children: buildFirstCategoryItems(context),
                                  controller: firstController,
                                ),
                              ),
                              Container(height: 15),
                            ],
                          ),
                        ),
                        Column(
                          children: <Widget>[
                            Container(height: 15),
                            Container(
                              height: 340,
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: ListView(
                                cacheExtent: 1000,
                                children: buildSecondCategoryItems(context),
                                controller: secondController,
                              ),
                            ),
                            Container(height: 15),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      height: 0.5,
                      color: AppThemeUtil.getListSeparatorColor(),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                            child: Text(InternationalLocalizations.cancel, style: TextStyle(fontSize: 15)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
          ),
        )
      ],
    );
  }

  List<Widget> buildFirstCategoryItems(BuildContext context) {
    List<Widget> items = [];
    for (int i = 0; i < widget.categories.length; i++) {
      bool isSelected = firstCategory == i;
      items.add(Container(
        color: isSelected
            ? AppThemeUtil.setDifferentModeColor(
                lightColor: AppColors.color_f6f6f6,
                darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
              )
            : null,
        child: ListTileTheme(
          selectedColor: Color(0xFF357CFF),
          child: ListTile(
            key: isSelected ? firstKey : null,
            title: Text(
              widget.categories[i][1],
              style: isSelected ? TextStyle(fontWeight: FontWeight.bold) : null,
            ),
            selected: isSelected,
            onTap: () {
              setState(() {
                firstCategory = i;
              });
            },
          ),
        ),
      ));
    }
    return items;
  }

  List<Widget> buildSecondCategoryItems(BuildContext context) {
    List<Widget> items = [];
    if (firstCategory < widget.categories.length) {
      List data = widget.categories[firstCategory][2];
      for (int i = 0; i < data.length; i++) {
        bool isSelected = secondCategory == i && firstCategory == selected[0];
        items.add(ListTileTheme(
            key: isSelected ? secondKey : null,
            selectedColor: Color(0xFF357CFF),
            child: ListTile(
              title: Text(
                data[i][1],
                style: isSelected ? TextStyle(fontWeight: FontWeight.bold) : null,
              ),
              selected: isSelected,
              trailing: isSelected ? Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  secondCategory = i;
                  selected = [firstCategory, secondCategory];
                });
                Navigator.of(context).pop([
                  firstCategory,
                  widget.categories[firstCategory][0],
                  widget.categories[firstCategory][1],
                  i,
                  widget.categories[firstCategory][2][i][0],
                  widget.categories[firstCategory][2][i][1],
                ]);
              },
            )));
      }
    }
    return items;
  }

  void _scrollToSelected() {
    if (firstKey.currentContext?.findRenderObject() != null) {
      firstController.position.ensureVisible(
        firstKey.currentContext?.findRenderObject() as RenderObject,
        alignment: 0.5,
        duration: const Duration(milliseconds: 500),
      );
    }
    if (secondKey.currentContext?.findRenderObject() != null) {
      secondController.position.ensureVisible(
        secondKey.currentContext?.findRenderObject() as RenderObject,
        alignment: 0.5,
        duration: const Duration(milliseconds: 500),
      );
    }
  }
}
