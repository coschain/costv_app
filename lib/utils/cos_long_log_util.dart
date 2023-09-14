import 'package:costv_android/constant.dart';
import 'package:flutter/material.dart';

class CosLongLogUtil {
  static var _separator = "=";
  static var _split =
      "$_separator$_separator$_separator$_separator$_separator$_separator$_separator$_separator$_separator";
  static var _title = "CosLong-Log";
  static int _limitLength = 800;
  static String _startLine = "$_split$_title$_split";
  static String _endLine = "$_split$_separator$_separator$_separator$_split";

  static void init({required String title, required int limitLength}) {
    _title = title;
    _limitLength = limitLength ??= _limitLength;
    _startLine = "$_split$_title$_split";
    var endLineStr = StringBuffer();
    var cnCharReg = RegExp("[\u4e00-\u9fa5]");
    for (int i = 0; i < _startLine.length; i++) {
      if (cnCharReg.stringMatch(_startLine[i]) != null) {
        endLineStr.write(_separator);
      }
      endLineStr.write(_separator);
    }
    _endLine = endLineStr.toString();
  }

  static void log(String msg) {
    if (Constant.isPrint) {
      debugPrint("$_startLine");
      _logEmpyLine();
      if (msg.length < _limitLength) {
        debugPrint(msg);
      } else {
        segmentationLog(msg);
      }
      _logEmpyLine();
      debugPrint("$_endLine");
    }
  }

  static void segmentationLog(String msg) {
    var outStr = StringBuffer();
    for (var index = 0; index < msg.length; index++) {
      outStr.write(msg[index]);
      if (index % _limitLength == 0 && index != 0) {
        debugPrint(outStr.toString());
        outStr.clear();
        var lastIndex = index + 1;
        if (msg.length - lastIndex < _limitLength) {
          var remainderStr = msg.substring(lastIndex, msg.length);
          debugPrint(remainderStr);
          break;
        }
      }
    }
  }

  static void _logEmpyLine() {
    debugPrint("");
  }
}
