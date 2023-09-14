import 'package:common_utils/common_utils.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/pages/upload/video_tags_container.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';

const int MaxTagSize = 20;

class VideoTagsSheet extends StatefulWidget {
  final List? sysTags;
  final List<int>? selectedSysTags;
  final List<String>? userTags;

  VideoTagsSheet({
    this.sysTags,
    this.selectedSysTags,
    this.userTags,
  });

  @override
  _VideoTagsSheetState createState() => _VideoTagsSheetState();
}

class _VideoTagsSheetState extends State<VideoTagsSheet> {
  List<int> _sysTags = [];
  List<String> _userTags = [];
  String _inputTag = "";
  bool _changed = false;
  late TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    if (widget.selectedSysTags != null) {
      _sysTags.addAll(widget.selectedSysTags!);
    }
    if (widget.userTags != null) {
      _userTags.addAll(widget.userTags!);
    }
    _inputController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    List<String> recommendTags = _unSelectedSysTags;
    List<String> chosenTags = _selectedTags;
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
                  Container(
                    height: 400,
                    padding: EdgeInsets.all(15),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: AppThemeUtil.setDifferentModeColor(
                                lightColor: Color(0xffe7e7e7),
                                darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.only(left: 15, right: 0),
                            margin: EdgeInsets.only(top: 5, bottom: 20),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextField(
                                    controller: _inputController,
                                    style: TextStyle(fontSize: 15),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: InternationalLocalizations.uploadTagInputHint,
                                      hintStyle: TextStyle(color: AppThemeUtil.getUploadHintTextColor()),
                                    ),
                                    maxLines: 1,
                                    onChanged: (s) {
                                      if (s.length > MaxTagSize) {
                                        s = s.substring(0, MaxTagSize);
                                        _inputController.text = s;
                                      }
                                      setState(() {
                                        _inputTag = s;
                                      });
                                    },
                                  ),
                                ),
                                ObjectUtil.isEmptyString(_inputTag)
                                    ? Container()
                                    : ElevatedButton(
                                        child: Text(InternationalLocalizations.uploadTagAdd),
                                        onPressed: () {
                                          setState(() {
                                            _addTag(_inputTag);
                                            _inputTag = "";
                                          });
                                          _inputController.clear();
                                        },
                                      ),
                              ],
                            ),
                          ),
                          recommendTags.length > 0 ? Text(InternationalLocalizations.uploadTagRecommends) : Container(),
                          recommendTags.length > 0
                              ? Container(
                                  padding: EdgeInsets.only(top: 10, bottom: 20),
                                  child: VideoTagsContainer(
                                    tags: recommendTags,
                                    onTap: (index, t) {
                                      setState(() {
                                        _addTag(t);
                                      });
                                    },
                                  ),
                                )
                              : Container(),
                          chosenTags.length > 0 ? Text(InternationalLocalizations.uploadTagSelected) : Container(),
                          chosenTags.length > 0
                              ? Container(
                                  padding: EdgeInsets.only(top: 10, bottom: 20),
                                  child: VideoTagsContainer(
                                    tags: chosenTags,
                                    hasDeleteIcon: true,
                                    onTap: (index, t) {
                                      setState(() {
                                        _removeTag(t);
                                      });
                                    },
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 0.5,
                    color: AppThemeUtil.getListSeparatorColor(),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                          child:
                              Text(_changed ? InternationalLocalizations.confirm : InternationalLocalizations.cancel, style: TextStyle(fontSize: 15)),
                          onPressed: () {
                            if (_changed) {
                              Navigator.of(context).pop([_sysTags, _userTags]);
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  List<String> get _unSelectedSysTags {
    List<String> r = [];
    for (int i = 0; i < widget.sysTags!.length; i++) {
      if (_sysTags.indexOf(i) < 0) {
        r.add(widget.sysTags![i][1]);
      }
    }
    return r;
  }

  List<String> get _selectedTags {
    List<String> r = [];
    _sysTags.forEach((index) {
      r.add(widget.sysTags![index][1]);
    });
    r.addAll(_userTags);
    return r;
  }

  void _addTag(String t) {
    t = t.trim();
    if (t.length == 0) {
      return;
    }
    _changed = true;
    int sysTagIndex = -1;
    for (int i = 0; i < widget.sysTags!.length; i++) {
      if (widget.sysTags![i][1] == t) {
        sysTagIndex = i;
        break;
      }
    }
    if (sysTagIndex >= 0) {
      if (_sysTags.indexOf(sysTagIndex) < 0) {
        _sysTags.add(sysTagIndex);
      }
      return;
    }
    if (_userTags.indexOf(t) < 0) {
      _userTags.add(t);
    }
  }

  void _removeTag(String t) {
    _changed = true;
    int sysTagIndex = -1;
    for (int i = 0; i < widget.sysTags!.length; i++) {
      if (widget.sysTags![i][1] == t) {
        sysTagIndex = i;
        break;
      }
    }
    if (sysTagIndex >= 0) {
      _sysTags.remove(sysTagIndex);
    }
    _userTags.remove(t);
  }
}
