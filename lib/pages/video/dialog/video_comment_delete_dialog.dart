import 'dart:convert';

import 'package:costv_android/bean/simple_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/language/json/common/en.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/video/bean/video_comment_delete_radio_bean.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:flutter/material.dart';

typedef OnSuccessListener();
typedef HandleDeleteCallBack = Function(bool isProcessing, bool isSuccess);
class VideoCommentDeleteDialog {
  final String _tag;
  final GlobalKey<ScaffoldState> _dialogSKey;
  final GlobalKey<ScaffoldState> _pageKey;
  List<VideoCommentDeleteRadioBean> _listCommentDelete = [];
  String _id;
  String _vid;
  String _uid;
  StateSetter _stateSetter;
  String _selectCode;
  bool _isAbleDelete = false;
  OnSuccessListener _onSuccessListener;
  HandleDeleteCallBack _handleDeleteCallBack;

  VideoCommentDeleteDialog(this._tag, this._pageKey, this._dialogSKey) {
    for (int i = 0;
        i < InternationalLocalizations.commentDeleteTypeCodeList.length;
        i++) {
      _listCommentDelete.add(VideoCommentDeleteRadioBean(
          InternationalLocalizations.commentDeleteTypeCodeList[i],
          InternationalLocalizations.commentDeleteTypeNameList[i]));
    }
  }

  /// 初始化数据
  void initData(String id, String vid, String uid,
      OnSuccessListener onSuccessListener,
  {HandleDeleteCallBack handleDeleteCallBack}) {
    _id = id;
    _vid = vid;
    _uid = uid;
    _selectCode = null;
    _isAbleDelete = false;
    this._onSuccessListener = onSuccessListener;
    this._handleDeleteCallBack = handleDeleteCallBack;
  }

  void showVideoCommentDeleteDialog() {
    showDialog<int>(
      context: _pageKey.currentState.context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, state) {
          _stateSetter = state;
          return Scaffold(
            key: _dialogSKey,
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            body: SimpleDialog(
              titlePadding: EdgeInsets.all(0.0),
              contentPadding: EdgeInsets.all(0.0),
              children: <Widget>[_buildCommentDelete(context)],
            ),
          );
        });
      },
    );
  }

  /// 构建删除评论弹出框界面
  Widget _buildCommentDelete(BuildContext context) {
    return Container(
        width: AppDimens.item_size_290,
        height: AppDimens.item_size_380,
        decoration: BoxDecoration(
          color: AppThemeUtil.setDifferentModeColor(
            lightColor: AppColors.color_ffffff,
            darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
          ),
          borderRadius:
          BorderRadius.circular(AppDimens.radius_size_4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(
                left: AppDimens.margin_20,
                top: AppDimens.margin_15,
                right: AppDimens.margin_20,
              ),
              child: Text(
                InternationalLocalizations.commentDeleteTitle,
                style: TextStyle(
                  color: AppThemeUtil.setDifferentModeColor(
                    lightColor: AppColors.color_333333,
                    darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr
                  ),
                  fontSize: AppDimens.text_size_16,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                top: 4,
                left: AppDimens.margin_20,
                right: AppDimens.margin_20,
              ),
              child: Text(
                InternationalLocalizations.commentDeleteTips,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: Common.getColorFromHexString("A0A0A0", 1.0)
                ),
              ),
            ),
            Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: AppDimens.margin_12_5),
                  child: ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      VideoCommentDeleteRadioBean bean = _listCommentDelete[index];
                      return RadioListTile<String>(
                        title:
                        Text(bean.getName, style: TextStyle(
                          color: AppThemeUtil.setDifferentModeColor(
                            lightColor: AppColors.color_333333,
                            darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                          ),
                          fontSize: AppDimens.text_size_12,
                        )),
                        value: bean.getCode,
                        groupValue: _selectCode,
                        onChanged: (value) {
                          _stateSetter(() {
                            _selectCode = value;
                            _isAbleDelete = true;
                          });
                        },
                      );
                    },
                    itemCount: _listCommentDelete.length,
                  ),
                )),
            Container(
              height: AppDimens.item_size_40,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: Material(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_d6d6d6,
                          darkColorStr: "858585",
                        ),
                        child: MaterialButton(
                          child: Text(
                            InternationalLocalizations.cancel,
                            style: AppStyles.text_style_ffffff_14,
                            textAlign: TextAlign.center,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      )),
                  Expanded(
                      flex: 1,
                      child: Material(
                        color: _isAbleDelete
                            ? AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_3674ff,
                          darkColorStr: "285ED8",
                        )
                            : AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_a0a0a0,
                          darkColorStr: "858585",
                        ),
                        child: MaterialButton(
                          child: Text(
                            InternationalLocalizations.delete,
                            style: AppStyles.text_style_ffffff_14,
                            textAlign: TextAlign.center,
                          ),
                          onPressed: () {
                            if (_isAbleDelete) {
                              _httpVideoCommentDel(context);
                            }
                          },
                        ),
                      )),
                ],
              ),
            )
          ],
        ),
      );
  }

  void _httpVideoCommentDel(BuildContext context) {
    if (this._handleDeleteCallBack != null) {
      this._handleDeleteCallBack(true, false);
    }
    RequestManager.instance
        .videoCommentDel(
            _tag, _id ?? '', _vid ?? '', _uid ?? '', _selectCode ?? '')
        .then((response) {
      if (response == null) {
        if (this._handleDeleteCallBack != null) {
          this._handleDeleteCallBack(false, false);
        }
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        ToastUtil.showToast(InternationalLocalizations.commentDeleteSuccessTips);
        if(_onSuccessListener != null){
          _onSuccessListener();
          if (this._handleDeleteCallBack != null) {
            this._handleDeleteCallBack(false, true);
          }
        }
        Navigator.of(context).pop();
      } else {
        ToastUtil.showToast(bean?.msg ?? '');
        if (this._handleDeleteCallBack != null) {
          this._handleDeleteCallBack(false, false);
        }
      }
    });
  }
}
