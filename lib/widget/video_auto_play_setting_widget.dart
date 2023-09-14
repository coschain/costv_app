import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/global_util.dart';

///点击疑问按钮回调
typedef ClickQuestionCallBack = Function(double globalX, double globalY);

///自动播放功能切换的回调
typedef AutoPlaySwitchCallBack = Function(bool isOpen);

class VideoAutoPlaySettingWidget extends StatefulWidget {
  final ClickQuestionCallBack? clickQuestionCallBack;
  final AutoPlaySwitchCallBack? autoPlaySwitchCallBack;

  VideoAutoPlaySettingWidget({Key? key, this.clickQuestionCallBack, this.autoPlaySwitchCallBack}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return VideoAutoPlaySettingWidgetState();
  }
}

class VideoAutoPlaySettingWidgetState extends State<VideoAutoPlaySettingWidget> {
  bool _isSwitchEnable = true, _isOpen = false;
  bool _isShowDesc = false;

  @override
  void initState() {
    super.initState();
    _isOpen = usrAutoPlaySetting;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppThemeUtil.setDifferentModeColor(
        lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
        darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Container(
          color: Colors.transparent,
          margin: EdgeInsets.all(0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              //左侧疑问按钮
              _buildQuestionWidget(),
              //开关描述
              _buildSwitchDesc(),
              //开关
              _buildSwitch(),
            ],
          ),
        ),
        onTap: () {
          setState(() {
            _isShowDesc = false;
          });
        },
      ),
    );
  }

  ///左侧疑问按钮
  Widget _buildQuestionWidget() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: <Widget>[
        _buildQuestionButton(),
        Positioned(
          bottom: 23,
          child: _buildFunctionDesc(),
        )
      ],
    );
  }

  Widget _buildQuestionButton() {
    double globalX = 0, globalY = 0;
    return Material(
      color: Colors.transparent,
      child: Ink(
        color: AppThemeUtil.setDifferentModeColor(
          lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
          darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
        ),
        child: InkWell(
          onTap: () {
            if (widget.clickQuestionCallBack != null) {
              widget.clickQuestionCallBack?.call(globalX ?? 0, globalY ?? 0);
            }
            setState(() {
              _isShowDesc = !_isShowDesc;
            });
          },
          child: Container(
            padding: EdgeInsets.all(5),
            child: Image.asset(
              AppThemeUtil.getQuestionIcn(),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionDesc() {
    return AnimatedOpacity(
      opacity: _isShowDesc ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(15),
              margin: EdgeInsets.only(right: 45),
              decoration: BoxDecoration(
                color: AppThemeUtil.setDifferentModeColor(
                  lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
                  darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
                ),
                borderRadius: BorderRadius.all(Radius.circular(5)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.2),
                    offset: Offset(0, 0),
                    spreadRadius: 0,
                    blurRadius: 10,
                  )
                ],
              ),
              child: Text(
                InternationalLocalizations.autoPlayFunctionDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppThemeUtil.setDifferentModeColor(
                    lightColor: Common.getColorFromHexString("333333", 1.0),
                    darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              child: Image.asset(AppThemeUtil.getAutoPlayTipDownArrow()),
            ),
          ],
        ),
      ),
    );
  }

  ///开关描述
  Widget _buildSwitchDesc() {
    return Container(
        margin: EdgeInsets.only(left: 5),
        child: Text(InternationalLocalizations.autoPlayDesc ?? '',
            style: TextStyle(
              color: AppThemeUtil.setDifferentModeColor(
                lightColor: Common.getColorFromHexString("333333", 1.0),
                darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
              ),
              fontSize: 14,
            )));
  }

  ///切换开关
  Widget _buildSwitch() {
    return Container(
      height: kRadialReactionRadius, //设置为kRadialReactionRadius,去掉switch的上下间距
      margin: EdgeInsets.only(left: 5, right: 0),
      child: IgnorePointer(
        child: Container(
          child: Switch(
            value: _isOpen,
            onChanged: (bool val) {
              setState(() {
                _isOpen = val;
                if (widget.autoPlaySwitchCallBack != null) {
                  widget.autoPlaySwitchCallBack?.call(val);
                }
              });
            },
            activeColor: Common.getColorFromHexString("357CFF", 1.0),
            activeTrackColor: Common.getColorFromHexString("357CFF", 0.5),
            inactiveTrackColor: AppThemeUtil.setDifferentModeColor(
              lightColor: Common.getColorFromHexString("221F1F", 0.26),
              darkColor: Common.getColorFromHexString("D6D6D6", 0.26),
            ),
            inactiveThumbColor: Common.getColorFromHexString("F1F1F1", 1.0),
          ),
        ),
        ignoring: !_isSwitchEnable,
      ),
    );
  }

  void updateSwitchEnableStatus(bool isEnable) {
    if (isEnable != _isSwitchEnable) {
      setState(() {
        _isSwitchEnable = isEnable;
      });
    }
  }

  void updateValue(bool val) {
    if (_isOpen != val) {
      setState(() {
        _isOpen = val;
      });
    }
  }

  void updateFunctionDescShowingStatus(bool val) {
    if (_isShowDesc != val) {
      setState(() {
        _isShowDesc = val;
      });
    }
  }
}
