import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/common_util.dart';

typedef VideoUploadAppbarBackHandler = void Function();
typedef VideoUploadAppbarButtonHandler = void Function();

class VideoUploadAppbar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final VideoUploadAppbarBackHandler? onBack;
  final String? buttonText;
  final Color? buttonTextColor;
  final VideoUploadAppbarButtonHandler? onButtonTapped;

  VideoUploadAppbar({this.title, this.onBack, this.buttonText, this.buttonTextColor, this.onButtonTapped});

  @override
  _VideoUploadAppbarState createState() => _VideoUploadAppbarState();

  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _VideoUploadAppbarState extends State<VideoUploadAppbar> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width, leftWidth = 40;
    return PreferredSize(
      preferredSize: widget.preferredSize,
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        width: screenWidth,
        height: kToolbarHeight,
        color: AppThemeUtil.setDifferentModeColor(
          lightColor: Common.getColorFromHexString("FFFFFFFF", 1),
          darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //返回按钮
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: leftWidth,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Image.asset(
                  AppThemeUtil.getBackIcn(),
                  width: 7,
                  height: 14,
                  fit: BoxFit.cover,
                ),
              ),
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack?.call();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),

            // 标题
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: 5),
                child: Text(widget.title ?? "",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: Colors.black,
                          darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                        ),
                        fontSize: 15)),
              ),
            ),

            ObjectUtil.isEmptyString(widget.buttonText)
                ? Container()
                : Container(
                    margin: EdgeInsets.only(left: 16, right: 16),
                    child: GestureDetector(
                      child: Text(widget.buttonText ?? "", style: TextStyle(color: widget.buttonTextColor, fontSize: 15)),
                      onTap: () {
                        if (widget.onButtonTapped != null) {
                          widget.onButtonTapped?.call();
                        }
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
