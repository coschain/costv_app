import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/revenue_calculation_util.dart';
import 'package:flutter/material.dart';
import 'package:cosdart/types.dart';

typedef GetExchangeRateFailCallBack = void Function(String error);


/// 热门标签类型
enum HotTopicType {
  Unknown,
  TopicGame, //游戏
  TopicFun, //有趣
  TopicCutePets, //萌宠
  TopicMusic, //音乐
}

class HotTopicModel {
  HotTopicType topicType; //热门类型
  String desc; //热门描述
  String bgPath; //背景图片路径
  String iconUrl; //icon路劲
  HotTopicModel({this.topicType, this.desc, this.bgPath});
}

///历史视频类型
enum HistoryVideoType {
  RecentlyWatched, //最近观看
  Liked, //点过赞的视频，
  GiftTicketReward, //打赏过礼物派票的视频
  ProblemFeedback, //问题反馈
}

class HistoryVideoItemModel {
  HistoryVideoType type; //历史视频类型
  String icon; //图标路径
  String desc; //描述
  HistoryVideoItemModel({this.type, this.icon, this.desc});
}

class VideoUtil {
  static Future<ExchangeRateInfoData> requestExchangeRate(String tag, {GetExchangeRateFailCallBack failCallBack}) async {
    ExchangeRateInfoData data;
    await RequestManager.instance.getExchangeRateInfo(tag).then((response) {
      if (response == null) {
        CosLogUtil.log("fail to request exchange rate info");
        if (failCallBack != null) {
          failCallBack("response is empty");
        }
        return;
      }
      ExchangeRateInfoBean bean =
          ExchangeRateInfoBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        data = bean.data;
      } else {
        CosLogUtil.log("fail to fetch rate info,"
            " the error is ${bean.msg}, the error code is ${bean.status}");
        if (failCallBack != null) {
          failCallBack("code:${bean.status ?? ''},msg:${bean.msg ?? ''}");
        }
      }
    }).catchError((err) {
      CosLogUtil.log("fail to get exchagne rate, the error is $err");
      if (failCallBack != null) {
        failCallBack("get ExchangeRate exception: the error is $err");
      }
    }).whenComplete(() {});
    return data;
  }

  ///解析服务端返回的operation_vids数据(以逗号分隔vid)
  static String parseOperationVid(List<String> strList) {
    if (strList != null && strList.length > 0) {
      return strList.join(",");
    }
    return "";
  }

  ///清除存放历史视频id的map
  static void clearHistoryVidMap(Map<String, String> historyVideoMap) {
    if (historyVideoMap != null) {
      historyVideoMap.clear();
    }
  }

  ///添加新的的视频id到存放历史视频id的map
  static void addNewVidToHistoryVidMap(
      GetVideoListNewDataListBean data, Map<String, String> historyVideoMap) {
    if (data == null) {
      return;
    }
    if (historyVideoMap == null) {
      historyVideoMap = new Map();
    }
    if (data.id != null && !historyVideoMap.containsKey(data)) {
      historyVideoMap[data.id] = data.id;
    }
  }

  ///从视频数组中添加新的的视频id到存放历史视频id的map
  static void addNewVidToHistoryVidMapFromList(
      List<GetVideoListNewDataListBean> list,
      Map<String, String> historyVideoMap) {
    if (list == null) {
      return;
    }
    for (var video in list) {
      VideoUtil.addNewVidToHistoryVidMap(video, historyVideoMap);
    }
  }

  ///过滤重复热门视频
  static List<GetVideoListNewDataListBean> filterRepeatVideo(
      List<GetVideoListNewDataListBean> origin,
      Map<String, String> historyVideoMap) {
    List<GetVideoListNewDataListBean> list = [];
    if (origin != null && origin.length > 0 && historyVideoMap != null) {
      for (var data in origin) {
        if (data.id != null && !historyVideoMap.containsKey(data.id)) {
          list.add(data);
        }
      }
    }
    return list;
  }

  static String formatPlayTimes(
      BuildContext context, GetVideoListNewDataListBean video) {
    String desc = "";
    if (Common.checkIsNotEmptyStr(video?.watchNum)) {
      desc += video.watchNum + InternationalLocalizations.playCount;
    }
    return desc;
  }

  static String formatVideoCreateTime(
      BuildContext context, GetVideoListNewDataListBean video) {
    String desc = "";
    if (Common.checkIsNotEmptyStr(video?.createdAt)) {
      if (formatPlayTimes(context, video).length > 0) {
        desc += "·";
      }
      desc += Common.calcDiffTimeByStartTime(video.createdAt);
    }
    return desc;
  }

  static String getVideoWorth(ExchangeRateInfoData exchangeRate,
      dynamic_properties dgpoBean, GetVideoListNewDataListBean videoData) {
    if (videoData == null) {
      return "0";
    }

    bool isSettled = false;
    if (videoData.vestStatus == null) {
      CosLogUtil.log(
          "SingleVideoItem:vest_status is empty on video id:${videoData?.id ?? ""}");

      /// 没有vest_status，当成已经结算处理
      isSettled = true;
    } else {
      isSettled = (videoData.vestStatus == "1");
    }
    double totalVest = 0;
    if (isSettled) {
      ///已经结算直接用vest换算
      double giftVest = NumUtil.getDoubleByValueStr(videoData?.vestGift ?? "0");
      double videoVest = NumUtil.getDoubleByValueStr(videoData?.vest ?? "0");
      double originTotal = NumUtil.add(giftVest, videoVest);
      totalVest = NumUtil.divide(originTotal, RevenueCalculationUtil.cosUnit);
    } else {
      ///没有计算用votePower计算
      totalVest = RevenueCalculationUtil.getTotalRevenueVest(
          videoData.votepower, videoData.vestGift, dgpoBean);
    }
    double money = RevenueCalculationUtil.vestToRevenue(totalVest, exchangeRate);
    String finalVal =
        Common.formatDecimalDigit(money, 2);
    return Common.formatAmount(finalVal);
  }

