
import 'package:costv_android/constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:sensors_analytics_flutter_plugin/sensors_analytics_flutter_plugin.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class DataReportUtil {
  static DataReportUtil _instance;

  factory DataReportUtil() => _getInstance();

  static DataReportUtil get instance => _getInstance();
  FirebaseAnalytics firebaseAnalytics;
  DataReportUtil._();

  static DataReportUtil _getInstance() {
    if (_instance == null) {
      _instance = DataReportUtil._();
      _instance.firebaseAnalytics = FirebaseAnalytics();
    }
    return _instance;
  }

  void reportData({@required String eventName, @required Map<String,dynamic> params}) {
    if (eventName == null) {
      return;
    }
    if (params == null) {
      params = {};
    }
    //神策上报
    //设置公共属性,目前flutter插件不支持动态设置公共属性
    SensorsAnalyticsFlutterPlugin.registerSuperProperties({"uid": Constant.uid ?? ""});
    SensorsAnalyticsFlutterPlugin.track(eventName, params);
    //firbase 上报
    params["uid"] = Constant.uid ?? "";
    this.firebaseAnalytics.logEvent(name: eventName, parameters: params);
  }

}