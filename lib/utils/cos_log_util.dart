import 'package:costv_android/constant.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class CosLogUtil {
  static void log(String str) {
    if (Constant.isPrint) {
      debugPrint(str);
    }
  }

  static void i(String str) {
    var loggerWithStack = Logger(printer: PrefixPrinter(PrettyPrinter(methodCount: 6, colors: false, printTime: true)), filter: ProductionFilter());
    loggerWithStack.i(str);
  }

  static void e(String str) {
    var loggerWithStack = Logger(printer: PrefixPrinter(PrettyPrinter(methodCount: 6, colors: false, printTime: true)), filter: ProductionFilter());
    loggerWithStack.e(str);
  }
}
