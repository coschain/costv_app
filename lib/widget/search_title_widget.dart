import 'package:common_utils/common_utils.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:flutter/material.dart';

typedef OnTextChanged(String str);
typedef OnClickSearch(String str);

class SearchTitleWidget extends StatefulWidget {
  final String searchStr;
  final OnTextChanged onTextChanged;
  final OnClickSearch onClickSearch;

  SearchTitleWidget(
      {Key key, this.searchStr, this.onTextChanged, this.onClickSearch})
      : super(key: key);

  @override
  _SearchTitleWidgetState createState() => _SearchTitleWidgetState();
}

class _SearchTitleWidgetState extends State<SearchTitleWidget> {
  TextEditingController _textController = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _isShowDelete = false;

  @override
  void initState() {
    super.initState();
    if (!ObjectUtil.isEmptyString(widget.searchStr)) {
      _textController.text = widget.searchStr;
      _isShowDelete = true;
    }
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    if (_textController != null) {
      _textController.dispose();
      _textController = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.color_ffffff,
      height: AppDimens.item_size_55,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          InkWell(
            child: Container(
              padding: EdgeInsets.all(AppDimens.margin_10),
              child: Image.asset('assets/images/ic_back.png'),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                  left: AppDimens.margin_10, right: AppDimens.margin_10),
              height: AppDimens.item_size_32,
              child: Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  TextField(
                    onSubmitted: (value){
                      if (widget.onClickSearch != null &&
                          !ObjectUtil.isEmptyString(_textController.text.trim())) {
                        Navigator.pop(context);
                        widget.onClickSearch(_textController.text.trim());
                      }
                    },
                    onChanged: (str) {
                      if (str != null && str.trim().isNotEmpty) {
                        if (!_isShowDelete) {
                          _isShowDelete = true;
                        }
                      } else {
                        if (_isShowDelete) {
                          _isShowDelete = false;
                        }
                      }
                      if (widget.onTextChanged != null) {
                        widget.onTextChanged(str);
                      }
                    },
                    controller: _textController,
                    focusNode: _focusNode,
                    style: AppStyles.text_style_333333_14,
                    decoration: InputDecoration(
                      fillColor: AppColors.color_ebebeb,
                      filled: true,
                      hintStyle: AppStyles.text_style_858585_14,
                      hintText: InternationalLocalizations.searchInputHint,
                      contentPadding: EdgeInsets.only(
                          left: AppDimens.margin_10,
                          top: AppDimens.margin_12,
                          right: AppDimens.margin_20),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.color_transparent),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radius_size_21),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.color_3674ff),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radius_size_21),
                      ),
                    ),
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
                          widget.onTextChanged('');
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
              child: Image.asset('assets/images/ic_search.png'),
            ),
            onTap: () {
              if (widget.onClickSearch != null &&
                  !ObjectUtil.isEmptyString(_textController.text.trim())) {
                Navigator.pop(context);
                widget.onClickSearch(_textController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }
}
