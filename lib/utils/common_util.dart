import 'dart:math';

import 'package:common_utils/common_utils.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:decimal/decimal.dart';
import 'package:costv_android/utils/revenue_calculation_util.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:cosdart/types.dart';

const String tokenErrCode = "11011";

class Common {
  static bool checkIsNotEmptyStr(String str) {
    if (str != null && str.length > 0) {
      return true;
    }
    return false;
  }

  ///视频显示规则
  ///
  static String calcDiffTimeByStartTime(String stamp) {
    String diffStr = "";
    if (checkIsNotEmptyStr(stamp)) {
      int tNowStamp = DateTime.now().millisecondsSinceEpoch;
      int startStamp = int.tryParse(stamp) ?? 0;
      if (startStamp == 0 || startStamp > tNowStamp) {
        return diffStr;
      }
      startStamp *= 1000;
      int diff = tNowStamp - startStamp;
      Duration duration = Duration(milliseconds: diff);
      DateTime sDate = DateTime.fromMillisecondsSinceEpoch(startStamp);
      if (duration.inDays > 0) {
        if (duration.inDays >= 365) {
          //跨越自然年，显示：年份+月份+日期 例如：2019年12月12日
//          return InternationalLocalizations.yearMonthDay(sDate.year.toString(),
//              sDate.month.toString(), sDate.day.toString());
          return '${sDate.year.toString()}.${sDate.month.toString()}.${sDate.day.toString()}';
        } else if (duration.inDays >= 3) {
          //三天及到自然年，显示：月份+日期，例如：12月12日
//          return InternationalLocalizations.monthDay(
//              sDate.month.toString(), sDate.day.toString());
          return '${sDate.month.toString()}.${sDate.day.toString()}';
        } else {
          //二十四小时到三天内（不含），显示天数，例如：两天前
          return InternationalLocalizations.dayAgo(duration.inDays.toString());
        }
      } else if (duration.inHours > 0) {
        //一小时到24小时内（不含），显示小时数：例如：1小时前
        return InternationalLocalizations.hourAgo(duration.inHours.toString());
      } else if (duration.inMinutes > 0) {
        //一小时内（不含），显示分钟数
        return InternationalLocalizations.minuteAgo(
            duration.inMinutes.toString());
      } else {
        //小于1分钟就显示1分钟以前
        return InternationalLocalizations.minuteAgo('1');
      }
    }
    return diffStr;
  }

  static bool checkVideoDurationValid(String vDuration) {
    if (checkIsNotEmptyStr(vDuration)) {
      double dVal = double.tryParse(vDuration) ?? 0.0;
      if (dVal <= 1) {
        return false;
      }
      return true;
    }
    return false;
  }

  static String formatVideoDuration(String vDuration) {
    String durationStr = "00:00";
    if (checkIsNotEmptyStr(vDuration)) {
      double dVal = double.tryParse(vDuration) ?? 0.0;
      if (dVal == 0.0) {
        return durationStr;
      }
      double milliVal = dVal * 1000;
      Duration duration = Duration(milliseconds: milliVal.floor());
      if (dVal < 0.1) {
        return "00:001";
      } else if (dVal < 1) {
        return "00:" + (dVal * 10).toInt().toString().padLeft(3, '0');
      } else if (dVal < 3600) {
        return [duration.inMinutes, duration.inSeconds]
            .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
            .join(':');
      }
      {
        return [duration.inHours, duration.inMinutes]
            .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
            .join(':');
      }
    }
    return durationStr;
  }

  static Color getColorFromHexString(String colorStr, double alpha) {
    if (checkIsNotEmptyStr(colorStr)) {
      return Color(int.parse(colorStr, radix: 16)).withOpacity(alpha);
    }
    return Colors.white;
  }

  static bool isTimeCompareMoreThan(String time, String duration) {
    if (ObjectUtil.isEmptyString(time) || ObjectUtil.isEmptyString(duration)) {
      return false;
    }
    String videoDuration;
    if (duration.lastIndexOf('.') >= 0) {
      videoDuration = duration.substring(0, duration.lastIndexOf('.'));
    } else {
      videoDuration = duration;
    }
    List<String> listTime = time.split('.');
    List<String> listDuration = videoDuration.split('.');
    int timeIndex = 0;
    if (listTime.length > listDuration.length) {
      timeIndex = 3 - listDuration.length;
    } else {
      for (int i = 0; i < listTime.length; i++) {
        if (!ObjectUtil.isEmptyString(listTime[i])) {
          timeIndex = i;
          break;
        }
      }
    }
    for (int i = timeIndex, j = 0;
        i < listTime.length || j < listDuration.length;
        i++, j++) {
      if (double.parse(listTime[i]) > double.parse(listDuration[j])) {
        return true;
      }
    }
    return false;
  }

