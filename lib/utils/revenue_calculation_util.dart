import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:cosdart/types.dart';

class RevenueCalculationUtil {
  RevenueCalculationUtil._();

  static const int cosUnit = 1000000;
  static const int lowestEnergyRatio = 33;
  static const int energyUnit = 1000;

  ///获得结算奖金Vest
  static double getVideoRevenueVest(String votePower, dynamic_properties? chainStateDgpoBean) {
    if (!TextUtil.isEmpty(votePower) &&
        chainStateDgpoBean != null &&
        !TextUtil.isEmpty(chainStateDgpoBean.weightedVpsPost)) {
      double vp = double.parse(votePower);
      double r1 = NumUtil.add(vp, double.parse(chainStateDgpoBean.weightedVpsPost));
      return NumUtil.multiply(vp, chainStateDgpoBean.poolPostRewards.value.toInt()) / r1 / cosUnit;
    } else {
      return 0;
    }
  }

  /// 获得礼物票收益Vest
  static double getGiftRevenueVest(String vestGift) {
    if (!TextUtil.isEmpty(vestGift)) {
      return NumUtil.divide(double.parse(vestGift), cosUnit);
    } else {
      return 0;
    }
  }

  /// 获得总共收益Vest
  static double getTotalRevenueVest(String votePower, String vestGift, dynamic_properties? chainStateDgpoBean) {
    if (!TextUtil.isEmpty(votePower) && !TextUtil.isEmpty(vestGift)) {
      return NumUtil.add(getVideoRevenueVest(votePower, chainStateDgpoBean), getGiftRevenueVest(vestGift));
    } else {
      return 0;
    }
  }

  /// 将reply的power转为vest
  static double getReplyVestByPower(String power, dynamic_properties? chainStateDgpoBean) {
    if (!TextUtil.isEmpty(power) && chainStateDgpoBean != null && !TextUtil.isEmpty(chainStateDgpoBean.weightedVpsReply)) {
      double vp = double.parse(power);
      double r1 = NumUtil.add(vp, double.parse(chainStateDgpoBean.weightedVpsReply));
      return NumUtil.multiply(vp, chainStateDgpoBean.poolReplyRewards.value.toInt()) / r1 / cosUnit;
    } else {
      return 0;
    }
  }

  /// 将Vest转成对应国家的金钱
  static double vestToRevenue(double revenue, ExchangeRateInfoData? bean) {
    if (!TextUtil.isEmpty(bean?.cosusdt.price)) {
      String lan = Common.getRequestLanCodeByLanguage(false);
      if (lan == 'cn') {
        if (bean?.usdcny != null && !TextUtil.isEmpty(bean?.usdcny.price)) {
          return NumUtil.multiply(NumUtil.multiply(revenue, double.parse(bean?.cosusdt.price ?? "")), double.parse(bean?.usdcny.price ?? ""));
        } else {
          return 0;
        }
      } else if (lan == 'tw') {
        if (bean?.usdtwd != null && !TextUtil.isEmpty(bean?.usdtwd.price)) {
          return NumUtil.multiply(NumUtil.multiply(revenue, double.parse(bean?.cosusdt.price ?? '')), double.parse(bean?.usdtwd.price ?? ""));
        } else {
          return 0;
        }
      } else if (lan == 'jp') {
        if (bean?.usdjpy != null && !TextUtil.isEmpty(bean?.usdjpy.price)) {
          return NumUtil.multiply(NumUtil.multiply(revenue, double.parse(bean?.cosusdt.price ?? '' ?? '')), double.parse(bean?.usdjpy.price ?? ""));
        } else {
          return 0;
        }
      } else if (lan == 'ko') {
        if (bean?.usdkrw != null && !TextUtil.isEmpty(bean?.usdkrw.price)) {
          return NumUtil.multiply(NumUtil.multiply(revenue, double.parse(bean?.cosusdt.price ?? '')), double.parse(bean?.usdkrw.price ?? ""));
        } else {
          return 0;
        }
      } else if (lan == 'vi') {
        if (bean?.usdvnd != null && !TextUtil.isEmpty(bean?.usdvnd.price)) {
          return NumUtil.multiply(NumUtil.multiply(revenue, double.parse(bean?.cosusdt.price ?? '')), double.parse(bean?.usdvnd.price ?? ""));
        } else {
          return 0;
        }
      } else if (lan == 'pt-br') {
        if (bean?.usdbrl != null && !TextUtil.isEmpty(bean?.usdbrl.price)) {
          return NumUtil.multiply(NumUtil.multiply(revenue, double.parse(bean?.cosusdt.price ?? '')), double.parse(bean?.usdbrl.price ?? ""));
        } else {
          return 0;
        }
      } else if (lan == 'ru') {
        if (bean?.usdrub != null && !TextUtil.isEmpty(bean?.usdrub.price)) {
          return NumUtil.multiply(NumUtil.multiply(revenue, double.parse(bean?.cosusdt.price ?? '')), double.parse(bean?.usdrub.price ?? ""));
        } else {
          return 0;
        }
      } else if (lan == 'tr') {
        if (bean?.usdtry != null && !TextUtil.isEmpty(bean?.usdtry.price ?? '')) {
          return NumUtil.multiply(NumUtil.multiply(revenue, double.parse(bean?.cosusdt.price ?? '')), double.parse(bean?.usdtry.price ?? ''));
        } else {
          return 0;
        }
      } else {
        return NumUtil.multiply(revenue, double.parse(bean?.cosusdt.price ?? ''));
      }
    } else {
      return 0;
    }
  }

