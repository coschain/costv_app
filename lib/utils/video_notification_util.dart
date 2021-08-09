import 'package:costv_android/utils/cos_log_util.dart';
import 'package:flutter/services.dart';

class VideoNotificationUtil {


  static const platformNotification =
      const MethodChannel('com.contentos.plugin/notification');

  static VideoNotificationUtil _instance;

  factory VideoNotificationUtil() => _getInstance();

  static VideoNotificationUtil get instance => _getInstance();

  VideoNotificationUtil._();

  static VideoNotificationUtil _getInstance() {
    if (_instance == null) {
      _instance = VideoNotificationUtil._();
    }
    return _instance;
  }

  openVideoNotification(String data) async {
    try {
      await platformNotification.invokeMethod('open_video_notification', data);
    } on PlatformException catch (e) {
      CosLogUtil.log(e.toString());
    }
  }

  closeVideoNotification() async {
    try {
      await platformNotification.invokeMethod('close_video_notification', '');
    } on PlatformException catch (e) {
      CosLogUtil.log(e.toString());
    }
  }

}
