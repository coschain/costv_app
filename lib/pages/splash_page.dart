import 'dart:async';

import 'package:costv_android/constant.dart';
import 'package:costv_android/db/login_info_db_bean.dart';
import 'package:costv_android/db/login_info_db_provider.dart';
import 'package:costv_android/pages/main_page.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/material.dart';
import "package:costv_android/utils/data_report_util.dart";

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
        Future.delayed(Duration(milliseconds: waitTime - (timeEnd - _timeBegin)), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
            (route) => route == null,
          );
        });
      } else {
        CosLogUtil.log("$tag no wait");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
          (route) => route == null,
        );
      }
      _reportSplashStart(_timeBegin.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    double statusHeight = MediaQuery.of(context).padding.top;
    return Material(
      child: Container(
        margin: EdgeInsets.only(top: statusHeight),
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Image.asset(
              'assets/images/bg_startup_diagram.png',
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height - statusHeight,
            ),
            Container(
              margin: EdgeInsets.only(top: AppDimens.margin_177),
              child: Image.asset('assets/images/ic_logo.png'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _reportSplashStart(String startTime) {
    DataReportUtil.instance.reportData(eventName: "Splash", params: {"start": startTime});
  }
}
