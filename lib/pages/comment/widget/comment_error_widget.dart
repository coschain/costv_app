import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/material.dart';

enum CommentErrorType {
  CommentDelete, //评论被删除
  VideoDelete, //视频被删除
}

class CommentErrorWidget extends StatelessWidget {
  final CommentErrorType commentErrorType;

  CommentErrorWidget({required this.commentErrorType});

  @override
  Widget build(BuildContext context) {
    double marginTop;
    if (commentErrorType == CommentErrorType.VideoDelete) {
      marginTop = AppDimens.margin_174;
    } else {
      marginTop = AppDimens.margin_97;
    }
    return Container(
      color: AppThemeUtil.setDifferentModeColor(
        darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
      ),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          //图片
          Container(
            margin: EdgeInsets.only(top: marginTop),
            child: Image.asset(
              'assets/images/ic_no_comment.png',
              fit: BoxFit.cover,
            ),
          ),
          //提示
          Container(
            margin: EdgeInsets.only(top: AppDimens.margin_12_5),
            child: Text(
              _getDesc(),
              style: TextStyle(
                color: AppThemeUtil.setDifferentModeColor(
                  lightColor: AppColors.color_a0a0a0,
                  darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                ),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDesc() {
    if (commentErrorType == CommentErrorType.CommentDelete) {
      return InternationalLocalizations.commentNoComment;
    } else if (commentErrorType == CommentErrorType.VideoDelete) {
      return InternationalLocalizations.commentNoVideo;
    }
    return "";
  }
}
