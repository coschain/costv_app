import 'package:costv_android/language/json/common/en.dart';
import 'package:costv_android/language/json/common/ko.dart';
import 'package:costv_android/language/json/common/pt_br.dart';
import 'package:costv_android/language/json/common/ru.dart';
import 'package:costv_android/language/json/common/tr.dart';
import 'package:costv_android/language/json/common/vi.dart';
import 'package:costv_android/language/json/common/zh.dart';
import 'package:costv_android/language/json/common/zh_cn.dart';
import 'package:costv_android/language/json/login/en.dart';
import 'package:costv_android/language/json/login/ko.dart';
import 'package:costv_android/language/json/login/pt_br.dart';
import 'package:costv_android/language/json/login/ru.dart';
import 'package:costv_android/language/json/login/tr.dart';
import 'package:costv_android/language/json/login/vi.dart';
import 'package:costv_android/language/json/login/zh.dart';
import 'package:costv_android/language/json/login/zh_ch.dart';
import 'package:costv_android/language/json/main/en.dart';
import 'package:costv_android/language/json/main/ko.dart';
import 'package:costv_android/language/json/main/pt_br.dart';
import 'package:costv_android/language/json/main/ru.dart';
import 'package:costv_android/language/json/main/tr.dart';
import 'package:costv_android/language/json/main/vi.dart';
import 'package:costv_android/language/json/main/zh.dart';
import 'package:costv_android/language/json/main/zh_ch.dart';
import 'package:costv_android/language/json/net/en.dart';
import 'package:costv_android/language/json/net/ko.dart';
import 'package:costv_android/language/json/net/pt_br.dart';
import 'package:costv_android/language/json/net/ru.dart';
import 'package:costv_android/language/json/net/tr.dart';
import 'package:costv_android/language/json/net/vi.dart';
import 'package:costv_android/language/json/net/zh.dart';
import 'package:costv_android/language/json/net/zh_ch.dart';
import 'package:costv_android/language/json/user/en.dart';
import 'package:costv_android/language/json/user/ko.dart';
import 'package:costv_android/language/json/user/pt_br.dart';
import 'package:costv_android/language/json/user/ru.dart';
import 'package:costv_android/language/json/user/tr.dart';
import 'package:costv_android/language/json/user/vi.dart';
import 'package:costv_android/language/json/user/zh.dart';
import 'package:costv_android/language/json/user/zh_ch.dart';
import 'package:costv_android/language/json/videoDetail/en.dart';
import 'package:costv_android/language/json/videoDetail/ko.dart';
import 'package:costv_android/language/json/videoDetail/pt_br.dart';
import 'package:costv_android/language/json/videoDetail/ru.dart';
import 'package:costv_android/language/json/videoDetail/tr.dart';
import 'package:costv_android/language/json/videoDetail/vi.dart';
import 'package:costv_android/language/json/videoDetail/zh.dart';
import 'package:costv_android/language/json/videoDetail/zh_ch.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/time_util.dart';

import 'package:flutter/material.dart';

class InternationalLocalizations {

  //美国
  static const languageCodeEn = 'en';
  //韩国
  static const languageCodeKo = 'ko';
  //巴西葡萄牙
  static const languageCodePt_Br = 'pt-br';
  //俄罗斯
  static const languageCodeRu = 'ru';
  //土耳其
  static const languageCodeTr = 'tr';
  //越南
  static const languageCodeVi = 'vi';
  //中文繁体
  static const languageCodeZh = 'zh';
  //中文简体
  static const languageCodeZh_Cn = 'zh-cn';

  final Locale locale;

  static Map<String, dynamic> _mapCommonValue = {};
  static Map<String, dynamic> _mapLoginValue = {};
  static Map<String, dynamic> _mapMainValue = {};
  static Map<String, dynamic> _mapNetValue = {};
  static Map<String, dynamic> _mapVideoDetailValue = {};
  static Map<String, dynamic> _userValue = {};

  InternationalLocalizations(this.locale);