  static bool isUpdate(String localVersion, String netVersion) {
    if (ObjectUtil.isEmptyString(localVersion) ||
        ObjectUtil.isEmptyString(netVersion)) {
      return false;
    }
    List<String> listLocalVersion = localVersion.split('.');
    List<String> listNetVersion = netVersion.split('.');
    int length;
    if (listLocalVersion.length <= listNetVersion.length) {
      length = listLocalVersion.length;
    } else {
      length = listNetVersion.length;
    }
    for (int i = 0; i < length; i++) {
      if (double.parse(listNetVersion[i]) > double.parse(listLocalVersion[i])) {
        return true;
      }
    }
    return false;
  }

  /// 通过本地语言码获取请求接口时传给服务端的语言码
  /// isOperation: 是否运营位相关接口
  static String getRequestLanCodeByLanguage(bool isOperation) {
    String lan = curLanguage;
    if (lan != null) {
      if (lan.startsWith("en")) {
        return "en";
      } else if (lan.startsWith("ja")) {
        return "jp";
      } else if (lan.startsWith("ko")) {
        return "ko";
      } else if (lan.startsWith("vi")) {
        return "vi";
      } else if (lan.startsWith("pt")) {
        return "pt-br";
      } else if (lan.startsWith("ru")) {
        return "ru";
      } else if (lan.startsWith("tr")) {
        return "tr";
      } else if (lan.startsWith("zh")) {
        //简体
        if (lan.startsWith("zh_Hans") || lan.startsWith("zh_CN")) {
          if (isOperation) {
            return "zh-cn";
          }
          return "cn";
        }
        //繁体
        if (isOperation) {
          return "zh";
        }
        return "tw";
      }
    }
    return "en";
  }

  static bool checkIsTraditionalChinese(String lan) {
    if (lan.startsWith("zh") && !Common.checkIsSimplifiedChinese(lan)) {
      return true;
    }
    return false;
  }

  static bool checkIsSimplifiedChinese(String lan) {
    if (lan.startsWith("zh") && (lan.startsWith("zh_Hans") || lan.startsWith("zh_CN"))) {
      return true;
    }
    return false;
  }

  ///检查用户是否已经登录
  static bool judgeHasLogIn() {
    if (checkIsNotEmptyStr(Constant.uid) &&
        checkIsNotEmptyStr(Constant.token)) {
      return true;
    }
    return false;
  }

  ///通过当前语言获取货币符号
  static String getCurrencySymbolByLanguage({String lan}) {
    lan = lan ?? curLanguage;
    if (lan != null) {
      if (lan.startsWith("en")) {
        //美国货币符号
        return "\$";
      } else if (lan.startsWith("ja")) {
        //日本货币符号
        return "J.￥";
      } else if (lan.startsWith("ko")) {
        //韩国货币符号
        return "₩";
      } else if (lan.startsWith("vi")) {
        //越南货币符号
        return "₫";
      } else if (lan.startsWith("pt")) {
        //巴西葡萄牙语货币符号
        return "R\$";
      } else if (lan.startsWith("ru")) {
        //俄语货币符号
        return "₽";
      } else if (lan.startsWith("zh")) {
        //人民币符号
        if (lan.startsWith("zh_Hans") || lan.startsWith("zh_CN")) {
          return "￥";
        }
        //台币符号
        return "NT\$";
      } else if (lan.startsWith("tr")) {
        //土耳其货币符号
        return "₺";
      }
    }
    return "\$";
  }

  ///通过当前语言获取货币
  static String getCurrencyMoneyByLanguage({String lan}) {
    lan = lan ?? curLanguage;
    if (lan != null) {
      if (lan.startsWith("en")) {
        //美国货币
        return "usd";
      } else if (lan.startsWith("ja")) {
        //日本货币
        return "jpy";
      } else if (lan.startsWith("ko")) {
        //韩国货币
        return "krw";
      } else if (lan.startsWith("vi")) {
        //越南货币
        return "vnd";
      } else if (lan.startsWith("pt")) {
        //巴西葡萄牙语货币
        return "brl";
      } else if (lan.startsWith("ru")) {
        //俄语货币
        return "rub";
      } else if (lan.startsWith("zh")) {
        //人民币
        if (lan.startsWith("zh_Hans") || lan.startsWith("zh_CN")) {
          return "cny";
        }
        //台币
        return "twd";
      } else if (lan.startsWith("tr")) {
        //土耳其货币
        return "try";
      }
    }
    return "usd";
  }

