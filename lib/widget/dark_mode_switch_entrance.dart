import 'dart:async';

import 'package:costv_android/event/app_mode_switch_event.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:flutter/material.dart';

class DarkModeSwitchEntrance extends StatefulWidget {
  DarkModeSwitchEntrance({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DarkModeSwitchEntranceState();
  }
}

class DarkModeSwitchEntranceState extends State<DarkModeSwitchEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionY;
  late Animation<double> _lFadeIn;
  late Animation<double> _dFadeIn;
  bool isAnimation = false, _isSwitchEnable = true, _isOpen = false;
  double _moveY = 18.0;
  double _initLight = 0;
  double _initDark = -18;
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    _isOpen = brightnessModel == Brightness.dark;
    if (_isOpen) {
      _initLight = _moveY;
      _initDark = 0;
    }
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _lFadeIn = Tween<double>(begin: _isOpen ? 0.0 : 1.0, end: 1.0).animate(_controller);
    _dFadeIn = Tween<double>(begin: _isOpen ? 1.0 : 0.0, end: 1.0).animate(_controller);
    _positionY = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(updateState)
      ..addStatusListener(listenAnimationStatus);
    _listenEvent();
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(updateState);
    _positionY.removeStatusListener(listenAnimationStatus);
    _controller.dispose();
    _cancelListenEvent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String modeDesc = InternationalLocalizations.lightModeDesc;
    if (AppThemeUtil.checkIsDarkMode()) {
      modeDesc = InternationalLocalizations.darkModeDesc;
    }
    double itemWidth = MediaQuery.of(context).size.width, lIconSize = 16.0, descLeftMargin = 10, itemPadding = 15.0;
    return Material(
      color: Colors.transparent,
      child: Ink(
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0), darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
        child: InkWell(
          child: Container(
            width: itemWidth,
            padding: EdgeInsets.only(
              top: itemPadding,
              bottom: itemPadding,
              left: itemPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //左侧icon
                _buildIcn(),
                //描述
                Container(
                  width: itemWidth - descLeftMargin - itemPadding - lIconSize - 65,
                  margin: EdgeInsets.only(left: descLeftMargin),
                  child: Text(
                    modeDesc,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppThemeUtil.setDifferentModeColor(
                          lightColor: Common.getColorFromHexString("333333", 1.0), darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr),
                    ),
                  ),
                ),
                //right switch
                _buildSwitch()
              ],
            ),
          ),
          onTap: () {},
        ),
      ),
    );
  }

  ///icon
  Widget _buildIcn() {
    return Transform.translate(
      offset: Offset(0, 0),
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Container(
            width: 18,
            height: 18,
          ),
          Positioned(
            top: _initLight + _positionY.value,
            child: Opacity(
              opacity: _lFadeIn.value,
              child: Image.asset(
                "assets/images/icn_light_mode_menu.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: _initDark + _positionY.value,
            child: Opacity(
              opacity: _dFadeIn.value,
              child: Image.asset(
                "assets/images/icn_dark_mode_menu.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///切换开关
  Widget _buildSwitch() {
    _isOpen = AppThemeUtil.checkIsDarkMode();
    return IgnorePointer(
      ignoring: !_isSwitchEnable, //正在切换中的时候不让响应事件,避免上次还没切换成功，下次又开始了
      child: Container(
        height: kRadialReactionRadius, //设置为kRadialReactionRadius,去掉switch的上下间距
        margin: EdgeInsets.only(left: 2, right: 0),
        child: Container(
          child: Switch(
            value: _isOpen,
            onChanged: (bool val) {
              bool isToDarkMode = brightnessModel == Brightness.light;
              isSwitchedModeByUser = true;
              Brightness oldVal = brightnessModel;
              if (isToDarkMode) {
                brightnessModel = Brightness.dark;
              } else {
                brightnessModel = Brightness.light;
              }
              setState(() {
                _isOpen = val;
                _isSwitchEnable = false;
              });
              EventBusHelp.getInstance().fire(ManualSwitchModeEvent(oldVal, brightnessModel));
              Future.delayed(Duration(milliseconds: 500), () {
                if (!mounted) {
                  return;
                }
                startShowAnimation(isToDarkMode);
              });
              _reportDarkModeSwitch();
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
      ),
    );
  }

  void startShowAnimation(bool isToDarkMode) {
    if (isAnimation) {
      return;
    }
    isAnimation = true;
    double moveYStart = isToDarkMode ? 0 : -_moveY;
    double moveYEnd = isToDarkMode ? _moveY : 0;
    if (isToDarkMode) {
      _lFadeIn = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.01, curve: Curves.easeIn)));
      _dFadeIn = Tween<double>(begin: 1.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.0, curve: Curves.easeIn)));
    } else {
      _lFadeIn = Tween<double>(begin: 1.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.0, curve: Curves.easeIn)));
      _dFadeIn = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.01, curve: Curves.easeIn)));
    }
    try {
      if (_controller.isCompleted) {
        _controller.reverse();
      } else {
        _positionY = Tween<double>(begin: moveYStart, end: moveYEnd).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(0.01, 1.0, curve: Curves.easeIn),
        ));
        if (moveYStart < 0) {
          _positionY = Tween<double>(begin: moveYEnd, end: moveYStart).animate(CurvedAnimation(
            parent: _controller,
            curve: Interval(0.01, 1.0, curve: Curves.easeIn),
          ));
        }
        _controller.forward();
      }
    } on TickerCanceled {}
  }

  void updateState() {
    setState(() {});
  }

  void listenAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
    } else if (status == AnimationStatus.reverse) {
    } else if (status == AnimationStatus.completed) {
      isAnimation = false;
      setState(() {
        _isSwitchEnable = true;
      });
    } else if (status == AnimationStatus.dismissed) {
      isAnimation = false;
      setState(() {
        _isSwitchEnable = true;
      });
    }
  }

  ///监听消息
  void _listenEvent() {
    if (_eventSubscription == null) {
      _eventSubscription = EventBusHelp.getInstance().on().listen((event) {
        if (event != null) {
          if (event is SystemSwitchModeEvent) {
            if (event.oldVal != event.curVal) {
              if (!mounted) {
                return;
              }
              bool isToDarkMode = event.curVal == Brightness.dark;
              startShowAnimation(isToDarkMode);
            }
          }
        }
      });
    }
  }

  ///取消监听消息事件
  void _cancelListenEvent() {
    if (_eventSubscription != null) {
      _eventSubscription?.cancel();
    }
  }

  void _reportDarkModeSwitch() {
    DataReportUtil.instance.reportData(eventName: "Click_darkmode", params: {"Click_darkmode": 1});
  }
}