  void initData() {
    String languageCode = Common.getLanCodeByLanguage();
    if (languageCode == languageCodeKo) {
      _mapCommonValue = commonKo;
      _mapLoginValue = loginKo;
      _mapMainValue = mainKo;
      _mapNetValue = netKo;
      _mapVideoDetailValue = videoDetailKo;
      _userValue= userKo;
    } else if (languageCode == languageCodePt_Br) {
      _mapCommonValue = commonPtBr;
      _mapLoginValue = loginPtBr;
      _mapMainValue = mainPtBr;
      _mapNetValue = netPtBr;
      _mapVideoDetailValue = videoDetailPtBr;
      _userValue= userPtBr;
    } else if (languageCode == languageCodeRu) {
      _mapCommonValue = commonRu;
      _mapLoginValue = loginRu;
      _mapMainValue = mainRu;
      _mapNetValue = netRu;
      _mapVideoDetailValue = videoDetailRu;
      _userValue= userRu;
    }  else if (languageCode == languageCodeTr) {
      _mapCommonValue = commonTr;
      _mapLoginValue = loginTr;
      _mapMainValue = mainTr;
      _mapNetValue = netTr;
      _mapVideoDetailValue = videoDetailTr;
      _userValue= userTr;
    } else if (languageCode == languageCodeVi) {
      _mapCommonValue = commonVi;
      _mapLoginValue = loginVi;
      _mapMainValue = mainVi;
      _mapNetValue = netVi;
      _mapVideoDetailValue = videoDetailVi;
      _userValue= userVi;
    } else if (languageCode == languageCodeZh_Cn) {
      _mapCommonValue = commonZhCh;
      _mapLoginValue = loginZhCn;
      _mapMainValue = mainZhCn;
      _mapNetValue = netZhCn;
      _mapVideoDetailValue = videoDetailZhCn;
      _userValue= userZhCn;
    } else if (languageCode == languageCodeZh) {
      _mapCommonValue = commonZh;
      _mapLoginValue = loginZh;
      _mapMainValue = mainZh;
      _mapNetValue = netZh;
      _mapVideoDetailValue = videoDetailZh;
      _userValue= userZh;
    } else {
      _mapCommonValue = commonEn;
      _mapLoginValue = loginEn;
      _mapMainValue = mainEn;
      _mapNetValue = netEn;
      _mapVideoDetailValue = videoDetailEn;
      _userValue= userEn;
    }
  }

  static Map<String, dynamic> get mapNetValue => _mapNetValue;

  // begin通用
  static get title {
    return _mapCommonValue['title'];
  }

  static get httpErrorDefault {
    return _mapCommonValue['httpErrorDefault'];
  }

  static get httpErrorCancel {
    return _mapCommonValue['httpErrorCancel'];
  }

  static get httpErrorConnectTimeout {
    return _mapCommonValue['httpErrorConnectTimeout'];
  }

  static get httpErrorReceiveTimeout {
    return _mapCommonValue['httpErrorReceiveTimeout'];
  }

  static get httpErrorResponse {
    return _mapCommonValue['httpErrorResponse'];
  }

  static get httpError {
    return _mapCommonValue['httpError'];
  }

  static get cancel {
    return _mapCommonValue['cancel'];
  }

  static get carryOn {
    return _mapCommonValue['carryOn'];
  }

  static get back {
    return _mapCommonValue['back'];
  }

  static get close {
    return _mapCommonValue['close'];
  }

  static get noMoreData {
    return _mapCommonValue['noMoreData'];
  }

  static get playCount {
    return _mapCommonValue['playCount'];
  }

  static get confirm {
    return _mapCommonValue['confirm'];
  }

  static get netError {
    return _mapCommonValue['netError'];
  }

  static get notLogInTips {
    return _mapCommonValue['notLogInTips'];
  }

  static get subscriptionLogInTips {
    return _mapCommonValue['subscriptionLogInTips'];
  }

  static get watchHistoryLogInTips {
    return _mapCommonValue['watchHistoryLogInTips'];
  }

  static get netRequestFailTips {
    return _mapCommonValue['netRequestFailTips'];
  }

  static get netRequestFailDesc {
    return _mapCommonValue['netRequestFailDesc'];
  }

  static get reloadData {
    return _mapCommonValue['reloadData'];
  }

  static get updateTitle => (String version) {
    return _mapCommonValue['updateTitle'].replaceAll('\${version}', version);
  };

  static get updateConfirm {
    return _mapCommonValue['updateConfirm'];
  }

  // end通用

