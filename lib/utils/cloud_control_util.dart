
import 'dart:convert';
import 'dart:io';

import 'package:costv_android/bean/cos_tv_cloud_control_bean.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/cloud_control_event.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/utils/cos_log_util.dart';

const maxFetchTimes = 3;//最多获取的次数

class CloudControlUtil {
  static CloudControlUtil _instance;
  factory CloudControlUtil() => _getInstance();
  static CloudControlUtil get instance => _getInstance();
  bool isShowPop = false;
  bool isFetching = false;
  String tag = "CloudControl";
  CloudControlData controlData;
  int fetchTimes = 0;
  CloudControlUtil._();

  static CloudControlUtil _getInstance() {
    if (_instance == null) {
      _instance = CloudControlUtil._();
    }
    return _instance;
  }

  Future<void> fetchCloudControl() async{
    if (isFetching) {
      return;
    }
    isFetching = true;
    fetchTimes++;
    RequestManager.instance.getCloudControl(tag: tag)
        .then((response) {
      CosTvCloudControlBean bean = CosTvCloudControlBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data != null) {
          controlData = bean.data;
          if (controlData.pop == "1") {
            isShowPop = true;
          } else {
            isShowPop = false;
          }
          if(Platform.isIOS){
            isShowPop = false;
          }
          EventBusHelp.getInstance().fire(CloudControlFinishEvent(true));
        }
      } else {
        CosLogUtil.log("$tag: fetch cloud control data fail, the error is "
            "code:${bean?.toString() ?? ""},msg:${bean?.msg ?? ""}");
        EventBusHelp.getInstance().fire(CloudControlFinishEvent(false));
        isFetching = false;
        if (fetchTimes < maxFetchTimes) {
          fetchCloudControl();
        }
      }
    }).catchError((err) {
      CosLogUtil.log("$tag: fetch cloud control data exception, the error is $err");
      EventBusHelp.getInstance().fire(CloudControlFinishEvent(false));
      isFetching = false;
      if (fetchTimes < maxFetchTimes) {
        fetchCloudControl();
      }
    }).whenComplete(() {
      isFetching = false;
    });
  }

  bool getIsShowPop() {
    return isShowPop;
  }

  CloudControlData getCloudControlData() {
    return controlData;
  }
}