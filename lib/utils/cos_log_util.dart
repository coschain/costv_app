import 'package:costv_android/constant.dart';
import 'package:flutter/foundation.dart';

class CosLogUtil {
  static void log(Object str) {
    if(Constant.isPrint){
      debugPrint(str);
    }
  }
}
