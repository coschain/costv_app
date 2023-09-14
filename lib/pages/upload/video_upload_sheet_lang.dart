import 'package:costv_android/language/international_localizations.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';

class VideoLanguageSheet extends StatefulWidget {
  final String langCode;
  final List languageList;

  VideoLanguageSheet({required this.langCode, required this.languageList});

  @override
  _VideoLanguageSheetState createState() => _VideoLanguageSheetState();
}

class _VideoLanguageSheetState extends State<VideoLanguageSheet> {
  late String langCode;
  late GlobalKey globalKey;
  late ScrollController scrollController;

  _VideoLanguageSheetState();

  @override
  void initState() {
    super.initState();
    langCode = widget.langCode;
    globalKey = GlobalKey();
    scrollController = ScrollController();
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
                    Container(height: 15),
                    Container(
                      height: 340,
                      child: ListView(
                        cacheExtent: 1000,
                        children: buildItems(context),
                        controller: scrollController,
                      ),
                    ),
                    Container(height: 15),
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

  List<Widget> buildItems(BuildContext context) {
    List<Widget> items = [];
    for (int i = 0; i < widget.languageList.length; i++) {
      bool isSelected = langCode == widget.languageList[i][0];
      items.add(ListTileTheme(
        key: isSelected ? globalKey : null,
        selectedColor: Color(0xFF357CFF),
        child: ListTile(
          title: Text(
            widget.languageList[i][1],
            style: isSelected ? TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          selected: isSelected,
          trailing: isSelected ? Icon(Icons.check) : null,
          onTap: () {
            setState(() {
              langCode = widget.languageList[i][0];
            });
            Navigator.of(context).pop(i);
          },
        ),
      ));
    }
    return items;
  }

  void _scrollToSelected() {
    if (globalKey.currentContext?.findRenderObject() != null) {
      scrollController.position.ensureVisible(
        globalKey.currentContext?.findRenderObject() as RenderObject,
        alignment: 0.5,
        duration: const Duration(milliseconds: 500),
      );
    }
  }
}