//  static void autoPlayVideoOfIndex(int oldIdx, int newIdx,
//      Map<int, GlobalObjectKey<SingleVideoItemState>> keyMap) {
//    if (oldIdx != newIdx) {
//      if (keyMap != null) {
//        //停掉正在播放的视频
//        if (keyMap.containsKey(newIdx) && keyMap[newIdx].currentState != null) {
//          keyMap[newIdx].currentState.stopPlay(true);
//        }
//        //播放当前视频
//        if (keyMap.containsKey(oldIdx) && keyMap[oldIdx].currentState != null) {
//          keyMap[oldIdx].currentState.startPlay();
//        }
//      }
//    } else {
//      if (keyMap.containsKey(oldIdx) && keyMap[oldIdx].currentState != null) {
//        keyMap[oldIdx].currentState.startPlay();
//      }
//    }
//  }
//
//  static void  stopPlayVideo(bool isRestart, int curIdx,
//      Map<int, GlobalObjectKey<SingleVideoItemState>> keyMap) {
//    if (curIdx != null) {
//      if (keyMap != null && keyMap.containsKey(curIdx) && keyMap[curIdx].currentState != null) {
//        keyMap[curIdx].currentState.stopPlay(isRestart);
//      }
//    }
//  }

  static bool checkVideoListIsNotEmpty(
      List<GetVideoListNewDataListBean> videoList) {
    if (videoList != null && videoList.isNotEmpty) {
      return true;
    }
    return false;
  }

  static String formatDuration(Duration position) {
    final ms = position.inMilliseconds;

    int seconds = ms ~/ 1000;
    final int hours = seconds ~/ 3600;
    seconds = seconds % 3600;
    var minutes = seconds ~/ 60;
    seconds = seconds % 60;

    final hoursString = hours >= 10 ? '$hours' : hours == 0 ? '00' : '0$hours';

    final minutesString =
    minutes >= 10 ? '$minutes' : minutes == 0 ? '00' : '0$minutes';

    final secondsString =
    seconds >= 10 ? '$seconds' : seconds == 0 ? '00' : '0$seconds';

    final formattedTime =
        '${hoursString == '00' ? '' : hoursString + ':'}$minutesString:$secondsString';

    return formattedTime;
  }
}
