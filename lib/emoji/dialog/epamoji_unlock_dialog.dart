import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/material.dart';

class EpamojiUnlockDialog {
  void showEpamojiUnlockDialog(BuildContext context) {
    showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, state) {
          return SimpleDialog(
            titlePadding: EdgeInsets.all(0.0),
            contentPadding: EdgeInsets.all(0.0),
            backgroundColor: AppColors.color_transparent,
            children: <Widget>[_buildBody(context)],
          );
        });
      },
    );
  }

  /// 构建解锁Epamoji表情弹出框界面
  Widget _buildBody(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: AppColors.color_transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Stack(
            alignment: Alignment.topRight,
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Image.asset('assets/images/ic_unlock_emoji_head.png'),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(flex: 1, child: Container()),
                      Expanded(
                          flex: 1,
                          child: Container(
                            margin: EdgeInsets.only(right: AppDimens.margin_20),
                            child: Text(
                              InternationalLocalizations.emojiUnlockTitle,
                              style: TextStyle(
                                  color: AppColors.color_ffffff,
                                  fontSize: AppDimens.text_size_17),
                            ),
                          )),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.all(AppDimens.margin_10),
                    child: Image.asset(
                        'assets/images/ic_unlock_emoji_close_white.png'),
                  ),
                ),
              )
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppThemeUtil.setDifferentModeColor(
                lightColor: AppColors.color_ffffff,
                darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
              ),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimens.radius_size_4),
                  bottomRight: Radius.circular(AppDimens.radius_size_4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: AppDimens.margin_17_5),
                  child: Image.asset(AppThemeUtil.getUnlockEmojiBody()),
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: AppDimens.margin_25,
                    top: AppDimens.margin_15,
                    right: AppDimens.margin_25,
                  ),
                  child: Text(
                    InternationalLocalizations.emojiUnlockHint,
                    style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_333333,
                          darkColorStr: DarkModelTextColorUtil
                              .firstLevelBrightnessColorStr,
                        ),
                        fontSize: AppDimens.text_size_13),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: AppDimens.margin_25,
                    top: AppDimens.margin_25,
                    right: AppDimens.margin_25,
                    bottom: AppDimens.margin_25,
                  ),
                  child: Text(
                    InternationalLocalizations.emojiUnlockGo,
                    style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_333333,
                          darkColorStr: DarkModelTextColorUtil
                              .firstLevelBrightnessColorStr,
                        ),
                        fontSize: AppDimens.text_size_13),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
