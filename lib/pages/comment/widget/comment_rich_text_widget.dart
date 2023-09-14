import 'package:common_utils/common_utils.dart';
import 'package:costv_android/emoji/emoji_lists.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/material.dart';

typedef ClickNameListener = Function(String uid, String name);
typedef ClickHttpListener = Function(String url);

class CommentRichTextWidget extends StatelessWidget {
  static final altUidOneStart = '<a href="[removed]void(0);" class="s-nick" data-id="';
  static final altUidTwoStart = '<a href="javascript:void(0);" class="s-nick" data-id="';
  static final altUidEnd = '">@';
  static final altNameEnd = '</a>';
  static final urlRegex = RegExp(
    r'^((?:.|\n)*?)((?:https?):\/\/[^\s/$.?#].[^\s]*)',
    caseSensitive: false, //忽略大小写
  );

  String text;
  double runSpacing;
  ClickNameListener? clickNameListener;
  ClickHttpListener? clickHttpListener;

  CommentRichTextWidget(
    this.text, {
    this.runSpacing = 10,
    this.clickNameListener,
    this.clickHttpListener,
    Key? key,
  }) : super(key: key) {
    assert(ObjectUtil.isNotEmpty(text));
  }

  List<Widget> textConvertToWidget(String text) {
    List<dynamic> listUser = _userTextConvertToWidget(text);
    List<dynamic> listHttpWidget = [];
    listUser.forEach((data) {
      if (data is Widget) {
        listHttpWidget.add(data);
      } else {
        List<dynamic> listHttp = _httpTextConvertToWidget(data);
        if (!ObjectUtil.isEmptyList(listHttp)) {
          listHttpWidget.addAll(listHttp);
        }
      }
    });
    List<dynamic> listEmojiWidget = listHttpWidget;
    List<dynamic> listEmojiTemp = [];
    epamojis.forEach((key, emojiBean) {
      listEmojiWidget.forEach((data) {
        if (data is Widget) {
          listEmojiTemp.add(data);
        } else {
          List<dynamic> listEmoji = _emojiTextConvertToWidget(data, emojiBean.value, emojiBean.code);
          if (!ObjectUtil.isEmptyList(listEmoji)) {
            listEmojiTemp.addAll(listEmoji);
          }
        }
      });
      listEmojiWidget.clear();
      listEmojiWidget.addAll(listEmojiTemp);
      listEmojiTemp.clear();
    });
    List<Widget> listWidget = [];
    listEmojiWidget.forEach((data) {
      if (data is Widget) {
        listWidget.add(data);
      } else {
        listWidget.add(Text(
          data,
          style: TextStyle(
            color: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_333333,
              darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
            ),
            fontSize: AppDimens.text_size_14,
          ),
        ));
      }
    });
    return listWidget;
  }

  List<dynamic> _userTextConvertToWidget(String text, {List<dynamic>? listData}) {
    if (!ObjectUtil.isEmptyString(text)) {
      if (listData == null) {
        listData = [];
      }
      int startOneIndex = text.indexOf(altUidOneStart);
      int startTwoIndex = text.indexOf(altUidTwoStart);
      if (startOneIndex >= 0 && (startOneIndex < startTwoIndex || startTwoIndex < 0)) {
        String textUidStart = text.substring(0, startOneIndex);
        String textUidEnd = text.substring(startOneIndex + altUidOneStart.length);
        String uid;
        int uidEndIndex = textUidEnd.indexOf(altUidEnd);
        if (uidEndIndex >= 0) {
          uid = textUidEnd.substring(0, uidEndIndex);
          String textNameEnd = textUidEnd.substring(uidEndIndex + altUidEnd.length);
          int nameEndIndex = textNameEnd.indexOf(altNameEnd);
          if (nameEndIndex >= 0) {
            String name = textNameEnd.substring(0, nameEndIndex);
            if (ObjectUtil.isNotEmpty(textUidStart)) {
              listData.add(textUidStart);
            }
            listData.add(InkWell(
              onTap: () {
                if (clickNameListener != null && Common.isAbleClick()) {
                  clickNameListener?.call(uid, name);
                }
              },
              child: Text(
                '@$name',
                style: TextStyle(
                    fontSize: AppDimens.text_size_14,
                    decoration: TextDecoration.underline,
                    color: AppColors.color_3674ff,
                    decorationColor: AppColors.color_3674ff),
              ),
            ));
            String textProcess = textNameEnd.substring(nameEndIndex + altNameEnd.length);
            if (ObjectUtil.isNotEmpty(textProcess)) {
              _userTextConvertToWidget(textProcess, listData: listData);
            }
          } else {
            listData.add(text);
            return listData;
          }
        } else {
          listData.add(text);
          return listData;
        }
      } else {
        if (startTwoIndex >= 0) {
          String textUidStart = text.substring(0, startTwoIndex);
          String textUidEnd = text.substring(startTwoIndex + altUidTwoStart.length);
          String uid;
          int uidEndIndex = textUidEnd.indexOf(altUidEnd);
          if (uidEndIndex >= 0) {
            uid = textUidEnd.substring(0, uidEndIndex);
            String textNameEnd = textUidEnd.substring(uidEndIndex + altUidEnd.length);
            int nameEndIndex = textNameEnd.indexOf(altNameEnd);
            if (nameEndIndex >= 0) {
              String name = textNameEnd.substring(0, nameEndIndex);
              if (ObjectUtil.isNotEmpty(textUidStart)) {
                listData.add(textUidStart);
              }
              listData.add(InkWell(
                onTap: () {
                  if (clickNameListener != null && Common.isAbleClick()) {
                    clickNameListener?.call(uid, name);
                  }
                },
                child: Text(
                  '@$name',
                  style: TextStyle(
                      fontSize: AppDimens.text_size_14,
                      decoration: TextDecoration.underline,
                      color: AppColors.color_3674ff,
                      decorationColor: AppColors.color_3674ff),
                ),
              ));
              String textProcess = textNameEnd.substring(nameEndIndex + altNameEnd.length);
              if (ObjectUtil.isNotEmpty(textProcess)) {
                _userTextConvertToWidget(textProcess, listData: listData);
              }
            } else {
              listData.add(text);
              return listData;
            }
          } else {
            listData.add(text);
            return listData;
          }
        } else {
          listData.add(text);
          return listData;
        }
      }
      return listData;
    }
    return [];
  }

  List<dynamic> _httpTextConvertToWidget(String text, {List<dynamic>? listData}) {
    if (!ObjectUtil.isEmptyString(text)) {
      if (listData == null) {
        listData = [];
      }
      RegExpMatch? match = urlRegex.firstMatch(text);
      if (match == null) {
        listData.add(text);
        return listData;
      } else {
        String textProcess = text.replaceFirst(match.group(0) ?? '', '');
        if (match.group(1)?.isNotEmpty ?? false) {
          listData.add(match.group(1));
        }
        if (match.group(2)?.isNotEmpty ?? false) {
          String url = match.group(2) ?? '';
          listData.add(InkWell(
            onTap: () {
              if (clickHttpListener != null && Common.isAbleClick()) {
                clickHttpListener?.call(url);
              }
            },
            child: Text(
              url,
              style: TextStyle(
                  fontSize: AppDimens.text_size_14,
                  decoration: TextDecoration.underline,
                  color: AppColors.color_3674ff,
                  decorationColor: AppColors.color_3674ff),
            ),
          ));
        }
        if (textProcess.isNotEmpty) {
          _httpTextConvertToWidget(textProcess, listData: listData);
        }
      }
      return listData;
    }
    return [];
  }

  List<dynamic> _emojiTextConvertToWidget(String text, String strRegExp, String emojiCode, {List<dynamic>? listData}) {
    if (!ObjectUtil.isEmptyString(text) && !ObjectUtil.isEmptyString(strRegExp)) {
      if (listData == null) {
        listData = [];
      }
      int startIndex = text.indexOf(strRegExp);
      if (startIndex < 0) {
        listData.add(text);
        return listData;
      } else {
        String textStart = text.substring(0, startIndex);
        if (ObjectUtil.isNotEmpty(textStart)) {
          listData.add(textStart);
        }
        listData.add(Image.asset(
          'assets/epamoji/$emojiCode.png',
          width: 38,
          height: 38,
        ));
        String textProcess = text.substring(startIndex + strRegExp.length);
        if (textProcess.isNotEmpty) {
          _emojiTextConvertToWidget(textProcess, strRegExp, emojiCode, listData: listData);
        }
      }
      return listData;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> listRichText = textConvertToWidget(text);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: runSpacing,
      children: listRichText,
    );
  }
}
