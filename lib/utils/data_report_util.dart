
import 'package:costv_android/constant.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/platform_util.dart';
import 'package:sensors_analytics_flutter_plugin/sensors_analytics_flutter_plugin.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:costv_android/utils/global_util.dart';

class DataReportUtil {
  static DataReportUtil? _instance;

  factory DataReportUtil() => _getInstance();

  static DataReportUtil get instance => _getInstance();
  FirebaseAnalytics? firebaseAnalytics;

  DataReportUtil._();

  static DataReportUtil _getInstance() {
    if (_instance == null) {
      _instance = DataReportUtil._();
      _instance?.firebaseAnalytics = FirebaseAnalytics.instance;
    }
    return _instance!;
  }

  void reportData({required String eventName, required Map<String, dynamic> params}) async {
    if (eventName == null) {
      return;
    }
    if (params == null) {
      params = {};
    }
    String curAid = aid;
    if (!Common.checkIsNotEmptyStr(curAid)) {
      //获取aid
      curAid = await PlatformUtil.getDeviceID();
      aid = curAid;
    }
    CosLogUtil.log("DataReportUtil eventName = $eventName");
    CosLogUtil.log("DataReportUtil params = $params");
    //神策上报
    //设置公共属性,目前flutter插件不支持动态设置公共属性
    SensorsAnalyticsFlutterPlugin.registerSuperProperties({
      "selfuid": Constant.uid ?? "",
      "aid": curAid ?? '',
    });
    SensorsAnalyticsFlutterPlugin.track(eventName, params);
    //firbase 上报
    params["selfuid"] = Constant.uid ?? "";
    params["aid"] = curAid ?? '';
    this.firebaseAnalytics?.logEvent(name: eventName, parameters: params);
  }
}