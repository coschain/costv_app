import 'package:costv_android/utils/cos_log_util.dart';
import 'package:flutter/services.dart';

class VideoSmallWindowsUtil {
  static const platformSdk =
      const MethodChannel('com.contentos.plugin/video_small_windows');

  static VideoSmallWindowsUtil _instance;

  factory VideoSmallWindowsUtil() => _getInstance();

  static VideoSmallWindowsUtil get instance => _getInstance();

  VideoSmallWindowsUtil._();

  static VideoSmallWindowsUtil _getInstance() {
    if (_instance == null) {
      _instance = VideoSmallWindowsUtil._();
    }
    return _instance;
  }

  openVideoSmallWindows(String data) async {
    try {
      await platformSdk.invokeMethod('open_windows', data);
    } on PlatformException catch (e) {
      CosLogUtil.log(e.toString());
    }
  }

}