  /// 获取奖励完成状态的总共收益Vest
  static double getStatusFinishTotalRevenueVest(String vest, String vestGift) {
    double? giftVest = NumUtil.getDoubleByValueStr(vestGift);
    double? videoVest = NumUtil.getDoubleByValueStr(vest);
    double originTotal = NumUtil.add(giftVest ?? 0, videoVest ?? 0);
    double totalVest = NumUtil.divide(originTotal, RevenueCalculationUtil.cosUnit);
    return totalVest;
  }

  static double calCurrentEnergy(String votePowerStr, String vestStr) {
    if (TextUtil.isEmpty(votePowerStr) || TextUtil.isEmpty(vestStr)) {
      return 0;
    }

    double? votePower = NumUtil.getDoubleByValueStr(votePowerStr);
    double? vest = NumUtil.getDoubleByValueStr(vestStr);
    double result = NumUtil.multiply(votePower ?? 0, vest ?? 0);
    return result;
  }

  static double calLowestEnergyConsume(String vestStr) {
    if (TextUtil.isEmpty(vestStr)) {
      return RevenueCalculationUtil.lowestEnergyRatio.toDouble();
    }

    double? vest = NumUtil.getDoubleByValueStr(vestStr);
    double result = NumUtil.multiply(vest ?? 0, RevenueCalculationUtil.lowestEnergyRatio);
    return result;
  }

  static double vestToEnergy(String vestStr) {
    if (TextUtil.isEmpty(vestStr)) {
      return 0;
    }

    double? vest = NumUtil.getDoubleByValueStr(vestStr);
    double result = NumUtil.multiply(vest ?? 0, RevenueCalculationUtil.energyUnit);
    return result;
  }

  static int calResumeLowestEnergySeconds(double currentEnergy, double maxEnergy) {
    if (maxEnergy <= 0) {
      return 0;
    }

    double lowestEnergy = NumUtil.multiply(maxEnergy, NumUtil.divide(RevenueCalculationUtil.lowestEnergyRatio, RevenueCalculationUtil.energyUnit));

    if (currentEnergy >= lowestEnergy) {
      return 0;
    }

    double diff = NumUtil.subtract(lowestEnergy, currentEnergy);
    int second = NumUtil.multiply(NumUtil.divide(diff, maxEnergy), 24 * 3600).ceil();
    return second;
  }

  static int calResumeLowestEnergyMinutes(double currentEnergy, double maxEnergy) {
    int seconds = RevenueCalculationUtil.calResumeLowestEnergySeconds(currentEnergy, maxEnergy);
    int minutes = NumUtil.divide(seconds, 60).ceil();
    return minutes;
  }
}