  ///通过当前语言获取时间选择弹出框语言
  static LocaleType getTimeShowByLanguage({String lan}) {
    lan = lan ?? curLanguage;
    if (lan != null) {
      if (lan.startsWith("en")) {
        //美国
        return LocaleType.en;
      } else if (lan.startsWith("ja")) {
        //日本
        return LocaleType.jp;
      } else if (lan.startsWith("ko")) {
        //韩国
        return LocaleType.ko;
      } else if (lan.startsWith("vi")) {
        //越南
        return LocaleType.vi;
      } else if (lan.startsWith("pt")) {
        //巴西葡萄牙
        return LocaleType.pt;
      } else if (lan.startsWith("ru")) {
        //俄语
        return LocaleType.ru;
      } else if (lan.startsWith("zh")) {
        //中国
        return LocaleType.zh;
      } else if (lan.startsWith("tr")) {
        //土耳其
        return LocaleType.tr;
      }
    }
    return LocaleType.en;
  }

  ///通过当前系统语言获取通用标识语言
  static String getLanCodeByLanguage() {
    String lan = curLanguage;
    if (lan != null) {
      if (lan.startsWith("en")) {
        //美国
        return InternationalLocalizations.languageCodeEn;
      } else if (lan.startsWith("ko")) {
        //韩国
        return InternationalLocalizations.languageCodeKo;
      } else if (lan.startsWith("vi")) {
        //越南
        return InternationalLocalizations.languageCodeVi;
      } else if (lan.startsWith("pt")) {
        //巴西葡萄牙
        return InternationalLocalizations.languageCodePt_Br;
      } else if (lan.startsWith("ru")) {
        //俄罗斯
        return InternationalLocalizations.languageCodeRu;
      } else if (lan.startsWith("tr")) {
        //土耳其
        return InternationalLocalizations.languageCodeTr;
      } else if (lan.startsWith("zh")) {
        //中国
        //简体
        if (lan.startsWith("zh_Hans") || lan.startsWith("zh_CN")) {
          return InternationalLocalizations.languageCodeZh_Cn;
        }
        //繁体
        return InternationalLocalizations.languageCodeZh;
      }
    }
    return "en";
  }

  static bool isEn() {
    String lan = curLanguage;
    if (lan == null || lan.startsWith("en")) {
      return true;
    } else {
      return false;
    }
  }

  static String formatAmount(String amount) {
    if (!checkIsNotEmptyStr(amount)) {
      return "0";
    }
    int pIdx = amount.indexOf(".");
    if (pIdx != -1) {
      String pre = amount.substring(0,pIdx);
      String suffix = amount.substring(pIdx,amount.length);
      pre = pre.replaceAllMapped(
          new RegExp(r"(\d)(?=(?:\d{3})+\b)"), (match) => "${match.group(1)},");
      return pre + suffix;
    }
    amount = amount.replaceAllMapped(
        new RegExp(r"(\d)(?=(?:\d{3})+\b)"), (match) => "${match.group(1)},");
    return amount;
  }

  static DateTime _lastTime;
  static const int clickMilliSeconds = 500;

  static bool isAbleClick() {
    if (_lastTime == null ||
        DateTime.now().difference(_lastTime) >
            Duration(milliseconds: clickMilliSeconds)) {
      _lastTime = DateTime.now();
      return true;
    } else {
      _lastTime = DateTime.now();
      return false;
    }
  }

  static Decimal getUserMaxPower(AccountInfo acctInfo) {
    if (acctInfo != null && acctInfo.vest != null) {
      Decimal vestDec = Decimal.fromInt(acctInfo.vest.value.toInt());
      vestDec *= Decimal.fromInt(33);
      return vestDec;
    }
    return Decimal.fromInt(0);
  }