  // begin主页
  static get homeTitle {
    return _mapMainValue['videoDetail']['homeTitle'];
  }

  static get homePopularTitle {
    return _mapMainValue['videoDetail']['homePopularTitle'];
  }

  static get homeMySubscriptionTitle {
    return _mapMainValue['videoDetail']['homeMySubscriptionTitle'];
  }

  static get homeSeeHistoryTitle {
    return _mapMainValue['videoDetail']['homeSeeHistoryTitle'];
  }

  static get noMoreOperateVideo {
    return _mapMainValue['videoDetail']['noMoreOperateVideo'];
  }

  // end主页

  // begin视频详情页
  static get videoShare {
    return _mapVideoDetailValue['videoDetail']['videoShare'];
  }

  static get videoReport {
    return _mapVideoDetailValue['videoDetail']['videoReport'];
  }

  static get videoSubscription {
    return _mapVideoDetailValue['videoDetail']['videoSubscription'];
  }

  static get videoSubscriptionFinish {
    return _mapVideoDetailValue['videoDetail']['videoSubscriptionFinish'];
  }

  static get videoSubscriptionCount {
    return _mapVideoDetailValue['videoDetail']['videoSubscriptionCount'];
  }

  static get videoNoMoreComment {
    return _mapVideoDetailValue['videoDetail']['videoNoMoreComment'];
  }

  static get videoHotSort {
    return _mapVideoDetailValue['videoDetail']['videoHotSort'];
  }

  static get videoTimeSort {
    return _mapVideoDetailValue['videoDetail']['videoTimeSort'];
  }

  static get videoInputMsgHint {
    return _mapVideoDetailValue['videoDetail']['videoInputMsgHint'];
  }

  static get videoRecommendation {
    return _mapVideoDetailValue['videoDetail']['videoRecommendation'];
  }

  static get videoCommentCount {
    return _mapVideoDetailValue['videoDetail']['videoCommentCount'];
  }

  static get videoCommentReply {
    return _mapVideoDetailValue['videoDetail']['videoCommentReply'];
  }

  static get videoCommentReplyCount {
    return _mapVideoDetailValue['videoDetail']['videoCommentReplyCount'];
  }

  static get videoCommentSendMessage {
    return _mapVideoDetailValue['videoDetail']['videoCommentSendMessage'];
  }

  static get videoRevenueTotal {
    return _mapVideoDetailValue['videoDetail']['videoRevenueTotal'];
  }

  static get videoRevenueTotalVest {
    return _mapVideoDetailValue['videoDetail']['videoRevenueTotalVest'];
  }

  static get videoVest {
    return _mapVideoDetailValue['videoDetail']['videoVest'];
  }

  static get videoSettlementBonus {
    return _mapVideoDetailValue['videoDetail']['videoSettlementBonus'];
  }

  static get videoSettlementTime {
    return _mapVideoDetailValue['videoDetail']['videoSettlementTime'];
  }

  static get videoSettlementTimeFuture {
    return _mapVideoDetailValue['videoDetail']['videoSettlementTimeFuture'];
  }

  static get videoGiftRevenue {
    return _mapVideoDetailValue['videoDetail']['videoGiftRevenue'];
  }

  static get videoAbout {
    return _mapVideoDetailValue['videoDetail']['videoAbout'];
  }

  static get videoRemainingSettlementTime {
    return _mapVideoDetailValue['videoDetail']['videoRemainingSettlementTime'];
  }

  static get videoSettlementFinish {
    return _mapVideoDetailValue['videoDetail']['videoSettlementFinish'];
  }

  static get videoCommentFold {
    return _mapVideoDetailValue['videoDetail']['videoCommentFold'];
  }

  static get videoCommentReplyAll {
    return _mapVideoDetailValue['videoDetail']['videoCommentReplyAll'];
  }

  static get videoLoginPop {
    return _mapVideoDetailValue['videoDetail']['videoLoginPop'];
  }

  static get videoLinkFinishHint {
    return _mapVideoDetailValue['videoDetail']['videoLinkFinishHint'];
  }

  static get videoPopFinish {
    return _mapVideoDetailValue['videoDetail']['videoPopFinish'];
  }

  static get videoClickMoreComment {
    return _mapVideoDetailValue['videoDetail']['videoClickMoreComment'];
  }

