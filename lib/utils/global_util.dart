import 'package:flutter/material.dart';

enum BottomTabType {
  TabHome, //首页
  TabHot, //热门
  TabSubscription, //订阅
  TabMessageCenter, //消息中心
  TabWatchHistory, //观看历史
}

String curLanguage = "en";
String savedLanKey = "appLanKey";
int curTabIndex = 0;
bool usrAutoPlaySetting = false; //默认关闭
String videoDetailPageRouteName = "videoDetailPageRoute";
RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
String aid = '';
Brightness brightnessModel = Brightness.light;
bool isSwitchedModeByUser = false;
BuildContext? mainContext; //main page context