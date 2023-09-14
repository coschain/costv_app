import 'dart:async';

import 'package:costv_android/event/app_mode_switch_event.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/language/international_localizations_delegate.dart';
import 'package:costv_android/pages/splash_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/global.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/widget/app_mode_switch_toast.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sensors_analytics_flutter_plugin/sensors_analytics_flutter_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constant.dart';
import 'language/international_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  ///捕获同步异常，try/catch
  FlutterError.onError = (FlutterErrorDetails details) {
    if (Constant.isDebug) {
      /// 开发环境下只打印错误日志到控制台
      FlutterError.dumpErrorToConsole(details);
    } else {
      /// 生产环境下重定向到runZoned中处理
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  };
  runApp(CosTvApp());

  // ///捕获异步异常，Future
  // runZoned(() {
  //   // 限制竖屏
  //   WidgetsFlutterBinding.ensureInitialized();
  //   SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
  //   });
  // }, onError: (Object error, StackTrace stackTrace) {
  // });
}

class CosTvApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<StatefulWidget> createState() {
    return CosTvAppState();
  }
}

class CosTvAppState extends State<CosTvApp> with WidgetsBindingObserver {
  StreamSubscription? _eventMain;

  @override
  void initState() {
    super.initState();
    FacebookAudienceNetwork.init();
    WidgetsBinding.instance.addObserver(this);
    _listenEvent();
    initFirebase();
    initDevices();
    initSensor();
  }

  Future<void> initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelListenEvent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: InternationalLocalizations.title ?? '',
      theme: _getThemData(),
      home: SplashPage(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        InternationalLocalizationsDelegate.delegate,
      ],
      supportedLocales: [
        const Locale(InternationalLocalizations.languageCodeEn),
        const Locale(InternationalLocalizations.languageCodeKo),
        const Locale(InternationalLocalizations.languageCodePt_Br),
        const Locale(InternationalLocalizations.languageCodeRu),
        const Locale(InternationalLocalizations.languageCodeVi),
        const Locale(InternationalLocalizations.languageCodeZh_Cn),
        const Locale(InternationalLocalizations.languageCodeZh),
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        curLanguage = deviceLocale.toString();
        _loadSavedLan();
        return;
      },
      navigatorObservers: [
        routeObserver,
      ],
    );
  }

  ThemeData _getThemData() {
    return ThemeData(
      fontFamily: "Roboto",
      unselectedWidgetColor: Common.getColorFromHexString("858585", 1.0),
      brightness: brightnessModel,
      canvasColor: ThemeData.light().canvasColor,
    );
  }

  Future<String?> _loadSavedLan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? val = "";
    if (prefs.containsKey(savedLanKey)) {
      try {
        val = prefs.getString(savedLanKey);
        if (val != null && val != curLanguage) {
          curLanguage = val;
          Locale local = Locale(curLanguage);
          InternationalLocalizationsDelegate.delegate.load(local);
        }
      } catch (e) {}
    }
    return val;
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    if (!isSwitchedModeByUser && brightness != brightnessModel) {
      EventBusHelp.getInstance()
          .fire(SystemSwitchModeEvent(brightnessModel, brightness));
      brightnessModel = brightness;
      setState(() {
        _showModeSwitchToast(brightnessModel == Brightness.dark);
      });
    }
  }

  ///监听消息
  void _listenEvent() {
    if (_eventMain == null) {
      _eventMain = EventBusHelp.getInstance().on().listen((event) {
        if (event != null) {
          if (event is ManualSwitchModeEvent) {
            if (event.oldVal != event.curVal) {
              brightnessModel = event.curVal;
              setState(() {
                _showModeSwitchToast(brightnessModel == Brightness.dark);
              });
            }
          }
        }
      });
    }
  }

  ///取消监听消息事件
  void _cancelListenEvent() {
    if (_eventMain != null) {
      _eventMain?.cancel();
    }
  }

  void _showModeSwitchToast(bool isDarkMode) {
    Future.delayed(Duration(milliseconds: 500), () {
      AppModeSwitchToast.show(mainContext!, isDarkMode);
    });
  }

  void initDevices() async {
    await Global.init();
  }

  void initSensor() async {
    SensorsAnalyticsFlutterPlugin.init(
        serverUrl:"",
        autoTrackTypes: <SAAutoTrackType>{
          SAAutoTrackType.APP_START,
          SAAutoTrackType.APP_VIEW_SCREEN,
          SAAutoTrackType.APP_CLICK,
          SAAutoTrackType.APP_END
        },
        enableLog: true,
        visualized: VisualizedConfig(autoTrack: true, properties: true),
        android: AndroidConfig(
            maxCacheSize: 32 * 1024 * 1024,
            jellybean: true,
            subProcessFlush: true),
        ios: IOSConfig(maxCacheSize: 10000));
  }
}