  static get energyNotEnoughTips => (String minutes) {
        return _mapVideoDetailValue['videoDetail']['energyNotEnoughTips']
            .replaceAll('\${minutes}', minutes);
      };

  // end视频详情页

  // begin举报
  static get reportInformVideo {
    return _mapVideoDetailValue['videoReport']['reportInformVideo'];
  }

  static get reportTime {
    return _mapVideoDetailValue['videoReport']['reportTime'];
  }

  static get reportPlaceholder {
    return _mapVideoDetailValue['videoReport']['reportPlaceholder'];
  }

  static get reportTimeTips {
    return _mapVideoDetailValue['videoReport']['reportTimeTips'];
  }

  static get reportTipsOne {
    return _mapVideoDetailValue['videoReport']['reportTipsOne'];
  }

  static get reportTipsTwo {
    return _mapVideoDetailValue['videoReport']['reportTipsTwo'];
  }

  static get reportThanksToShare {
    return _mapVideoDetailValue['videoReport']['reportThanksToShare'];
  }

  static get reportProblem {
    return _mapVideoDetailValue['videoReport']['reportProblem'];
  }

  static get reportClose {
    return _mapVideoDetailValue['videoReport']['reportClose'];
  }

  static get reportBtnMore {
    return _mapVideoDetailValue['videoReport']['reportBtnMore'];
  }

  static get reportInputMsgHint {
    return _mapVideoDetailValue['videoReport']['reportInputMsgHint'];
  }

  static get reportTypeCodeList {
    return _mapVideoDetailValue['videoReport']['reportTypeCodeList'];
  }

  static get reportTypeNameList {
    return _mapVideoDetailValue['videoReport']['reportTypeNameList'];
  }

  // end举报

  // begin订阅列表(follow列表)页
  static get followingListPageTitle {
    return _mapMainValue['followingList']['followingListPageTitle'];
  }

  static get noMoreFollowing {
    return _mapMainValue['followingList']['noMoreFollowing'];
  }

  static get failToLoadData {
    return _mapMainValue['followingList']['failToLoadData'];
  }

  static get watchNumberDesc => (String num) {
        return _mapMainValue['followingList']['watchNumberDesc']
            .replaceAll('\${num}', num);
      };

  static get noMoreSubscribeVideo {
    return _mapMainValue['followingList']['noMoreSubscribeVideo'];
  }

  static get noSubscribe {
    return _mapMainValue['followingList']['noSubscribe'];
  }

  // end订阅列表(follow列表)页

  // begin视频时间
  static get yearAgo => (String year) {
        return _mapMainValue['videoTime']['yearAgo']
            .replaceAll('\${year}', year);
      };

  static get monthAgo => (String month) {
    return _mapMainValue['videoTime']['monthAgo'].replaceAll('\${month}', month);
  };

  static get dayAgo => (String day) {
    return _mapMainValue['videoTime']['dayAgo'].replaceAll('\${day}', day);
  };

  static get hourAgo => (String h) {
    return _mapMainValue['videoTime']['hourAgo'].replaceAll('\${h}', h);
  };

  static get minuteAgo => (String minute) {
    return _mapMainValue['videoTime']['minuteAgo'].replaceAll('\${minute}', minute);
  };

  static get secondAgo => (String sec) {
    return _mapMainValue['videoTime']['secondAgo'].replaceAll('\${sec}', sec);
  };

  static get monthDay => (String m, String d) {
    if(Common.isEn()){
      m = TimeUtil.getEnMonthForNumber(m);
    }
    String monthDay = _mapMainValue['videoTime']['monthDay'].replaceAll('\${m}', m);
    return monthDay.replaceAll('\${d}', d);
  };

  static get yearMonthDay => (String y, String m, String d) {
    if(Common.isEn()){
      m = TimeUtil.getEnMonthForNumber(m);
    }
    String yearMonthDayOne = _mapMainValue['videoTime']['yearMonthDay'].replaceAll('\${y}', y);
    String yearMonthDayTwo = yearMonthDayOne.replaceAll('\${m}', m);
    return yearMonthDayTwo.replaceAll('\${d}', d);
  };

  // end视频时间