  static String getAddedWorth(AccountInfo acctInfo, ExchangeRateInfoData exchangeRateInfoData,
   chainStateBean, bool isVideo) {
    Decimal maxPower = getUserMaxPower(acctInfo);
    print("maxPower is ${maxPower.toString()}");
    double settlementBonusVest = RevenueCalculationUtil.getVideoRevenueVest(
        maxPower.toStringAsFixed(0), chainStateBean?.dgpo);
    if (!isVideo) {
      settlementBonusVest = RevenueCalculationUtil.getReplyVestByPower(maxPower.toStringAsFixed(0), chainStateBean?.dgpo);
    }
    double val = RevenueCalculationUtil.vestToRevenue(
        settlementBonusVest, exchangeRateInfoData);
    print("val is $val");
    if (val > 0) {
      return val.toStringAsFixed(2);
    }
    return "";
  }

  static String formatDecimalDigit(double val, int digit) {
    if (val != null) {
      if (digit == null) {
        digit = 2;
      }
      //使用decimal转换一下，可以将e-1转成0.1
      Decimal decimal = Decimal.parse(val.toString());
      String valStr = decimal.toString();
      int len = valStr.length;
      int pIdx = valStr.indexOf(".");
      if (pIdx == -1) {
        //没有小数,直接使用原始值，不用加0
        return valStr;
      }
      int digitNum = len - 1 - pIdx;
      //大于1时，保留digit位小数
      if (val >= 1.0) {
         if (digitNum < digit) {
           return valStr;
         }
         return decimal.toStringAsFixed(2);
      } else {
        //小于1时,保留digit位有效数字
        int nonZeroIdx = pIdx + 1;
        for (int i = nonZeroIdx; i < len; i++) {
          if (valStr[i] != "0") {
            nonZeroIdx = i;
            break;
          }
        }
        if (nonZeroIdx < len) {
          int lessDigit = nonZeroIdx + digit - len;
          if (lessDigit <= 0) {
             return decimal.toStringAsFixed(nonZeroIdx);
          } else {
            for (int j = 0; j < lessDigit; j++) {
              valStr += "0";
            }
            return valStr;
          }
        } else {
          return valStr;
        }
      }

    }
    return "0";
  }

  static String calcVideoAddedIncome(AccountInfo acctInfo,
      ExchangeRateInfoData exchangeRateInfoData,
      ChainState chainStateBean,String oldPower,String giftVest) {
    if (acctInfo != null && exchangeRateInfoData != null && chainStateBean != null
        && oldPower != null && giftVest != null) {
        double oldVest = RevenueCalculationUtil.getTotalRevenueVest(oldPower, giftVest, chainStateBean.dgpo);
        double oldVal = RevenueCalculationUtil.vestToRevenue(oldVest, exchangeRateInfoData);
        Decimal maxPower = getUserMaxPower(acctInfo);
        Decimal oldPowerDec = Decimal.parse(oldPower);
        Decimal newPowerDec = (maxPower + oldPowerDec);
        double newVest =  RevenueCalculationUtil.getTotalRevenueVest(newPowerDec.toStringAsFixed(0), giftVest, chainStateBean.dgpo);
        double newVal = RevenueCalculationUtil.vestToRevenue(newVest, exchangeRateInfoData);
        double diff = newVal - oldVal;
        if (diff > 0) {
          return formatDecimalDigit(diff, 2);
        }
    }
    return "";
  }

  static String calcCommentAddedIncome(AccountInfo acctInfo,
      ExchangeRateInfoData exchangeRateInfoData,
      ChainState chainStateBean,String oldPower) {
    if (acctInfo != null && exchangeRateInfoData != null && chainStateBean != null
        && oldPower != null) {
        double oldVest = RevenueCalculationUtil.getReplyVestByPower(oldPower, chainStateBean.dgpo);
        double oldVal = RevenueCalculationUtil.vestToRevenue(oldVest, exchangeRateInfoData);
        Decimal maxPower = getUserMaxPower(acctInfo);
        Decimal oldPowerDec = Decimal.parse(oldPower);
        Decimal newPowerDec = (maxPower + oldPowerDec);
        double newVest =  RevenueCalculationUtil.getReplyVestByPower(newPowerDec.toStringAsFixed(0),chainStateBean.dgpo);
        double newVal = RevenueCalculationUtil.vestToRevenue(newVest, exchangeRateInfoData);
        double diff = newVal - oldVal;
        if (diff > 0) {
          return formatDecimalDigit(diff, 2);
        }
    }
    return "";
  }
}
