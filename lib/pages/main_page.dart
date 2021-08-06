import 'dart:async';

import 'package:costv_android/constant.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/login_status_event.dart';
import 'package:costv_android/event/tab_switch_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/home_page.dart';
import 'package:costv_android/pages/my_subscription_page.dart';
import 'package:costv_android/pages/popular_page.dart';
import 'package:costv_android/pages/recently_watched_page.dart';
import "package:costv_android/utils/global_util.dart";
import 'package:costv_android/values/app_styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_analytics_flutter_plugin/sensors_analytics_flutter_plugin.dart';
import 'package:wakelock/wakelock.dart';

class MainPage extends StatefulWidget {
  MainPage({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const tag = '_MainPageState';
   static const String CHANNEL_PUSH_MESSAGE = "com.contentos.plugin/push_message";
   static const String PUSH_MESSAGE_OPEN_SUBSCRIPTION = "open_subscription";
  var _tabImages;
  int _tabIndex = 0;
  StreamSubscription _streamSubscription;
  static const _methodChannelPush = const MethodChannel(CHANNEL_PUSH_MESSAGE);

  @override
  void initState() {
    super.initState();
    // 保持屏幕唤醒
    Wakelock.enable();
    _initData();
    _methodChannelPush.setMethodCallHandler(_listenPushMessage);
    _listenBusEvent();
    _httpAddDevice();
  }

  @override
  void dispose() {
    super.dispose();
    RequestManager.instance.cancelAllNetworkRequest(tag);
    if (_streamSubscription != null) {
      _streamSubscription.cancel();
      _streamSubscription = null;
    }
  }

  _initData() {
    _tabImages = [
      [
        _getTabImage('assets/images/ic_home.png'),
        _getTabImage('assets/images/ic_home_select.png')
      ],
      [
        _getTabImage('assets/images/ic_popular.png'),
        _getTabImage('assets/images/ic_popular_select.png')
      ],
      [
        _getTabImage('assets/images/ic_my_subscription.png'),
        _getTabImage('assets/images/ic_my_subscription_select.png')
      ],
      [
        _getTabImage('assets/images/ic_see_history.png'),
        _getTabImage('assets/images/ic_see_history_select.png')
      ]
    ];
  }

  Future<dynamic> _listenPushMessage(MethodCall methodCall) async {
    switch (methodCall.method) {
      case PUSH_MESSAGE_OPEN_SUBSCRIPTION:
        setState(() {
          _tabIndex = 2;
        });
        break;
    }
  }


  void _listenBusEvent() {
    EventBusHelp.getInstance().on<LoginStatusEvent>().listen((event) {
      if (event != null &&
          event is LoginStatusEvent &&
          event.type == LoginStatusEvent.typeLoginSuccess) {
        _httpAddDevice();
      }
    });
  }

  /// app设备上报接口
  void _httpAddDevice() {
    RequestManager.instance.addDevice(tag, Constant.uid ?? '').then((response) {
      if (response == null || !mounted) {
        return;
      }
    });
  }

  TextStyle _getTabTextStyle(int curIndex) {
    if (curIndex == _tabIndex) {
      return AppStyles.text_style_3674ff_9;
    }
    return AppStyles.text_style_333333_9;
  }

  Image _getTabImage(path) {
    return Image.asset(path);
  }

  Image _getTabIcon(int curIndex) {
    if (curIndex == _tabIndex) {
      return _tabImages[curIndex][1];
    }
    return _tabImages[curIndex][0];
  }

  @override
  Widget build(BuildContext context) {
    SensorsAnalyticsFlutterPlugin.profileSet({"Age": 18});
    return Scaffold(
      body: IndexedStack(
        children: <Widget>[
          HomePage(),
          PopularPage(),
          MySubscriptionPage(),
          RecentlyWatchedPage(),
        ],
        index: _tabIndex,
      ),
      bottomNavigationBar: CupertinoTabBar(
        // 强制指定bottom bar的背景色为亮灰色，否则ios指定暗色主题时背景会变黑，导致字看不清。
        backgroundColor: CupertinoColors.extraLightBackgroundGray,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: _getTabIcon(0),
              title: Text(InternationalLocalizations.homeTitle,
                  textAlign: TextAlign.center, style: _getTabTextStyle(0))),
          BottomNavigationBarItem(
              icon: _getTabIcon(1),
              title: Text(InternationalLocalizations.homePopularTitle,
                  textAlign: TextAlign.center, style: _getTabTextStyle(1))),
          BottomNavigationBarItem(
              icon: _getTabIcon(2),
              title: Text(
                InternationalLocalizations.homeMySubscriptionTitle,
                textAlign: TextAlign.center,
                style: _getTabTextStyle(2),
              )),
          BottomNavigationBarItem(
              icon: _getTabIcon(3),
              title: Text(
                InternationalLocalizations.homeSeeHistoryTitle,
                textAlign: TextAlign.center,
                style: _getTabTextStyle(3),
              )),
        ],
        currentIndex: _tabIndex,
        onTap: (index) {
          EventBusHelp.getInstance().fire(TabSwitchEvent(curTabIndex, index));
          curTabIndex = index;
          setState(() {
            _tabIndex = index;
          });
        },
      ),
    );
  }
}