  // begin热门相关
  static get hotTopicGame {
    return _mapMainValue['hot']['hotTopicGame'];
  }

  static get hotTopicFun {
    return _mapMainValue['hot']['hotTopicFun'];
  }

  static get hotTopicCutePets {
    return _mapMainValue['hot']['hotTopicCutePets'];
  }

  static get hotTopicMusic {
    return _mapMainValue['hot']['hotTopicMusic'];
  }

  static get moMoreHotData {
    return _mapMainValue['hot']['moMoreHotData'];
  }

  // end热门相关

  // begin视频观看历史
  static get recentlyWatched {
    return _mapMainValue['history']['recentlyWatched'];
  }

  static get noMoreHistoryVideo {
    return _mapMainValue['history']['noMoreHistoryVideo'];
  }

  static get watchHistory {
    return _mapMainValue['history']['watchHistory'];
  }

  static get likedVideo {
    return _mapMainValue['history']['likedVideo'];
  }

  static get giftRewardVideo {
    return _mapMainValue['history']['giftRewardVideo'];
  }

  static get deleteVideoTips {
    return _mapMainValue['history']['deleteVideoTips'];
  }

  static get problemFeedback {
    return _mapMainValue['history']['problemFeedback'];
  }

  static get likedVideoTitle {
    return _mapMainValue['liked']['likedVideoTitle'];
  }

  // end视频观看历史

  // begin搜索页
  static get searchInputHint {
    return _mapMainValue['search']['searchInputHint'];
  }

  static get searchHistory {
    return _mapMainValue['search']['searchHistory'];
  }

  static get searchVideo {
    return _mapMainValue['search']['searchVideo'];
  }

  static get searchCreator {
    return _mapMainValue['search']['searchCreator'];
  }

  static get searchNoData {
    return _mapMainValue['search']['searchNoData'];
  }

  static get searchPlayCount {
    return _mapMainValue['search']['searchPlayCount'];
  }

  static get searchFan {
    return _mapMainValue['search']['searchFan'];
  }

  static get searchAttention {
    return _mapMainValue['search']['searchAttention'];
  }

  static get searchAttentionFinish {
    return _mapMainValue['search']['searchAttentionFinish'];
  }

  static get searchAttentionAllFinish {
    return _mapMainValue['search']['searchAttentionAllFinish'];
  }

  static get searchHotVideo {
    return _mapMainValue['search']['searchHotVideo'];
  }

  static get searchRecommendUser {
    return _mapMainValue['search']['searchRecommendUser'];
  }

  static get searchNoMoreVideo {
    return _mapMainValue['search']['searchNoMoreVideo'];
  }

  static get searchNoMoreUser {
    return _mapMainValue['search']['searchNoMoreUser'];
  }

  // end搜索页

  // begin时间格式
  static get justNow {
    return _mapMainValue['timeFormat']['justNow'];
  }

  static get yesterday {
    return _mapMainValue['timeFormat']['yesterday'];
  }

  static get minutes =>(int minutes) {
    return _mapMainValue['timeFormat']['minutes'].replaceAll('\${minutes}', minutes?.toString()??'');
  };

  static get hours =>(int hours) {
    return _mapMainValue['timeFormat']['hours'].replaceAll('\${hours}', hours?.toString()??'');
  };

  static get days =>(int days) {
    return _mapMainValue['timeFormat']['days'].replaceAll('\${days}', days?.toString()??'');
  };

  // end时间格式

  //begin登录
  static get logInFail {
    return _mapLoginValue['logInFail'];
  }

  static get logIn {
    return _mapLoginValue['logIn'];
  }

  //end登录

  static get followSelfErrorTips {
    return _mapNetValue['remoteResError']['90029'];
  }

  //begin user相关
  static get getUserFansNum =>(String num) {
    return _userValue['fansNum'].replaceAll('\${num}', num?.toString()??'0');
  };

  static get userHottestVideo {
    return _userValue['userHottestVideo'];
  }

  static get userHotVideo {
    return _userValue['userHotVideo'];
  }

  static get userNoMoreVideo {
    return _userValue['userNoMoreVideo'];
  }

  static get userNewVideos {
    return _userValue['userNewVideos'];
  }

  static get hasNotUploadVideos {
    return _userValue['hasNotUploadVideos'];
  }

//end user相关
}
