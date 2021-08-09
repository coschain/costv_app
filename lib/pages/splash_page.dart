import 'dart:async';

import 'package:costv_android/constant.dart';
import 'package:costv_android/db/login_info_db_bean.dart';
import 'package:costv_android/db/login_info_db_provider.dart';
import 'package:costv_android/pages/main_page.dart';
import 'package:costv_android/utils/cloud_control_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import "package:costv_android/utils/data_report_util.dart";
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SplashPageState();
  }
}

class _SplashPageState extends State<SplashPage> {
  static const tag = '_SplashPageState';
  static const waitTime = 1500;

  int _timeBegin;

  @override
  void initState() {
    super.initState();
    _initData();
    CloudControlUtil.instance.fetchCloudControl();
  }

  Future _initData() async {
    _timeBegin = DateTime.now().millisecondsSinceEpoch;
    CosLogUtil.log("$tag _timeBegin = $_timeBegin");
    LoginInfoDbProvider loginInfoDbProvider = LoginInfoDbProvider();
    try {
      await loginInfoDbProvider.open();
      LoginInfoDbBean loginInfoDbBean =
          await loginInfoDbProvider.getLoginInfoDbBean();
      if (loginInfoDbBean != null) {
        Constant.uid = loginInfoDbBean.getUid;
        Constant.token = loginInfoDbBean.getToken;
        Constant.accountName = loginInfoDbBean.getChainAccountName;
        MethodChannel methodChannelLogin =
            MethodChannel(MainPageState.channelLogin);
        methodChannelLogin.invokeMethod(
            MainPageState.loginSetLoginInfo, Constant.uid);
      }
    } catch (e) {
      CosLogUtil.log("$tag: e = $e");
    } finally {
      await loginInfoDbProvider.close();
      int timeEnd = DateTime.now().millisecondsSinceEpoch;
      CosLogUtil.log("$tag timeEnd = $timeEnd");
      CosLogUtil.log("$tag time = ${timeEnd - _timeBegin}");
      if ((timeEnd - _timeBegin) < waitTime) {
        CosLogUtil.log("$tag wait");
        Future.delayed(
            Duration(milliseconds: waitTime - (timeEnd - _timeBegin)), () {
          Navigator.pushAndRemoveUntil(
            context,
            SlideAnimationRoute(
              builder: (_) {
                return MainPage();
              },
            ),
            (route) => route == null,
          );
        });
      } else {
        CosLogUtil.log("$tag no wait");
        Navigator.pushAndRemoveUntil(
          context,
          SlideAnimationRoute(
            builder: (_) {
              return MainPage();
            },
          ),
          (route) => route == null,
        );
      }
      _reportSplashStart(_timeBegin.toString());
      _reportStartWithDarkMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    brightnessModel = MediaQuery.of(context).platformBrightness;
    double statusHeight = MediaQuery.of(context).padding.top;
    return Material(
      child: Container(
        margin: EdgeInsets.only(top: statusHeight),
        child: Image.asset(
          'assets/images/bg_startup_logo.webp',
          fit: BoxFit.cover,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height - statusHeight,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _reportSplashStart(String startTime) {
    DataReportUtil.instance
        .reportData(eventName: "Splash", params: {"start": startTime});
  }

  void _reportStartWithDarkMode() {
    if (brightnessModel == Brightness.dark) {
      DataReportUtil.instance.reportData(
          eventName: "Start_darkmode", params: {"Start_darkmode": "1"});
    }
  }
}
