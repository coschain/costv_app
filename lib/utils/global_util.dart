import 'package:flutter/material.dart';

enum BottomTabType {
  TabHome, //首页
  TabHot, //热门
  TabSubscription, //订阅
  TabWatchHistory, //观看历史
}

String curLanguage = "en";
String savedLanKey = "appLanKey";
int curTabIndex = 0;
RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
