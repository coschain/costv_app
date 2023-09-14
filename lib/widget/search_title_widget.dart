import 'package:common_utils/common_utils.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/material.dart';

typedef OnTextChanged(String str);
typedef OnClickSearch(String str);

class SearchTitleWidget extends StatefulWidget {
  final String searchStr;
  final OnTextChanged? onTextChanged;
  final OnClickSearch? onClickSearch;

  SearchTitleWidget({Key? key, required this.searchStr, this.onTextChanged, this.onClickSearch}) : super(key: key);

  @override
  _SearchTitleWidgetState createState() => _SearchTitleWidgetState();
}

class _SearchTitleWidgetState extends State<SearchTitleWidget> {
  TextEditingController _textController = TextEditingController();
  bool _isShowDelete = false;

  @override
  void initState() {
    super.initState();
    if (!ObjectUtil.isEmptyString(widget.searchStr)) {
      _textController.text = widget.searchStr;
      _isShowDelete = true;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppThemeUtil.setDifferentModeColor(lightColor: AppColors.color_ffffff, darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
      height: AppDimens.item_size_55,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          InkWell(
            child: Container(
              padding: EdgeInsets.all(AppDimens.margin_10),
              child: Image.asset(AppThemeUtil.getBackIcn()),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: AppDimens.margin_10, right: AppDimens.margin_10),
              height: AppDimens.item_size_32,
              child: Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  TextField(
                    onSubmitted: (value) {
                      if (widget.onClickSearch != null && !ObjectUtil.isEmptyString(_textController.text.trim())) {
                        Navigator.pop(context);
                        widget.onClickSearch?.call(_textController.text.trim());
                      }
                    },
                    onChanged: (str) {
                      if (str.trim().isNotEmpty) {
                        if (!_isShowDelete) {
                          _isShowDelete = true;
                        }
                      } else {
                        if (_isShowDelete) {
                          _isShowDelete = false;
                        }
                      }
                      if (widget.onTextChanged != null) {
                        widget.onTextChanged?.call(str);
                      }
                    },
                    controller: _textController,
                    style: TextStyle(
                      color: AppThemeUtil.setDifferentModeColor(
                        lightColor: AppColors.color_333333,
                        darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                      ),
                      fontSize: AppDimens.text_size_14,
                    ),
                    decoration: InputDecoration(
                      fillColor: AppThemeUtil.setDifferentModeColor(
                        lightColor: AppColors.color_ebebeb,
                        darkColorStr: "333333",
                      ),
                      filled: true,
                      hintStyle: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_858585,
                          darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                        ),
                        fontSize: AppDimens.text_size_14,
                      ),
                      hintText: InternationalLocalizations.searchInputHint,
                      contentPadding: EdgeInsets.only(left: AppDimens.margin_10, top: AppDimens.margin_12, right: AppDimens.margin_20),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.color_transparent),
                        borderRadius: BorderRadius.circular(AppDimens.radius_size_21),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.color_3674ff),
                        borderRadius: BorderRadius.circular(AppDimens.radius_size_21),
                      ),
                    ),
                    autofocus: true,
                  ),
                  Offstage(
                    offstage: !_isShowDelete,
                    child: InkWell(
                      child: Container(
                        margin: EdgeInsets.only(right: AppDimens.margin_5),
                        padding: EdgeInsets.all(AppDimens.margin_5),
                        child: Image.asset('assets/images/ic_input_close.png'),
                      ),
                      onTap: () {
                        _textController.clear();
                        if (widget.onTextChanged != null) {
                          widget.onTextChanged?.call('');
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          InkWell(
            child: Container(
              padding: EdgeInsets.all(AppDimens.margin_10),
              child: Image.asset(AppThemeUtil.getSearchIcn()),
            ),
            onTap: () {
              if (widget.onClickSearch != null && !ObjectUtil.isEmptyString(_textController.text.trim())) {
                Navigator.pop(context);
                widget.onClickSearch?.call(_textController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }
}
