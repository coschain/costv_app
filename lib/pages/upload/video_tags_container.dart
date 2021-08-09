import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/utils/common_util.dart';


typedef VideoTagOnTapCallback = void Function(int index, String tag);

class VideoTagsContainer extends StatelessWidget {
  final List<String> tags;
  final bool hasDeleteIcon;
  final VideoTagOnTapCallback onTap;

  VideoTagsContainer({
    @required this.tags,
    this.hasDeleteIcon = false,
    this.onTap,
  });

  @protected
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      children: items(),
    );
  }

  List<Widget> items() {
    List<Widget> items = [];
    for (int i = 0; i < tags.length; i++) {
      Widget w;
      if (hasDeleteIcon) {
        w = Chip(
          label: Text(tags[i]),
          labelStyle: TextStyle(fontSize: 14, color: Colors.white),
          backgroundColor: Color(0xFF357CFF),
          shape: StadiumBorder(side: BorderSide(
            color: Color(0xFF357CFF),
          )),
          deleteIcon: Icon(Icons.close, size: 14, color: Colors.white),
          onDeleted: () {
            if (onTap != null) {
              onTap(i, tags[i]);
            }
          },
        );
      } else {
        if (onTap == null) {
          w = Chip(
            label: Text(tags[i]),
            labelStyle: TextStyle(
              fontSize: 14,
              color: Common.getColorFromHexString(AppThemeUtil.getSecondaryTitleColorStr(), 1.0),
            ),
            backgroundColor: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_f6f6f6,
              darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
            ),
            shape: StadiumBorder(side: BorderSide(
              color: Common.getColorFromHexString(AppThemeUtil.getSecondaryTitleColorStr(), 1.0),
            )),
          );
        } else {
          w = ActionChip(
            label: Text(tags[i]),
            labelStyle: TextStyle(
              fontSize: 14,
              color: Common.getColorFromHexString(AppThemeUtil.getSecondaryTitleColorStr(), 1.0),
            ),
            backgroundColor: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_f6f6f6,
              darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
            ),
            shape: StadiumBorder(side: BorderSide(
              color: Common.getColorFromHexString(AppThemeUtil.getSecondaryTitleColorStr(), 1.0),
            )),
            onPressed: () {
              onTap(i, tags[i]);
            },
          );
        }
      }
      items.add(w);
    }
    return items;
  }
}
