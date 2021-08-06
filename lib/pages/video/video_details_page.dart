import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/bank_property_bean.dart';
import 'package:costv_android/bean/comment_list_bean.dart';
import 'package:costv_android/bean/cos_video_details_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_info_bean.dart';
import 'package:costv_android/bean/integral_user_info_bean.dart';
import 'package:costv_android/bean/integral_video_integral_bean.dart';
import 'package:costv_android/bean/relate_list_bean.dart';
import 'package:costv_android/bean/simple_bean.dart';
import 'package:costv_android/bean/simple_proxy_bean.dart';
import 'package:costv_android/bean/video_gift_info_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/watch_video_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/video/bean/comment_children_list_parameter_bean.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/bean/video_settlement_bean.dart';
import 'package:costv_android/pages/video/popupwindow/video_comment_children_list_window.dart';
import 'package:costv_android/pages/video/popupwindow/video_settlement_window.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/platform_util.dart';
import 'package:costv_android/utils/revenue_calculation_util.dart';
import 'package:costv_android/utils/time_format_util.dart';
import 'package:costv_android/utils/time_util.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:costv_android/utils/video_report_util.dart';
import 'package:costv_android/utils/video_small_windows_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/animation/animation_rotate_widget.dart';
import 'package:costv_android/widget/animation/video_add_money_widget.dart';
import 'package:costv_android/widget/bottom_progress_indicator.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/no_more_data_widget.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/popupwindow/popup_window.dart';
import 'package:costv_android/widget/popupwindow/popup_window_route.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/video_time_widget.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';

import 'dialog/energy_not_enough_dialog.dart';
import 'dialog/video_report_dialog.dart';
import 'player/costv_controls.dart';
import 'player/costv_fullscreen.dart';
import 'package:cosdart/types.dart';

class VideoDetailsPage extends StatefulWidget {
  final VideoDetailPageParamsBean _videoDetailPageParamsBean;

  VideoDetailsPage(this._videoDetailPageParamsBean, {Key key})
      : super(key: key);

  @override
  _VideoDetailsPageState createState() => _VideoDetailsPageState();
}

enum CommentType {
  commentTypeHot,
  commentTypeTime,
}
enum CommentSendType {
  commentSendTypeNormal,
  commentSendTypeChildren,
}

class _VideoDetailsPageState extends State<VideoDetailsPage>
    with SingleTickerProviderStateMixin, RouteAware {
  static const String tag = '_VideoDetailsPageState';
  final GlobalKey<ScaffoldState> _dialogSKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _pageKey = GlobalKey<ScaffoldState>();
  static const int videoPageSize = 20;
  static const int commentPageSize = 10;
  static const String orderByHot = 'like_count';
  static const String orderByTime = 'created_at';
  static const int timeInterval = 1000;
  static const int timeTotalTime = 60 * 1000;
  static const int popRewardHot = 20;
  static const int popRewardNormal = 10;
  int settlementTime = Constant.isDebug ? 60 * 5 : 60 * 60 * 24 * 7;

  AnimationController _animationController;
  List<dynamic> _listData = [];
  bool _isHaveMoreData = false;
  CommentType _commentTypeCurrent = CommentType.commentTypeHot;
  TextEditingController _textController;
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  bool _isNetIng = false;
  GetVideoInfoDataBean _getVideoInfoDataBean;
  bool _isHideVideoMsg = true;
  bool _isInitFinish = false;
  bool _isVideoLike = false;
  bool _isFollow = false;
  bool _isLoadMoreComment = false;
  int _videoPage = 1;
  int _commentPage = 1;
  CommentListDataBean _commentListDataBean;
  List<dynamic> _listComment = [];
  List<RelateListItemBean> _listRelate;
  int _linkCount = 0;
  Map<String, dynamic> _mapRemoteResError;
  Map<String, dynamic> _mapVideoIntegralError;
  bool _isAbleSendMsg = false;
  VideoReportDialog _videoReportDialog;
  EnergyNotEnoughDialog _energyNotEnoughDialog;
  BankPropertyDataBean _bankPropertyDataBean;
  TimerUtil _timerUtil;
  int _popReward = popRewardHot;
  ExchangeRateInfoData _exchangeRateInfoData;
  ChainState _chainStateBean;
  String _strSettlementTime = '';
  bool _isRotatedTitle = false;
  bool _isRotatedMoney = false;
  VideoSettlementBean _videoSettlementBean = VideoSettlementBean();
  VideoGiftInfoDataBean _videoGiftInfoDataBean;
  IntegralUserInfoDataBean _integralUserInfoDataBean;
  bool _isGetVideoPop = false;
  AccountInfo _cosInfoBean;
  bool _autoPlayWhenBack = false;
  Duration _lastPlayerPosition = Duration.zero;
  Duration _currentPlayerPosition = Duration.zero;
  TimeFormatUtil _timeFormatUtil = TimeFormatUtil();
  CommentSendType _commentSendType = CommentSendType.commentSendTypeNormal;
  String _commentId;
  String _commentName;
  String _uid;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
    );
    _textController = TextEditingController();

    _mapRemoteResError =
        InternationalLocalizations.mapNetValue['remoteResError'];
    _mapVideoIntegralError =
        InternationalLocalizations.mapNetValue['videoIntegralError'];

    _timerUtil = TimerUtil(mInterval: timeInterval, mTotalTime: timeTotalTime);
    _timerUtil.setOnTimerTickCallback((int tick) {
      CosLogUtil.log("video_details_page _timerUtil tick = $tick");
      if (tick == 0) {
        _timerUtil.updateTotalTime(timeTotalTime);
        _httpIntegralVideoIntegral();
      }
      setState(() {
        CosLogUtil.log(
            "video_details_page _timerUtil _animationController = ${(timeTotalTime - tick) / timeTotalTime}");
        _animationController.value = (timeTotalTime - tick) / timeTotalTime;
      });
    });
    _chainInfoInit();
    _cosAccountInfoInit();
//    _httpVideoDetailsInit();
    _loadVideoDetailsInfo();
    if (Common.judgeHasLogIn()) {
      _addWatchHistory();
    }
    if (Common.checkIsNotEmptyStr(
        widget._videoDetailPageParamsBean.getVideoSource)) {
      _initVideoPlayers(widget._videoDetailPageParamsBean.getVideoSource);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    RequestManager.instance.cancelAllNetworkRequest(tag);
    routeObserver.unsubscribe(this);
    _videoPlayerController?.removeListener(videoPlayerChanged);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    if (_animationController != null) {
      _animationController.dispose();
      _animationController = null;
    }
    if (_textController != null) {
      _textController.dispose();
      _textController = null;
    }
    if (_timerUtil != null) {
      _timerUtil.cancel();
      _timerUtil = null;
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (_autoPlayWhenBack) {
      _chewieController?.play();
    }
    _autoPlayWhenBack = false;
  }

  @override
  void didPushNext() {
    super.didPushNext();
    _autoPlayWhenBack = _chewieController != null &&
        !_chewieController.isFullScreen &&
        _videoPlayerController != null &&
        _videoPlayerController.value != null &&
        _videoPlayerController.value.isPlaying;
    if (_autoPlayWhenBack) {
      _chewieController.pause();
    }
  }

  /// 公链信息初始化
  void _chainInfoInit() {
    CosSdkUtil.instance.getChainState().then((bean) {
      if (bean != null) {
        _chainStateBean = bean.state;
        if (_isInitFinish) {
          initTotalRevenue();
        }
      }
    });
  }

  void _cosAccountInfoInit() {
    CosSdkUtil.instance
        .getAccountChainInfo(Constant.accountName ?? '')
        .then((bean) {
      if (bean != null) {
        _cosInfoBean = bean.info;
      }
    });
  }

  void _fetchExChangeRate(bool isUpdateState) async {
    RequestManager.instance.getExchangeRateInfo(tag).then((response) {
      _processExchangeRateInfo(response);
      if (_exchangeRateInfoData != null && isUpdateState) {
        setState(() {});
      }
    });
  }

  void _loadVideoDetailsInfo() {
    setState(() {
      _isNetIng = true;
    });
    Future.wait([
      RequestManager.instance.getVideoDetailsInfo(tag,
        widget._videoDetailPageParamsBean?.getVid ?? '',
        Common.getCurrencyMoneyByLanguage(),
        uid: Constant.uid ?? '',
        fuid: widget._videoDetailPageParamsBean?.getUid ?? '',
      ),
      RequestManager.instance.videoRelateList(
          tag, widget._videoDetailPageParamsBean?.getVid ?? '',
          page: _videoPage.toString(), pageSize: videoPageSize.toString()),
      RequestManager.instance.videoCommentList(
          tag,
          widget._videoDetailPageParamsBean?.getVid ?? '',
          _commentPage,
          commentPageSize,
          uid: Constant.uid ?? '',
          orderBy: VideoCommentListResponse.orderByHot),
    ]).then((listResponse) {
      if (listResponse == null || !mounted) {
        return;
      }
      bool isHaveBasicData = true;
      //视频详情相关数据
      if (listResponse.length >= 1) {
        isHaveBasicData = _processVideoDetailsInfo(listResponse[0]);
      }
      //视频推荐列表
      if (listResponse.length >= 2) {
        _processVideoRelateList(listResponse[1]);
      }
      //评论列表
      if (listResponse.length >= 3) {
        _processVideoCommentList(listResponse[2], false, false);
      }
      if (isHaveBasicData) {
        _isInitFinish = true;
      } else {
        //重新拉取汇率，避免推荐视频列表视频价值显示不正确
        _fetchExChangeRate(true);
      }
      initTotalRevenue();
      initSettlementTime();
      _initAuthorFollowStatus(_getVideoInfoDataBean?.uid ?? '');
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      _isFirstLoad = false;
      if (_videoPlayerController == null &&
          !Common.checkIsNotEmptyStr(
              widget._videoDetailPageParamsBean?.getVideoSource)) {
        _initVideoPlayers(_getVideoInfoDataBean?.videosource ?? '').then((_) {
          setState(() {});
        });
      }
      setState(() {
        _isNetIng = false;
      });
    });
  }

  bool _processVideoDetailsInfo(Response response) {
    CosVideoDetailsBean bean =
        CosVideoDetailsBean.fromJson(json.decode(response.data));
    if (bean.status == SimpleResponse.statusStrSuccess) {
      if (bean.data != null) {
        //video info
        _processGetVideoInfo(bean.data.videoGetVideoInfo);
        _videoGiftInfoDataBean = bean.data.videoGiftInfo;
        _integralUserInfoDataBean = bean.data.integralUserInfo;
        _bankPropertyDataBean = bean.data.bankProperty;
        _exchangeRateInfoData = bean.data.bankGetRateList;
        if (bean.data.videoIsLike != null) {
          _isVideoLike =
              (bean.data.videoIsLike == VideoIsLikeResponse.isLikeYes);
        }
        if (bean.data.accountIsFollow != null) {
          if (bean.data.accountIsFollow ==
                  FollowStateResponse.followStateFollowing ||
              bean.data.accountIsFollow ==
                  FollowStateResponse.followStateFriend) {
            _isFollow = true;
          } else {
            _isFollow = false;
          }
        }
        return true;
      } else {
        CosLogUtil.log("VideoDetailPage: fetch empty video details info, "
            "vid is ${widget._videoDetailPageParamsBean?.getVid ?? ''}, "
            "uid is ${Constant.uid ?? ''}");
        return false;
      }
    } else {
      CosLogUtil.log("VideoDetailPage: fail to fetch video details info, "
          "the error code is ${bean.status}, msg is ${bean.msg}, "
          "vid is ${widget._videoDetailPageParamsBean?.getVid ?? ''}, "
          "uid is ${Constant.uid ?? ''}");
      return false;
    }
  }

  ///添加观看历史
  void _addWatchHistory() {
    RequestManager.instance
        .addHistory(tag, Constant.uid ?? '',
            widget._videoDetailPageParamsBean?.getVid ?? '')
        .then((response) {
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        EventBusHelp.getInstance().fire(
            WatchVideoEvent(widget._videoDetailPageParamsBean.getVid ?? ""));
      }
    });
  }

  void initTotalRevenue() {
    if (_getVideoInfoDataBean != null && _exchangeRateInfoData != null) {
      _videoSettlementBean.setVestStatus = _getVideoInfoDataBean.vestStatus;
      _videoSettlementBean.setMoneySymbol =
          Common.getCurrencySymbolByLanguage();
      if (_getVideoInfoDataBean?.vestStatus ==
          VideoInfoResponse.vestStatusFinish) {
        /// 奖励完成
        ///已经结算直接用vest换算
        double settlementBonusVest = NumUtil.divide(
            double.parse(_getVideoInfoDataBean?.vest ?? 0),
            RevenueCalculationUtil.cosUnit);
        double settlementBonus = RevenueCalculationUtil.vestToRevenue(
            settlementBonusVest, _exchangeRateInfoData);
        double giftRevenueVest = NumUtil.divide(
            double.parse(_getVideoInfoDataBean?.vestGift ?? 0),
            RevenueCalculationUtil.cosUnit);
        double giftRevenue = RevenueCalculationUtil.vestToRevenue(
            giftRevenueVest, _exchangeRateInfoData);
        double totalRevenueVest = NumUtil.divide(
            NumUtil.add(double.parse(_getVideoInfoDataBean?.vest ?? 0),
                double.parse(_getVideoInfoDataBean?.vestGift ?? 0)),
            RevenueCalculationUtil.cosUnit);
//        String totalRevenue = RevenueCalculationUtil.vestToRevenue(
//                totalRevenueVest, _exchangeRateInfoData)
//            .toStringAsFixed(2);
        double money = RevenueCalculationUtil.vestToRevenue(
            totalRevenueVest, _exchangeRateInfoData);
        String totalRevenue = Common.formatDecimalDigit(money, 2);

        _videoSettlementBean.setSettlementTime =
            TimeUtil.secondToYYYYMMddHHmmss(
                int.parse(_getVideoInfoDataBean.vestTime ?? '0'));
        _strSettlementTime = _videoSettlementBean.getSettlementTime;
        _videoSettlementBean.setSettlementBonusVest =
            settlementBonusVest.toStringAsFixed(2);
        _videoSettlementBean.setSettlementBonus =
            settlementBonus.toStringAsFixed(2);
        _videoSettlementBean.setGiftRevenueVest =
            giftRevenueVest.toStringAsFixed(2);
        _videoSettlementBean.setGiftRevenue = giftRevenue.toStringAsFixed(2);
        _videoSettlementBean.setTotalRevenueVest =
            totalRevenueVest.toStringAsFixed(2);
        _videoSettlementBean.setTotalRevenue = totalRevenue;
      } else {
        _videoSettlementBean.setSettlementTime = calculationSettlementTime();
        _strSettlementTime = _videoSettlementBean.getSettlementTime;
        double settlementBonusVest = RevenueCalculationUtil.getVideoRevenueVest(
            _getVideoInfoDataBean?.votepower, _chainStateBean?.dgpo);
        _videoSettlementBean.setSettlementBonusVest =
            settlementBonusVest.toStringAsFixed(2);
        _videoSettlementBean.setSettlementBonus =
            RevenueCalculationUtil.vestToRevenue(
                    settlementBonusVest, _exchangeRateInfoData)
                .toStringAsFixed(2);
        double giftRevenueVest = RevenueCalculationUtil.getGiftRevenueVest(
            _getVideoInfoDataBean?.vestGift);
        _videoSettlementBean.setGiftRevenueVest = giftRevenueVest.toString();
        _videoSettlementBean.setGiftRevenue =
            RevenueCalculationUtil.vestToRevenue(
                    giftRevenueVest, _exchangeRateInfoData)
                .toStringAsFixed(2);
        double totalRevenueVest =
            NumUtil.add(settlementBonusVest, giftRevenueVest);
        _videoSettlementBean.setTotalRevenueVest =
            totalRevenueVest.toStringAsFixed(2);
//      _videoSettlementBean.setTotalRevenue =
//          RevenueCalculationUtil.vestToRevenue(
//                  totalRevenueVest, _exchangeRateInfoData)
//              .toStringAsFixed(2);
        double money = RevenueCalculationUtil.vestToRevenue(
            totalRevenueVest, _exchangeRateInfoData);
        String totalRevenue = Common.formatDecimalDigit(money, 2);
        _videoSettlementBean.setTotalRevenue = totalRevenue;
      }
    }
  }

  void _initAuthorFollowStatus(String authorUid) async {
    Response response = await RequestManager.instance
        .accountIsFollow(tag, Constant.uid ?? '', authorUid ?? '');
    if (response == null) {
      return;
    }
    _processAccountIsFollow(response);
  }

  void initSettlementTime() {
    _strSettlementTime = InternationalLocalizations.videoSettlementFinish;
    if (_getVideoInfoDataBean?.vestStatus !=
        VideoInfoResponse.vestStatusFinish) {
      _strSettlementTime = calculationSettlementTime();
    }
  }

  void _httpVideoIsLike(bool isCarryOnLike) {
    setState(() {
      _isNetIng = true;
    });
    RequestManager.instance
        .videoIsLike(tag, Constant.uid ?? '',
            widget._videoDetailPageParamsBean?.getVid ?? '')
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      _processVideoIsLike(response, isCarryOnLike);
    });
  }

  /// 处理视频详情接口返回数据
  bool _processGetVideoInfo(GetVideoInfoDataBean videoInfo) {
    if (videoInfo != null) {
      _getVideoInfoDataBean = videoInfo;
      if (!TextUtil.isEmpty(_getVideoInfoDataBean.likeCount)) {
        _linkCount = int.parse(_getVideoInfoDataBean.likeCount);
      } else {
        _linkCount = 0;
      }
      if (_getVideoInfoDataBean.platform == VideoInfoResponse.platformUGC ||
          _getVideoInfoDataBean.topicClass == VideoInfoResponse.topicClassYes) {
        _popReward = popRewardHot;
      } else {
        _popReward = popRewardNormal;
      }
      if (TextUtil.isEmpty(widget._videoDetailPageParamsBean.getUid)) {
        widget._videoDetailPageParamsBean.setUid =
            _getVideoInfoDataBean.uid ?? '';
      }
      return true;
    } else {
      _linkCount = 0;
    }
    return false;
  }

  Future<void> _initVideoPlayers(String videoUrl) async {
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    return _videoPlayerController.initialize().then((_) {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: true,
        looping: true,
        showControlsOnInitialize: false,
        allowMuting: false,
        isLive: _videoPlayerController.value.duration == Duration.zero,
        customControls: CosTVControls(),
        materialProgressColors: CosTVControlColor.MaterialProgressColors,
        routePageBuilder:
            CosTvFullScreenBuilder.of(_videoPlayerController.value.aspectRatio),
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      );
      _videoPlayerController.addListener(videoPlayerChanged);
    });
  }

  void videoPlayerChanged() {
    VideoPlayerValue playerValue = _videoPlayerController?.value;
    if (playerValue == null) {
      return;
    }

    // 对接看视频得POP倒计时
    if (playerValue.isPlaying) {
      if (_timerUtil != null && !_timerUtil.isActive()) {
        _timerUtil.startCountDown();
      }
    } else {
      if (_timerUtil != null && _timerUtil.isActive()) {
        _timerUtil.cancel();
      }
    }

    // 观看时长埋点
    if (playerValue.isPlaying) {
      if (_currentPlayerPosition != playerValue.position) {
        _lastPlayerPosition = _currentPlayerPosition;
        _currentPlayerPosition = playerValue.position;

        if (_currentPlayerPosition.inSeconds >= 1 &&
            _lastPlayerPosition.inSeconds < 1) {
          DataReportUtil.instance.reportData(
            eventName: "Video_play",
            params: {"vid": _getVideoInfoDataBean?.id ?? ""},
          );
        }

        if (playerValue.duration > Duration.zero) {
          Duration threshold = playerValue.duration * 0.9;
          if (_currentPlayerPosition >= threshold &&
              _lastPlayerPosition < threshold) {
            DataReportUtil.instance.reportData(
              eventName: "Video_done",
              params: {
                "vid": _getVideoInfoDataBean?.id ?? "",
                "watchtime": _currentPlayerPosition.inSeconds,
              },
            );
          }
        }
      }
    }
  }

  /// 添加视频点赞
  void _httpVideoLike() async {
    setState(() {
      _isNetIng = true;
    });
    if (_cosInfoBean == null) {
      //先公链获取视频account信息,否则点赞成功之后没法计算视频的增值
      AccountResponse bean = await CosSdkUtil.instance
          .getAccountChainInfo(Constant.accountName ?? '');
      if (bean != null) {
        _cosInfoBean = bean.info;
      } else {
        ToastUtil.showToast(InternationalLocalizations.httpError);
        return;
      }
    }
    RequestManager.instance
        .videoLike(tag, widget._videoDetailPageParamsBean?.getVid ?? '',
            Constant.accountName ?? '')
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleProxyBean bean =
          SimpleProxyBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleProxyResponse.statusStrSuccess &&
          bean.data != null) {
        if (bean.data.ret == SimpleProxyResponse.responseSuccess) {
          _linkCount++;
          _isVideoLike = true;
          String addVal = Common.calcVideoAddedIncome(
              _cosInfoBean,
              _exchangeRateInfoData,
              _chainStateBean,
              _getVideoInfoDataBean.votepower,
              _getVideoInfoDataBean.vestGift);
          if (Common.checkIsNotEmptyStr(addVal)) {
            var videoWorthKey =
                _getAddMoneyViewKeyFromSymbol(_getVideoInfoDataBean.id);
            if (videoWorthKey != null && videoWorthKey.currentState != null) {
              videoWorthKey.currentState.startShowWithAni(
                  "+ " + '${Common.getCurrencySymbolByLanguage()} $addVal');
            }
          }
          _addVoterPowerToVideo();
        } else {
          if (_mapRemoteResError != null && bean.data.ret != null) {
            ToastUtil.showToast(_mapRemoteResError[bean.data.ret] ?? '');
          } else {
            ToastUtil.showToast(bean?.data?.error ?? '');
          }
        }
      } else {
        ToastUtil.showToast(bean?.data?.error ?? '');
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNetIng = false;
      });
    });
  }

  /// 处理检测视频是否点赞过返回数据
  void _processVideoIsLike(Response response, bool isCarryOnLike) {
    SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
    if (bean.status == SimpleResponse.statusStrSuccess) {
      if (bean.data == VideoIsLikeResponse.isLikeYes) {
        _isVideoLike = true;
      } else {
        _isVideoLike = false;
      }
      if (isCarryOnLike) {
        _checkAbleVideoLike();
      }
    } else {
      if (isCarryOnLike) {
        setState(() {
          _isNetIng = false;
        });
      }
    }
  }

  /// 添加关注
  void _httpAccountFollow() {
    setState(() {
      _isNetIng = true;
    });
    RequestManager.instance
        .accountFollow(
            tag, Constant.uid ?? '', _getVideoInfoDataBean?.uid ?? '')
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data == SimpleResponse.responseSuccess) {
          _isFollow = true;
        }
      } else {
        if (bean.status == "50007") {
          ToastUtil.showToast(InternationalLocalizations.followSelfErrorTips);
        } else {
          ToastUtil.showToast(bean.msg);
        }
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNetIng = false;
      });
    });
  }

  /// 取消关注
  void _httpAccountUnFollow() {
    setState(() {
      _isNetIng = true;
    });
    RequestManager.instance
        .accountUnFollow(
            tag, Constant.uid ?? '', _getVideoInfoDataBean?.uid ?? '')
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data == SimpleResponse.responseSuccess) {
          _isFollow = false;
        }
      } else {
        ToastUtil.showToast(bean.msg);
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNetIng = false;
      });
    });
  }

  ///处理是否关注返回数据
  void _processAccountIsFollow(Response response) {
    SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
    if (bean.status == SimpleResponse.statusStrSuccess) {
      if (bean.data == FollowStateResponse.followStateFollowing ||
          bean.data == FollowStateResponse.followStateFriend) {
        _isFollow = true;
      } else {
        _isFollow = false;
      }
    }
  }

  /// 添加留言
  void _httpVideoComment(String accountName, String id, String content) {
    setState(() {
      _isNetIng = true;
    });
    RequestManager.instance
        .videoComment(tag, id, accountName, content)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleProxyBean bean =
          SimpleProxyBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleProxyResponse.statusStrSuccess &&
          bean.data != null) {
        if (bean.data.ret == SimpleProxyResponse.responseSuccess) {
          _textController.text = '';
          _commentSendType = CommentSendType.commentSendTypeNormal;
          _isAbleSendMsg = false;
          Future.delayed(Duration(seconds: 3), () {
            _httpVideoCommentList(false, false);
          });
        } else {
          if (_mapRemoteResError != null && bean.data.ret != null) {
            ToastUtil.showToast(_mapRemoteResError[bean.data.ret] ?? '');
          } else {
            ToastUtil.showToast(bean?.data?.error ?? '');
          }
          setState(() {
            _isNetIng = false;
          });
        }
      } else {
        setState(() {
          _isNetIng = false;
        });
        ToastUtil.showToast(bean?.data?.error ?? '');
      }
    });
  }

  /// 获取评论列表
  void _httpVideoCommentList(bool isLoadMore, bool isClearData) {
    setState(() {
      if (isLoadMore) {
        _isLoadMoreComment = true;
      } else {
        _isNetIng = true;
      }
    });
    if (!isLoadMore) {
      _commentPage = 1;
    }
    String vid = _getVideoId();
    RequestManager.instance
        .videoCommentList(tag, vid, _commentPage, commentPageSize,
            uid: Constant.uid ?? '',
            orderBy: _commentTypeCurrent == CommentType.commentTypeHot
                ? orderByHot
                : orderByTime)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      _processVideoCommentList(response, isLoadMore, isClearData);
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        if (isLoadMore) {
          _isLoadMoreComment = false;
        } else {
          _isNetIng = false;
        }
      });
    });
  }

  /// 处理评论列表返回数据
  bool _processVideoCommentList(
      Response response, bool isLoadMore, bool isClearData) {
    if (response == null) {
      return false;
    }
    CommentListBean bean = CommentListBean.fromJson(json.decode(response.data));
    if (bean.status == SimpleResponse.statusStrSuccess &&
        bean.data != null &&
        bean.data.list != null &&
        bean.data.list.isNotEmpty) {
      _commentListDataBean = bean.data;
      if (!isLoadMore || isClearData) {
        _listComment.clear();
        if (_commentListDataBean.top != null) {
          _listComment.add(_commentListDataBean.top);
        }
      }
      if (_commentListDataBean.list != null &&
          _commentListDataBean.list.isNotEmpty) {
        _listComment.addAll(_commentListDataBean.list);
        _commentPage++;
      }
      return true;
    } else {
      ToastUtil.showToast(bean.msg);
      return false;
    }
  }

  /// 添加评论点赞
  void _httpCommentLike(String cid, int index, String accountName) async {
    setState(() {
      _isNetIng = true;
    });

    if (_cosInfoBean == null) {
      //先公链获取视频account信息,否则点赞成功之后没法计算评论的增值
      AccountResponse bean = await CosSdkUtil.instance
          .getAccountChainInfo(Constant.accountName ?? '');
      if (bean != null) {
        _cosInfoBean = bean.info;
      } else {
        ToastUtil.showToast(InternationalLocalizations.httpError);
        return;
      }
    }

    RequestManager.instance
        .commentLike(tag, cid ?? '', accountName)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleProxyBean bean =
          SimpleProxyBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleProxyResponse.statusStrSuccess &&
          bean.data != null) {
        GlobalObjectKey<VideoAddMoneyWidgetState> commentKey;
        String addVal = "";
        if (bean.data.ret == SimpleProxyResponse.responseSuccess) {
          if (_listComment[index] is CommentListDataListBean) {
            CommentListDataListBean commentListDataListBean =
                _listComment[index];
            commentListDataListBean?.isLike = '1';
            if (!TextUtil.isEmpty(commentListDataListBean?.likeCount)) {
              commentListDataListBean?.likeCount =
                  (int.parse(commentListDataListBean?.likeCount) + 1)
                      .toString();
            }
            commentKey =
                _getAddMoneyViewKeyFromSymbol(commentListDataListBean.cid);
            addVal = Common.calcCommentAddedIncome(
                _cosInfoBean,
                _exchangeRateInfoData,
                _chainStateBean,
                commentListDataListBean.votepower);
            _addVoterPowerToNormalComment(commentListDataListBean);
          } else if (_listComment[index] is CommentListTopBean) {
            CommentListTopBean commentListTopBean = _listComment[index];
            commentListTopBean?.isLike = '1';
            if (!TextUtil.isEmpty(commentListTopBean?.likeCount)) {
              commentListTopBean?.likeCount =
                  (int.parse(commentListTopBean?.likeCount) + 1).toString();
            }
            commentKey = _getAddMoneyViewKeyFromSymbol(commentListTopBean.cid);
            addVal = Common.calcCommentAddedIncome(
                _cosInfoBean,
                _exchangeRateInfoData,
                _chainStateBean,
                commentListTopBean.votepower);
            _addVoterPowerToTopComment(commentListTopBean);
          }
          if (Common.checkIsNotEmptyStr(addVal) &&
              commentKey != null &&
              commentKey.currentState != null) {
            commentKey.currentState.startShowWithAni(
                "+ " + '${Common.getCurrencySymbolByLanguage()} $addVal');
          }
        } else {
          if (_mapRemoteResError != null && bean.data.ret != null) {
            ToastUtil.showToast(_mapRemoteResError[bean.data.ret] ?? '');
          } else {
            ToastUtil.showToast(bean?.data?.error ?? '');
          }
        }
      } else {
        ToastUtil.showToast(bean?.data?.error ?? '');
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNetIng = false;
      });
    });
  }

  /// 视频相关推荐列表接口
  void _httpVideoRelateList(bool isLoadMore) {
    if (!isLoadMore) {
      setState(() {
        _isNetIng = true;
      });
    }
    String vid = _getVideoId();
    RequestManager.instance
        .videoRelateList(tag, vid,
            page: _videoPage.toString(), pageSize: videoPageSize.toString())
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      _processVideoRelateList(response);
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNetIng = false;
      });
    });
  }

  /// 处理视频相关推荐列表返回数据
  bool _processVideoRelateList(Response response) {
    if (response == null) {
      return false;
    }
    RelateListBean bean = RelateListBean.fromJson(json.decode(response.data));
    if (bean.status == SimpleResponse.statusStrSuccess &&
        bean.data != null &&
        bean.data[0] != null) {
      if (bean.data[0].list != null && bean.data[0].list.isNotEmpty) {
        _listRelate = bean.data[0].list;
        _listData.addAll(_listRelate);
        _videoPage++;
      }
      _isHaveMoreData = bean.data[0].hasNext == "1";
      return true;
    } else {
      ToastUtil.showToast(bean?.msg ?? '');
      return false;
    }
  }

  String _getVideoId() {
    String vid = '';
    if (_getVideoInfoDataBean != null && _getVideoInfoDataBean.id != null) {
      vid = _getVideoInfoDataBean.id;
    } else if (widget._videoDetailPageParamsBean != null &&
        widget._videoDetailPageParamsBean.getVid != null) {
      vid = widget._videoDetailPageParamsBean.getVid;
    }
    return vid;
  }

  /// 看视频得积分接口
  void _httpIntegralVideoIntegral() async {
    if (_isGetVideoPop) {
      return;
    }
    setState(() {
      _isGetVideoPop = true;
    });
    String deviceId = await PlatformUtil.getDeviceID();
    RequestManager.instance
        .integralVideoIntegral(tag, Constant.uid ?? '', _popReward.toString(),
            did: deviceId)
        .then((response) {
      if (response == null || !mounted) {
        _isGetVideoPop = false;
        return;
      }
      IntegralVideoIntegralBean bean =
          IntegralVideoIntegralBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleProxyResponse.statusStrSuccess) {
        if (_bankPropertyDataBean != null &&
            _bankPropertyDataBean.popcorn != null &&
            !TextUtil.isEmpty(_bankPropertyDataBean.popcorn.popcornbal)) {
          _bankPropertyDataBean.popcorn.popcornbal =
              (int.parse(_bankPropertyDataBean.popcorn.popcornbal) + _popReward)
                  .toString();
        }
      } else {
        if (_mapVideoIntegralError != null && bean.status != null) {
          ToastUtil.showToast(_mapVideoIntegralError[bean.status]);
        } else {
          ToastUtil.showToast(bean?.msg);
        }
      }
    }).whenComplete(() {
      _isGetVideoPop = false;
    });
  }

  /// 处理查询汇率返回数据
  void _processExchangeRateInfo(Response response) {
    ExchangeRateInfoBean info =
        ExchangeRateInfoBean.fromJson(json.decode(response.data));
    if (info.status == SimpleResponse.statusStrSuccess) {
      _exchangeRateInfoData = info.data;
    }
  }

  void _checkAbleVideoLike() {
    if (!_isVideoLike &&
        _getVideoInfoDataBean != null &&
        !TextUtil.isEmpty(_getVideoInfoDataBean.id)) {
      if (!ObjectUtil.isEmptyString(Constant.accountName)) {
        if (_checkIsEnergyEnough()) {
          _httpVideoLike();
        } else {
          _showEnergyNotEnoughDialog();
        }
      } else {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) {
          return WebViewPage(Constant.logInWebViewUrl);
        })).then((isSuccess) {
          if (isSuccess != null && isSuccess) {
            _httpVideoIsLike(true);
            _addWatchHistory();
          }
        });
      }
    }
  }

  void _checkAbleAccountFollow() {
    if (!ObjectUtil.isEmptyString(Constant.uid)) {
      if (_isFollow) {
        _httpAccountUnFollow();
      } else {
        _httpAccountFollow();
      }
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) {
        return WebViewPage(Constant.logInWebViewUrl);
      })).then((isSuccess) {
        if (isSuccess != null && isSuccess) {
          _checkAbleAccountFollow();
          _addWatchHistory();
        }
      });
    }
  }

  void _checkAbleCommentLike(String isLike, String cid, int index) {
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      if (isLike == CommentListDataListBean.isLikeNo) {
        if (_checkIsEnergyEnough()) {
          _httpCommentLike(cid, index, Constant.accountName);
        } else {
          _showEnergyNotEnoughDialog();
        }
      }
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) {
        return WebViewPage(Constant.logInWebViewUrl);
      })).then((isSuccess) {
        if (isSuccess != null && isSuccess) {
          _checkAbleCommentLike(isLike, cid, index);
          _addWatchHistory();
        }
      });
    }
  }

  void _checkAbleVideoComment(String id) {
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      if (_isAbleSendMsg) {
        String content;
        if (_commentSendType == CommentSendType.commentSendTypeNormal) {
          content = _textController.text.trim();
        } else {
          content = Constant.commentSendHtml(
              _uid, _commentName, _textController.text.trim());
        }
        FocusScope.of(context).requestFocus(FocusNode());
        _httpVideoComment(Constant.accountName, id, content);
      }
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) {
        return WebViewPage(Constant.logInWebViewUrl);
      })).then((isSuccess) {
        if (isSuccess != null && isSuccess) {
          _checkAbleVideoComment(id);
          _addWatchHistory();
        }
      });
    }
  }

  bool _checkIsEnergyEnough() {
    double energy = RevenueCalculationUtil.calCurrentEnergy(
        _cosInfoBean?.votePower?.toString(),
        _cosInfoBean.vest.value?.toString());
    double lowest = RevenueCalculationUtil.calLowestEnergyConsume(
        _cosInfoBean?.vest?.value?.toString());

    CosLogUtil.log('$tag energy: $energy, lowest: $lowest');

    return energy >= lowest;
  }

  void _showEnergyNotEnoughDialog() {
    if (_energyNotEnoughDialog == null) {
      _energyNotEnoughDialog =
          EnergyNotEnoughDialog(tag, _pageKey, _dialogSKey);
    }

    double energy = RevenueCalculationUtil.calCurrentEnergy(
        _cosInfoBean.votePower?.toString(),
        _cosInfoBean.vest.value?.toString());
    double maxEnergy = RevenueCalculationUtil.vestToEnergy(
        _cosInfoBean.vest?.value?.toString());
    int resumeMinutes =
        RevenueCalculationUtil.calResumeLowestEnergyMinutes(energy, maxEnergy);

    _energyNotEnoughDialog.initData(resumeMinutes.toString());
    _energyNotEnoughDialog.show();
  }

  Widget _buildPopShow() {
    if (!ObjectUtil.isEmptyString(Constant.uid)) {
      if (_isGetVideoPop) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppDimens.item_size_74,
              height: AppDimens.item_size_6,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.all(Radius.circular(AppDimens.radius_size_8)),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.color_ebebeb,
                  value: _animationController.value,
                  valueColor: ColorTween(
                          begin: AppColors.color_fdbc2e,
                          end: AppColors.color_ffe175)
                      .animate(_animationController),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: AppDimens.margin_5),
              width: AppDimens.item_size_20,
              height: AppDimens.item_size_20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.color_ffbe0e),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: AppDimens.margin_10),
              child: Image.asset('assets/images/ic_pop_number.png'),
            ),
            AutoSizeText(
              _bankPropertyDataBean?.popcorn?.popcornbal ?? '',
              style: AppStyles.text_style_f7b500_bold_14,
              minFontSize: 8,
            ),
          ],
        );
      } else {
        if (_integralUserInfoDataBean?.upperLimit ==
            IntegralUserInfoDataBean.upperLimitFinish) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: AppDimens.item_size_74,
                height: AppDimens.item_size_6,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(
                      Radius.circular(AppDimens.radius_size_8)),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.color_ebebeb,
                    value: _animationController.value,
                    valueColor: ColorTween(
                            begin: AppColors.color_fdbc2e,
                            end: AppColors.color_ffe175)
                        .animate(_animationController),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: AppDimens.margin_5),
                child: AutoSizeText(
                  '+$_popReward',
                  style: AppStyles.text_style_f7b500_bold_14,
                  minFontSize: 8,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: AppDimens.margin_5),
                child: AutoSizeText(
                  InternationalLocalizations.videoPopFinish,
                  style: AppStyles.text_style_f7b500_bold_12,
                  minFontSize: 8,
                ),
              )
            ],
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: AppDimens.item_size_74,
                height: AppDimens.item_size_6,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(
                      Radius.circular(AppDimens.radius_size_8)),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.color_ebebeb,
                    value: _animationController.value,
                    valueColor: ColorTween(
                            begin: AppColors.color_fdbc2e,
                            end: AppColors.color_ffe175)
                        .animate(_animationController),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: AppDimens.margin_5),
                child: AutoSizeText(
                  '+$_popReward',
                  style: AppStyles.text_style_f7b500_bold_14,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: AppDimens.margin_10),
                child: Image.asset('assets/images/ic_pop_number.png'),
              ),
              AutoSizeText(
                _bankPropertyDataBean?.popcorn?.popcornbal ?? '',
                style: AppStyles.text_style_f7b500_14,
                minFontSize: 8,
              ),
            ],
          );
        }
      }
    } else {
      return InkWell(
        onTap: () {
          if (Common.isAbleClick()) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) {
              return WebViewPage(Constant.logInWebViewUrl);
            })).then((isSuccess) {
              if (isSuccess != null && isSuccess) {
                setState(() {});
                _addWatchHistory();
              }
            });
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            left: AppDimens.margin_5,
            top: AppDimens.margin_5,
            bottom: AppDimens.margin_5,
          ),
          child: AutoSizeText(
            InternationalLocalizations.videoLoginPop,
            style: AppStyles.text_style_858585_underline_bold_12,
            minFontSize: 8,
          ),
        ),
      );
    }
  }

  Widget _buildListHead() {
    if (_getVideoInfoDataBean == null) {
      return Container();
    }
    int millisecondsSinceEpoch = 0;
    if (_getVideoInfoDataBean != null &&
        !TextUtil.isEmpty(_getVideoInfoDataBean?.createdAt)) {
      millisecondsSinceEpoch =
          int.parse(_getVideoInfoDataBean.createdAt) * 1000;
    }
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    double dx = 0;
    double dy = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: () {
            if (Common.isAbleClick()) {
              setState(() {
                _isHideVideoMsg = !_isHideVideoMsg;
                _isRotatedTitle = !_isRotatedTitle;
              });
            }
          },
          child: Container(
            margin: EdgeInsets.only(
                left: AppDimens.margin_15, right: AppDimens.margin_15),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: AppDimens.item_size_300,
                  child: AutoSizeText(
                    _getVideoInfoDataBean?.title ?? '',
                    style: AppStyles.text_style_333333_bold_16,
                    minFontSize: 8,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: AppDimens.margin_5),
                  child: AnimationRotateWidget(
                    rotated: _isRotatedTitle,
                    child: Image.asset('assets/images/ic_down_title.png'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(
              left: AppDimens.margin_15,
              top: AppDimens.margin_6_5,
              right: AppDimens.margin_15),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset('assets/images/ic_play_count.png'),
                  Container(
                    margin: EdgeInsets.only(left: AppDimens.margin_3),
                    child: AutoSizeText(
                      _getVideoInfoDataBean?.watchNum ?? '',
                      style: AppStyles.text_style_a0a0a0_12,
                      minFontSize: 8,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: AppDimens.margin_10),
                    child: Image.asset('assets/images/ic_release_time.png'),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: AppDimens.margin_3),
                    child: AutoSizeText(
                      '${dateTime.month}.${dateTime.day}',
                      style: AppStyles.text_style_a0a0a0_12,
                      minFontSize: 8,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: AppDimens.margin_10),
                    child: Image.asset('assets/images/ic_gift_count.png'),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: AppDimens.margin_3),
                    child: AutoSizeText(
                      _videoGiftInfoDataBean?.rewardTotal ?? '',
                      style: AppStyles.text_style_a0a0a0_12,
                      minFontSize: 8,
                    ),
                  ),
                ],
              ),
              _buildPopShow(),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(
              left: AppDimens.margin_41,
              top: AppDimens.margin_8,
              right: AppDimens.margin_41),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Material(
                color: AppColors.color_transparent,
                child: Ink(
                  child: InkWell(
                      onTap: () {
                        if (Common.isAbleClick()) {
                          if (_getVideoInfoDataBean?.vestStatus !=
                              VideoInfoResponse.vestStatusFinish) {
                            _checkAbleVideoLike();
                          } else {
                            ToastUtil.showToast(
                                InternationalLocalizations.videoLinkFinishHint);
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(AppDimens.margin_5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            (_isVideoLike)
                                ? Image.asset(
                                    'assets/images/ic_video_like_yes.png')
                                : Image.asset(
                                    'assets/images/ic_video_like_no.png'),
                            Container(
                              margin: EdgeInsets.only(top: AppDimens.margin_8),
                              child: AutoSizeText(
                                '$_linkCount',
                                style: AppStyles.text_style_858585_11,
                                minFontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      )),
                ),
              ),
              Material(
                color: AppColors.color_transparent,
                child: Ink(
                  child: InkWell(
                    onTap: () {
                      if (Common.isAbleClick()) {
                        if (_getVideoInfoDataBean != null) {
                          final RenderBox box = context.findRenderObject();
                          Share.share(
                              '${_getVideoInfoDataBean?.title ?? ''}_COS.TV\n${_getVideoInfoDataBean?.introduction ?? ''}\n${Constant.shareUrl}${_getVideoInfoDataBean?.id ?? ''}',
                              subject: _getVideoInfoDataBean?.title ?? '',
                              sharePositionOrigin:
                                  box.localToGlobal(Offset.zero) & box.size);
                        }
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(AppDimens.margin_5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset('assets/images/ic_share.png'),
                          Container(
                            margin: EdgeInsets.only(top: AppDimens.margin_8),
                            child: AutoSizeText(
                              InternationalLocalizations.videoShare,
                              style: AppStyles.text_style_858585_11,
                              minFontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                color: AppColors.color_transparent,
                child: Ink(
                  child: InkWell(
                    onTap: () {
                      if (Common.isAbleClick()) {
                        if (_videoReportDialog == null) {
                          _videoReportDialog =
                              VideoReportDialog(tag, _pageKey, _dialogSKey);
                        }
                        _videoReportDialog.initData(
                            _getVideoInfoDataBean?.id ?? '',
                            _getVideoInfoDataBean?.duration ?? '0');
                        _videoReportDialog.showVideoReportDialog();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(AppDimens.margin_5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset('assets/images/ic_report.png'),
                          Container(
                            margin: EdgeInsets.only(top: AppDimens.margin_8),
                            child: AutoSizeText(
                              InternationalLocalizations.videoReport,
                              style: AppStyles.text_style_858585_11,
                              minFontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: AppDimens.margin_8),
          child: Container(
            height: AppDimens.item_line_height_1,
            color: AppColors.color_e4e4e4,
          ),
        ),
        Container(
          margin: EdgeInsets.all(AppDimens.margin_15),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: AutoSizeText(
                  _strSettlementTime,
                  style: AppStyles.text_style_a0a0a0_13,
                  minFontSize: 8,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (details) {
                  dx = details.globalPosition.dx;
                  dy = details.globalPosition.dy;
                },
                onTap: () {
                  if (Common.isAbleClick()) {
                    if (_getVideoInfoDataBean != null) {
                      setState(() {
                        _isRotatedMoney = !_isRotatedMoney;
                      });
                      Navigator.push(
                        context,
                        PopupWindowRoute(
                          child: PopupWindow(
                            VideoSettlementWindow(_videoSettlementBean),
                            left: dx - AppDimens.item_size_220,
                            top: dy + AppDimens.item_size_5,
                            onCloseListener: () {
                              setState(() {
                                _isRotatedMoney = !_isRotatedMoney;
                              });
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    VideoAddMoneyWidget(
                        key: _getAddMoneyViewKeyFromSymbol(
                            _getVideoInfoDataBean?.id),
                        textStyle: AppStyles.text_style_333333_bold_18,
                        baseWidget: AutoSizeText(
                          '${Common.getCurrencySymbolByLanguage()} ${_videoSettlementBean.getTotalRevenue ?? ""}',
                          style: AppStyles.text_style_333333_bold_18,
                          minFontSize: 8,
                        )),
                    Container(
                      padding: EdgeInsets.only(left: AppDimens.margin_10),
                      child: AnimationRotateWidget(
                        rotated: _isRotatedMoney,
                        child: Image.asset('assets/images/ic_down_money.png'),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          height: AppDimens.item_line_height_1,
          color: AppColors.color_e4e4e4,
        ),
        Container(
          margin: EdgeInsets.only(
              top: AppDimens.margin_15, bottom: AppDimens.margin_15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(
                    left: AppDimens.margin_15, right: AppDimens.margin_15),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    InkWell(
                      child: Stack(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: AppColors.color_ffffff,
                            radius: AppDimens.item_size_20,
                            backgroundImage: AssetImage(
                                'assets/images/ic_default_avatar.png'),
                          ),
                          CircleAvatar(
                            backgroundColor: AppColors.color_transparent,
                            radius: AppDimens.item_size_20,
                            backgroundImage: CachedNetworkImageProvider(
                              _getVideoInfoDataBean?.anchorAvatar ?? '',
                            ),
                          )
                        ],
                      ),
                      onTap: () {
                        if (Common.isAbleClick()) {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) {
                            return WebViewPage(
                              '${Constant.otherUserCenterWebViewUrl}${_getVideoInfoDataBean?.uid}',
                            );
                          }));
                        }
                      },
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: AppDimens.margin_10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              child: AutoSizeText(
                                _getVideoInfoDataBean?.anchorNickname ?? '',
                                style: AppStyles.text_style_333333_14,
                                minFontSize: 8,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: AppDimens.margin_3),
                              child: AutoSizeText(
                                '${_getVideoInfoDataBean?.followerCount ?? '0'} ${InternationalLocalizations.videoSubscriptionCount}',
                                style: AppStyles.text_style_a0a0a0_12,
                                minFontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: AppDimens.item_size_80,
                      height: AppDimens.item_size_25,
                      child: Material(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radius_size_21),
                        color: _isFollow
                            ? AppColors.color_d6d6d6
                            : AppColors.color_3674ff,
                        child: MaterialButton(
                          child: AutoSizeText(
                            _isFollow
                                ? InternationalLocalizations
                                    .videoSubscriptionFinish
                                : InternationalLocalizations.videoSubscription,
                            style: AppStyles.text_style_ffffff_12,
                            minFontSize: 8,
                            maxLines: 1,
                          ),
                          onPressed: () {
                            _checkAbleAccountFollow();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Offstage(
                offstage: _isHideVideoMsg,
                child: Container(
                  margin: EdgeInsets.only(
                      left: AppDimens.margin_15,
                      top: AppDimens.margin_5,
                      right: AppDimens.margin_15),
                  child: Column(
                    children: <Widget>[
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.only(
                            left: AppDimens.margin_50,
                            top: AppDimens.margin_11),
                        child: AutoSizeText(
                          _getVideoInfoDataBean?.introduction ?? '',
                          style: AppStyles.text_style_333333_13,
                          minFontSize: 8,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                            left: AppDimens.margin_50, top: AppDimens.margin_5),
                        height: AppDimens.item_size_30,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (BuildContext context, int index) {
                            TagNameBean tagName =
                                _getVideoInfoDataBean?.tagName[index];
                            return Container(
                              margin:
                                  EdgeInsets.only(right: AppDimens.margin_5),
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        centerSlice:
                                            Rect.fromLTWH(80, 30, 150, 60),
                                        image: AssetImage(
                                          'assets/images/bg_label.png',
                                        ),
                                      ),
                                    ),
                                    padding: EdgeInsets.only(
                                        left: AppDimens.margin_20,
                                        top: AppDimens.margin_2,
                                        right: AppDimens.margin_5,
                                        bottom: AppDimens.margin_2),
                                    child: AutoSizeText(
                                      tagName?.content ?? '',
                                      style: AppStyles.text_style_858585_11,
                                      minFontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          itemCount:
                              _getVideoInfoDataBean?.tagName?.length ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: AppDimens.margin_15),
                child: Container(
                  height: AppDimens.item_line_height_1,
                  color: AppColors.color_e4e4e4,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  String calculationSettlementTime() {
    double timeCountNum = 0;
    if (!TextUtil.isEmpty(_getVideoInfoDataBean?.blocknumber)) {
      if (_chainStateBean != null &&
          _chainStateBean.dgpo != null &&
          _chainStateBean.dgpo.headBlockNumber != null) {
        double difference = NumUtil.subtract(
            NumUtil.add(settlementTime,
                double.parse(_getVideoInfoDataBean.blocknumber)),
            _chainStateBean.dgpo.headBlockNumber.toInt());
        timeCountNum = difference > 0
            ? NumUtil.add(NumUtil.multiply(difference, 1000),
                DateTime.now().millisecondsSinceEpoch)
            : 0;
      }
    } else {
      if (!TextUtil.isEmpty(_getVideoInfoDataBean?.createdAt)) {
        timeCountNum = NumUtil.multiply(
            NumUtil.add(
                double.parse(_getVideoInfoDataBean?.createdAt), settlementTime),
            1000);
      }
    }
    String time = _timeFormatUtil.formatTime(timeCountNum.toInt());
    if (!ObjectUtil.isEmptyString(time)) {
      return '${InternationalLocalizations.videoRemainingSettlementTime}: $time';
    } else {
      return time;
    }
  }

  Widget _buildCommentTable(CommentType showType) {
    return InkWell(
      onTap: () {
        if (Common.isAbleClick()) {
          setState(() {
            _commentTypeCurrent = showType;
            _httpVideoCommentList(false, false);
          });
        }
      },
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AutoSizeText(
                showType == CommentType.commentTypeHot
                    ? InternationalLocalizations.videoHotSort
                    : InternationalLocalizations.videoTimeSort,
                style: showType == _commentTypeCurrent
                    ? AppStyles.text_style_333333_bold_14
                    : AppStyles.text_style_a0a0a0_14,
                minFontSize: 8,
              ),
              Offstage(
                offstage: !(showType == _commentTypeCurrent),
                child: Container(
                  margin: EdgeInsets.only(top: AppDimens.margin_4_5),
                  width: AppDimens.item_size_30,
                  height: AppDimens.item_size_2,
                  color: AppColors.color_333333,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabStyle() {
    String languageCode = Common.getLanCodeByLanguage();
    if (languageCode == InternationalLocalizations.languageCodeZh_Cn ||
        languageCode == InternationalLocalizations.languageCodeZh) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCommentTable(CommentType.commentTypeHot),
          Container(
            margin: EdgeInsets.only(left: AppDimens.margin_30),
            child: _buildCommentTable(CommentType.commentTypeTime),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCommentTable(CommentType.commentTypeHot),
          Container(
            margin: EdgeInsets.only(top: AppDimens.margin_10),
            child: _buildCommentTable(CommentType.commentTypeTime),
          ),
        ],
      );
    }
  }

  Widget _buildCommentTopItem(
      CommentListTopBean commentListTopBean, int index) {
    int childrenCount = 0;
    if (!TextUtil.isEmpty(commentListTopBean?.childrenCount)) {
      childrenCount = int.parse(commentListTopBean?.childrenCount);
    }
    int childrenLength = commentListTopBean?.children?.length ?? 0;
    String totalRevenue = "";
    if (commentListTopBean != null && _exchangeRateInfoData != null) {
      if (commentListTopBean?.vestStatus ==
          VideoInfoResponse.vestStatusFinish) {
        /// 奖励完成
        double totalRevenueVest = NumUtil.divide(
          NumUtil.getDoubleByValueStr(commentListTopBean?.vest ?? ''),
          RevenueCalculationUtil.cosUnit,
        );
        double money = RevenueCalculationUtil.vestToRevenue(
            totalRevenueVest, _exchangeRateInfoData);
        totalRevenue = Common.formatDecimalDigit(money, 2);
      } else {
        /// 奖励未完成
//        double settlementBonusVest = RevenueCalculationUtil.getVideoRevenueVest(
////            commentListTopBean?.votepower, _chainStateBean?.dgpo);
        double settlementBonusVest = RevenueCalculationUtil.getReplyVestByPower(
            commentListTopBean?.votepower, _chainStateBean?.dgpo);
        double money = RevenueCalculationUtil.vestToRevenue(
            settlementBonusVest, _exchangeRateInfoData);
        totalRevenue = Common.formatDecimalDigit(money, 2);
      }
    }
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(AppDimens.margin_15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InkWell(
                child: Stack(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: AppColors.color_ffffff,
                      radius: AppDimens.item_size_15,
                      backgroundImage:
                          AssetImage('assets/images/ic_default_avatar.png'),
                    ),
                    CircleAvatar(
                      backgroundColor: AppColors.color_transparent,
                      radius: AppDimens.item_size_15,
                      backgroundImage: CachedNetworkImageProvider(
                        commentListTopBean?.user?.avatar ?? '',
                      ),
                    )
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                    return WebViewPage(
                      '${Constant.otherUserCenterWebViewUrl}${commentListTopBean?.uid}',
                    );
                  }));
                },
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: AppDimens.margin_7_5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Offstage(
                                offstage: !(commentListTopBean?.isTopOne ==
                                    CommentListDataListBean.isTopOneYes),
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: AppDimens.margin_5),
                                  child: Image.asset(
                                      'assets/images/ic_comment_first.png'),
                                ),
                              ),
                              InkWell(
                                child: LimitedBox(
                                  maxWidth: AppDimens.item_size_100,
                                  child: Text(
                                    commentListTopBean?.user?.nickname ?? '',
                                    style: AppStyles.text_style_333333_bold_12,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) {
                                    return WebViewPage(
                                      '${Constant.otherUserCenterWebViewUrl}${commentListTopBean?.uid}',
                                    );
                                  }));
                                },
                              ),
                              Offstage(
                                offstage: !(commentListTopBean?.isSendTicket ==
                                    CommentListDataListBean.isSendTicketYes),
                                child: Container(
                                  margin:
                                      EdgeInsets.only(left: AppDimens.margin_2),
                                  child: Image.asset(
                                      'assets/images/ic_comment_heart.png'),
                                ),
                              ),
                              Container(
                                margin:
                                    EdgeInsets.only(left: AppDimens.margin_10),
                                child: AutoSizeText(
                                  Common.calcDiffTimeByStartTime(
                                      commentListTopBean?.createdAt ?? ''),
                                  style: AppStyles.text_style_a0a0a0_12,
                                  minFontSize: 8,
                                ),
                              ),
                              Container(
                                margin:
                                    EdgeInsets.only(left: AppDimens.margin_10),
                                child: VideoAddMoneyWidget(
                                  baseWidget: Text(
                                    '${Common.getCurrencySymbolByLanguage()} ${totalRevenue ?? ''}',
                                    style: AppStyles.text_style_333333_bold_12,
                                  ),
                                  textStyle:
                                      AppStyles.text_style_333333_bold_12,
                                  key: _getAddMoneyViewKeyFromSymbol(
                                      commentListTopBean.cid),
                                ),
                              )
                            ],
                          ),
                          InkWell(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                AutoSizeText(
                                  commentListTopBean?.likeCount ?? '0',
                                  style: AppStyles.text_style_a0a0a0_14,
                                  minFontSize: 8,
                                ),
                                Container(
                                  margin:
                                      EdgeInsets.only(left: AppDimens.margin_5),
                                  child: commentListTopBean?.isLike ==
                                          CommentListDataListBean.isLikeYes
                                      ? Image.asset(
                                          'assets/images/ic_comment_like_yes.png')
                                      : Image.asset(
                                          'assets/images/ic_comment_like_no.png'),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (Common.isAbleClick()) {
                                if (commentListTopBean?.vestStatus !=
                                    VideoInfoResponse.vestStatusFinish) {
                                  _checkAbleCommentLike(
                                      commentListTopBean?.isLike ?? '',
                                      commentListTopBean?.cid ?? '',
                                      index);
                                } else {
                                  ToastUtil.showToast(InternationalLocalizations
                                      .videoLinkFinishHint);
                                }
                              }
                            },
                          )
                        ],
                      ),
                      InkWell(
                        child: Container(
                          width: AppDimens.item_size_290,
                          margin: EdgeInsets.only(top: AppDimens.margin_5),
                          child: Html(
                            data: commentListTopBean?.content ?? '',
                            defaultTextStyle: AppStyles.text_style_333333_14,
                            onLinkTap: (url) {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) {
                                return WebViewPage(
                                  '${Constant.otherUserCenterWebViewUrl}${commentListTopBean?.uid}',
                                );
                              }));
                            },
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _commentSendType =
                                CommentSendType.commentSendTypeChildren;
                            _commentId = commentListTopBean?.cid ?? '';
                            _commentName =
                                commentListTopBean?.user?.nickname ?? '';
                            _uid = commentListTopBean?.uid ?? '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Offstage(
          offstage: childrenLength == 0,
          child: Card(
            margin: EdgeInsets.only(
              left: AppDimens.margin_50,
              top: AppDimens.margin_5,
              right: AppDimens.margin_15,
              bottom: AppDimens.margin_6,
            ),
            color: AppColors.color_f2f2f2,
            elevation: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: List.generate(childrenLength, (int index) {
                    int childrenCount = 0;
                    if (!TextUtil.isEmpty(commentListTopBean?.childrenCount)) {
                      childrenCount =
                          int.parse(commentListTopBean?.childrenCount);
                    }
                    return _buildCommentChildrenItem(
                        commentListTopBean?.uid,
                        childrenCount,
                        commentListTopBean?.children[index]?.content ?? '',
                        commentListTopBean?.cid ?? '',
                        commentListTopBean?.children[index]?.user?.nickname ??
                            '',
                        index == (childrenLength - 1));
                  }),
                ),
                Offstage(
                  offstage: childrenCount <= childrenLength,
                  child: InkWell(
                    child: Container(
                      margin: EdgeInsets.only(
                          left: AppDimens.margin_10,
                          top: AppDimens.margin_5,
                          bottom: AppDimens.margin_10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AutoSizeText(
                            InternationalLocalizations.videoClickMoreComment,
                            style: AppStyles.text_style_3674ff_14,
                            minFontSize: 8,
                          ),
                          Container(
                            margin: EdgeInsets.only(left: AppDimens.margin_3),
                            child: Image.asset(
                                'assets/images/ic_right_comment.png'),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      if (Common.isAbleClick()) {
                        double statusBarHeight =
                            MediaQuery.of(context).padding.top;
                        double screenHeight =
                            MediaQuery.of(context).size.height;
                        double height = screenHeight -
                            statusBarHeight -
                            AppDimens.item_size_211;
                        CommentChildrenListParameterBean bean =
                            CommentChildrenListParameterBean();
                        bean.width = MediaQuery.of(context).size.width;
                        bean.height = height;
                        bean.vid = commentListTopBean?.children[0]?.vid ?? '';
                        bean.pid = commentListTopBean?.children[0]?.pid ?? '';
                        bean.uid = Constant.uid;
                        bean.mapRemoteResError = _mapRemoteResError;
                        bean.vestStatus =
                            _getVideoInfoDataBean?.vestStatus ?? '';
                        bean.cosInfoBean = _cosInfoBean;
                        bean.chainStateBean = _chainStateBean;
                        bean.exchangeRateInfoData = _exchangeRateInfoData;
                        bean.commentListTopBean = commentListTopBean;
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) {
                          return VideoCommentChildrenListWindow(bean);
                        }));
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
        Container(
          height: AppDimens.item_line_height_1,
          color: AppColors.color_e4e4e4,
        )
      ],
    );
  }

  Widget _buildCommentNormalItem(
      CommentListDataListBean commentListDataListBean, int index) {
    String totalRevenue = "";
    if (commentListDataListBean != null && _exchangeRateInfoData != null) {
      if (commentListDataListBean?.vestStatus ==
          VideoInfoResponse.vestStatusFinish) {
        /// 奖励完成
        double totalRevenueVest = NumUtil.divide(
          NumUtil.getDoubleByValueStr(commentListDataListBean?.vest ?? ''),
          RevenueCalculationUtil.cosUnit,
        );
        double money = RevenueCalculationUtil.vestToRevenue(
            totalRevenueVest, _exchangeRateInfoData);
        totalRevenue = Common.formatDecimalDigit(money, 2);
      } else {
        /// 奖励未完成
        double settlementBonusVest = RevenueCalculationUtil.getReplyVestByPower(
            commentListDataListBean?.votepower, _chainStateBean?.dgpo);
        double money = (RevenueCalculationUtil.vestToRevenue(
            settlementBonusVest, _exchangeRateInfoData));
        totalRevenue = Common.formatDecimalDigit(money, 2);
      }
    }
    int commentTotal = 0;
    if (!TextUtil.isEmpty(_commentListDataBean?.total)) {
      commentTotal = int.parse(_commentListDataBean?.total);
    }
    int commentLength = _listComment?.length ?? 0;
    int childrenCount = 0;
    if (!TextUtil.isEmpty(commentListDataListBean?.childrenCount)) {
      childrenCount = int.parse(commentListDataListBean?.childrenCount);
    }
    int childrenLength = commentListDataListBean?.children?.length ?? 0;
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(AppDimens.margin_15),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InkWell(
                child: Stack(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: AppColors.color_ffffff,
                      radius: AppDimens.item_size_15,
                      backgroundImage:
                          AssetImage('assets/images/ic_default_avatar.png'),
                    ),
                    CircleAvatar(
                      backgroundColor: AppColors.color_transparent,
                      radius: AppDimens.item_size_15,
                      backgroundImage: CachedNetworkImageProvider(
                        commentListDataListBean?.user?.avatar ?? '',
                      ),
                    )
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                    return WebViewPage(
                      '${Constant.otherUserCenterWebViewUrl}${commentListDataListBean?.uid}',
                    );
                  }));
                },
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: AppDimens.margin_7_5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Offstage(
                                offstage: !(commentListDataListBean?.isTopOne ==
                                    CommentListDataListBean.isTopOneYes),
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: AppDimens.margin_5),
                                  child: Image.asset(
                                      'assets/images/ic_comment_first.png'),
                                ),
                              ),
                              InkWell(
                                child: LimitedBox(
                                  maxWidth: AppDimens.item_size_100,
                                  child: Text(
                                    commentListDataListBean?.user?.nickname ??
                                        '',
                                    style: AppStyles.text_style_333333_bold_12,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) {
                                    return WebViewPage(
                                      '${Constant.otherUserCenterWebViewUrl}${commentListDataListBean?.uid}',
                                    );
                                  }));
                                },
                              ),
                              Offstage(
                                offstage: !(commentListDataListBean
                                        ?.isSendTicket ==
                                    CommentListDataListBean.isSendTicketYes),
                                child: Container(
                                  margin:
                                      EdgeInsets.only(left: AppDimens.margin_2),
                                  child: Image.asset(
                                      'assets/images/ic_comment_heart.png'),
                                ),
                              ),
                              Container(
                                margin:
                                    EdgeInsets.only(left: AppDimens.margin_10),
                                child: AutoSizeText(
                                  Common.calcDiffTimeByStartTime(
                                      commentListDataListBean?.createdAt ?? ''),
                                  style: AppStyles.text_style_a0a0a0_12,
                                  minFontSize: 8,
                                ),
                              ),
                              Container(
                                margin:
                                    EdgeInsets.only(left: AppDimens.margin_10),
                                child: VideoAddMoneyWidget(
                                  key: _getAddMoneyViewKeyFromSymbol(
                                      commentListDataListBean?.cid ?? ""),
                                  baseWidget: Text(
                                    '${Common.getCurrencySymbolByLanguage()} ${totalRevenue ?? ''}',
                                    style: AppStyles.text_style_333333_bold_12,
                                  ),
                                  textStyle:
                                      AppStyles.text_style_333333_bold_12,
                                  translateY: -20,
                                ),
                              )
                            ],
                          ),
                          InkWell(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                AutoSizeText(
                                  commentListDataListBean?.likeCount ?? '0',
                                  style: AppStyles.text_style_a0a0a0_14,
                                  minFontSize: 8,
                                ),
                                Container(
                                  margin:
                                      EdgeInsets.only(left: AppDimens.margin_5),
                                  child: commentListDataListBean?.isLike ==
                                          CommentListDataListBean.isLikeYes
                                      ? Image.asset(
                                          'assets/images/ic_comment_like_yes.png')
                                      : Image.asset(
                                          'assets/images/ic_comment_like_no.png'),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (Common.isAbleClick()) {
                                if (commentListDataListBean?.vestStatus !=
                                    VideoInfoResponse.vestStatusFinish) {
                                  _checkAbleCommentLike(
                                      commentListDataListBean?.isLike ?? '',
                                      commentListDataListBean?.cid ?? '',
                                      index);
                                } else {
                                  ToastUtil.showToast(InternationalLocalizations
                                      .videoLinkFinishHint);
                                }
                              }
                            },
                          )
                        ],
                      ),
                      InkWell(
                        child: Container(
                          margin: EdgeInsets.only(top: AppDimens.margin_5),
                          child: Html(
                            data: commentListDataListBean?.content ?? '',
                            defaultTextStyle: AppStyles.text_style_333333_14,
                            onLinkTap: (url) {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) {
                                return WebViewPage(
                                  '${Constant.otherUserCenterWebViewUrl}${commentListDataListBean?.uid}',
                                );
                              }));
                            },
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _commentSendType =
                                CommentSendType.commentSendTypeChildren;
                            _commentId = commentListDataListBean?.cid ?? '';
                            _commentName =
                                commentListDataListBean?.user?.nickname ?? '';
                            _uid = commentListDataListBean?.uid ?? '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Offstage(
          offstage: childrenLength == 0,
          child: Card(
            margin: EdgeInsets.only(
              left: AppDimens.margin_50,
              top: AppDimens.margin_6,
              right: AppDimens.margin_15,
            ),
            color: AppColors.color_f2f2f2,
            elevation: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: List.generate(
                      commentListDataListBean?.children?.length ?? 0,
                      (int index) {
                    return _buildCommentChildrenItem(
                        commentListDataListBean?.uid ?? '',
                        childrenCount,
                        commentListDataListBean?.children[index]?.content ?? '',
                        commentListDataListBean?.cid ?? '',
                        commentListDataListBean
                                ?.children[index]?.user?.nickname ??
                            '',
                        index == (childrenLength - 1));
                  }),
                ),
                Offstage(
                  offstage: childrenCount <= childrenLength,
                  child: InkWell(
                    child: Container(
                      margin: EdgeInsets.only(
                          left: AppDimens.margin_10,
                          top: AppDimens.margin_5,
                          bottom: AppDimens.margin_10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AutoSizeText(
                            InternationalLocalizations.videoClickMoreComment,
                            style: AppStyles.text_style_3674ff_14,
                            minFontSize: 8,
                          ),
                          Container(
                            margin: EdgeInsets.only(left: AppDimens.margin_3),
                            child: Image.asset(
                                'assets/images/ic_right_comment.png'),
                          )
                        ],
                      ),
                    ),
                    onTap: () {
                      if (Common.isAbleClick()) {
                        double statusBarHeight =
                            MediaQuery.of(context).padding.top;
                        double screenHeight =
                            MediaQuery.of(context).size.height;
                        double height = screenHeight -
                            statusBarHeight -
                            AppDimens.item_size_211;
                        CommentChildrenListParameterBean bean =
                            CommentChildrenListParameterBean();
                        bean.width = MediaQuery.of(context).size.width;
                        bean.height = height;
                        bean.vid =
                            commentListDataListBean?.children[0]?.vid ?? '';
                        bean.pid =
                            commentListDataListBean?.children[0]?.pid ?? '';
                        bean.uid = Constant.uid;
                        bean.mapRemoteResError = _mapRemoteResError;
                        bean.vestStatus =
                            _getVideoInfoDataBean?.vestStatus ?? '';
                        bean.cosInfoBean = _cosInfoBean;
                        bean.chainStateBean = _chainStateBean;
                        bean.exchangeRateInfoData = _exchangeRateInfoData;
                        bean.commentListDataListBean = commentListDataListBean;
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) {
                          return VideoCommentChildrenListWindow(bean);
                        }));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Offstage(
          offstage: _isLoadMoreComment,
          child: Container(
            margin: EdgeInsets.only(left: AppDimens.margin_45),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Offstage(
                  offstage: (index != _listComment.length - 1 ||
                      commentTotal <= commentLength),
                  child: InkWell(
                    child: Container(
                      padding: EdgeInsets.all(AppDimens.margin_5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AutoSizeText(
                            InternationalLocalizations.videoClickMoreComment,
                            style: AppStyles.text_style_3674ff_14,
                            minFontSize: 8,
                          ),
                          Container(
                            margin: EdgeInsets.only(left: AppDimens.margin_3),
                            child: Image.asset(
                                'assets/images/ic_right_comment.png'),
                          )
                        ],
                      ),
                    ),
                    onTap: () {
                      if (Common.isAbleClick()) {
                        if (_commentPage == 0) {
                          _commentPage = 1;
                          _httpVideoCommentList(true, true);
                        } else {
                          _httpVideoCommentList(true, false);
                        }
                      }
                    },
                  ),
                ),
                Offstage(
                  offstage:
                      (index != _listComment.length - 1 || _commentPage <= 2),
                  child: InkWell(
                    child: Container(
                      padding: EdgeInsets.all(AppDimens.margin_5),
                      child: AutoSizeText(
                        InternationalLocalizations.videoCommentFold,
                        style: AppStyles.text_style_3674ff_14,
                        minFontSize: 8,
                      ),
                    ),
                    onTap: () {
                      if (Common.isAbleClick()) {
                        setState(() {
                          _listComment.removeRange(5, _listComment.length);
                          _commentPage = 0;
                        });
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
        Offstage(
          offstage: !_isLoadMoreComment || index != _listComment.length - 1,
          child: Align(
            alignment: Alignment.center,
            child: BottomProgressIndicator(),
          ),
        ),
        Offstage(
          offstage: (index != _listComment.length - 1 ||
              commentTotal > commentLength),
          child: NoMoreDataWidget(
            bottomMessage: InternationalLocalizations.videoNoMoreComment,
          ),
        )
      ],
    );
  }

  Widget _buildCommentChildrenItem(String uid, int childrenCount,
      String content, String cid, String commentName, bool isBottom) {
    return InkWell(
      child: Container(
        margin: EdgeInsets.only(
          left: AppDimens.margin_10,
          top: AppDimens.margin_5,
          right: AppDimens.margin_10,
        ),
        child: Html(
          data: '$commentName：$content',
          defaultTextStyle: AppStyles.text_style_333333_14,
          onLinkTap: (url) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) {
              return WebViewPage(
                '${Constant.otherUserCenterWebViewUrl}$uid',
              );
            }));
          },
        ),
      ),
      onTap: () {
        setState(() {
          _commentSendType = CommentSendType.commentSendTypeChildren;
          _commentId = cid;
          _commentName = commentName;
          _uid = uid;
        });
      },
    );
  }

  Widget _buildVideoItem(int index) {
    RelateListItemBean relateListItemBean = _listData[index];
    String totalRevenue;
    if (relateListItemBean != null && _exchangeRateInfoData != null) {
      if (relateListItemBean?.vestStatus ==
          VideoInfoResponse.vestStatusFinish) {
        /// 奖励完成
        double totalRevenueVest =
            RevenueCalculationUtil.getStatusFinishTotalRevenueVest(
                relateListItemBean?.vest ?? '',
                relateListItemBean?.vestGift ?? '');
        totalRevenue = RevenueCalculationUtil.vestToRevenue(
                totalRevenueVest, _exchangeRateInfoData)
            .toStringAsFixed(2);
      } else {
        /// 奖励未完成
        double settlementBonusVest = RevenueCalculationUtil.getVideoRevenueVest(
            relateListItemBean?.votepower, _chainStateBean?.dgpo);
        double giftRevenueVest = RevenueCalculationUtil.getGiftRevenueVest(
            relateListItemBean?.vestGift);
        totalRevenue = RevenueCalculationUtil.vestToRevenue(
                NumUtil.add(settlementBonusVest, giftRevenueVest),
                _exchangeRateInfoData)
            .toStringAsFixed(2);
      }
    }
    Widget _getVideoDurationWidget() {
      if (Common.checkVideoDurationValid(relateListItemBean?.duration)) {
        return VideoTimeWidget(
            Common.formatVideoDuration(relateListItemBean?.duration));
      }
      return Container();
    }

    return InkWell(
      child: Column(
        children: <Widget>[
          Offstage(
            offstage: index != 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: AppDimens.item_line_height_1,
                  color: AppColors.color_e4e4e4,
                ),
                Container(
                  margin: EdgeInsets.only(
                      left: AppDimens.margin_15,
                      top: AppDimens.margin_15,
                      right: AppDimens.margin_15),
                  child: AutoSizeText(
                    InternationalLocalizations.videoRecommendation,
                    style: AppStyles.text_style_333333_bold_16,
                    minFontSize: 8,
                  ),
                )
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(
                left: AppDimens.margin_15,
                top: AppDimens.margin_15,
                right: AppDimens.margin_15),
            child: Row(
              children: <Widget>[
                Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radius_size_2),
                      child: Container(
                        width: AppDimens.item_size_152,
                        height: AppDimens.item_size_85_5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Common.getColorFromHexString("838383", 1),
                              Common.getColorFromHexString("333333", 1),
                            ],
                          ),
                        ),
                        child: CachedNetworkImage(
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: AppColors.color_d6d6d6,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.color_d6d6d6,
                          ),
                          imageUrl: relateListItemBean?.videoCoverBig ?? '',
                        ),
                      ),
                    ),
                    _getVideoDurationWidget()
                  ],
                ),
                Container(
                  height: AppDimens.item_size_85_5 + 3,
                  margin: EdgeInsets.only(left: AppDimens.margin_10),
                  width: AppDimens.item_size_165,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        relateListItemBean?.title ?? '',
                        style: AppStyles.text_style_333333_14,
                        maxLines: 2,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            totalRevenue != null
                                ? '${Common.getCurrencySymbolByLanguage()} ${totalRevenue ?? ''}'
                                : '',
                            style: AppStyles.text_style_333333_bold_15,
                          ),
                          Container(
                            margin: EdgeInsets.only(top: AppDimens.margin_2_5),
                            child: Text(
                              relateListItemBean?.anchorNickname ?? '',
                              style: AppStyles.text_style_333333_bold_15,
                              maxLines: 1,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
      onTap: () {
        if (Common.isAbleClick()) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) {
            return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
                vid: relateListItemBean?.id ?? '',
                uid: widget._videoDetailPageParamsBean.getUid,
                videoSource: relateListItemBean?.videosource ?? ''));
          }));
//          DataReportUtil.instance.reportData(
//            eventName: "Click_video",
//            params: {"Click_video": relateListItemBean?.id ?? ''},
//          );
            VideoReportUtil.reportClickVideo(ClickVideoSource.VideoDetail, relateListItemBean?.id ?? '');
        }
      },
    );
  }

  Widget _buildListItem(int index) {
    if (index == 0) {
      return _buildListHead();
    } else if (index == 1) {
      //评论tab
      return _buildCommentTab();
    } else if (index - 1 <= _listComment.length) {
      index -= 2;
      if (_listComment[index] is CommentListTopBean) {
        return _buildCommentTopItem(_listComment[index], index);
      } else if (_listComment[index] is CommentListDataListBean) {
        return _buildCommentNormalItem(_listComment[index], index);
      }
    } else if (index - 1 <= _listComment.length + _listData.length) {
      index -= (_listComment.length + 2);
      return _buildVideoItem(index);
    }
    return Container();
  }

  Widget _buildCommentTab() {
    return Container(
      margin:
          EdgeInsets.only(top: AppDimens.margin_8, bottom: AppDimens.margin_8),
      child: Container(
        margin: EdgeInsets.only(
          left: AppDimens.margin_15,
          right: AppDimens.margin_15,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            AutoSizeText(
              '${_commentListDataBean?.total ?? '0'}${InternationalLocalizations.videoCommentCount}',
              style: AppStyles.text_style_333333_bold_16,
              minFontSize: 8,
            ),
            _buildTabStyle(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isInitFinish ||
        (!_isInitFinish &&
            Common.checkIsNotEmptyStr(
                widget._videoDetailPageParamsBean.getVideoSource))) {
      body = Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          //播放器
          _buildPlayerWidget(),
          //视频详情、评论、推荐视频列表
          _buildVideoDetailInfoWidget(),
          //输入框
          _buildCommentInputWidget(),
        ],
      );
    } else {
      if (_isNetIng) {
        body = Container();
      } else {
        body = PageRemindWidget(
          clickCallBack: () {
            _loadVideoDetailsInfo();
          },
          remindType: RemindType.NetRequestFail,
        );
      }
    }
    return LoadingView(
      child: Scaffold(
        key: _pageKey,
        body: WillPopScope(
          child: Container(
            color: AppColors.color_ffffff,
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: body,
          ),
          onWillPop: () async {
            VideoSmallWindowsUtil.instance.openVideoSmallWindows(json.encode(_getVideoInfoDataBean.toJson()));
            Navigator.pop(context);
            return;
          },
        ),
      ),
      isShow: _isNetIng,
    );
  }

  ///创建播放器相关widget
  Widget _buildPlayerWidget() {
    return Stack(
      alignment: Alignment.topLeft,
      children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.width * 9.0 / 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromRGBO(84, 84, 84, 1.0), Colors.black],
            ),
          ),
          child: (_chewieController != null && _videoPlayerController != null)
              ? ClipRect(
                  child: Chewie(
                  controller: _chewieController,
                ))
              : Center(
                  child: Theme(
                  data: Theme.of(context).copyWith(accentColor: Colors.white),
                  child: CircularProgressIndicator(),
                )),
        ),
        InkWell(
          child: Container(
            padding: EdgeInsets.only(
              left: AppDimens.margin_10,
              top: AppDimens.margin_16,
              right: AppDimens.margin_10,
              bottom: AppDimens.margin_10,
            ),
            child: Image.asset('assets/images/ic_back_white.png'),
          ),
          onTap: () {
            if (Common.isAbleClick()) {
              VideoSmallWindowsUtil.instance.openVideoSmallWindows(json.encode(_getVideoInfoDataBean.toJson()));
              Navigator.pop(context);
            }
          },
        )
      ],
    );
  }

  ///创建视频详情、评论、推荐列表等相关widget
  Widget _buildVideoDetailInfoWidget() {
    if (_isFirstLoad) {
      return Container();
    }
    return Expanded(
      flex: 1,
      child: Container(
        margin: EdgeInsets.only(top: AppDimens.margin_10),
        child: RefreshAndLoadMoreListView(
          itemBuilder: (context, index) {
            return _buildListItem(index);
          },
          itemCount: _getTotalItemCount(),
          onLoadMore: () {
            _httpVideoRelateList(true);
            return;
          },
          pageSize: videoPageSize,
          isHaveMoreData: _isHaveMoreData,
          isRefreshEnable: false,
          isShowItemLine: false,
          hasTopPadding: false,
        ),
      ),
    );
  }

  ///创建评论回复的输入框相关widget
  Widget _buildCommentInputWidget() {
    if (_getVideoInfoDataBean == null &&
        (_listComment == null || _listComment.isEmpty)) {
      return Container();
    }
    return Container(
      margin: EdgeInsets.only(
          left: AppDimens.margin_15,
          top: AppDimens.margin_6_5,
          right: AppDimens.margin_15,
          bottom: AppDimens.margin_6_5),
      height: AppDimens.item_size_45,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: AppDimens.margin_5),
              height: AppDimens.item_size_32,
              child: TextField(
                onChanged: (str) {
                  if (str != null && str.trim().isNotEmpty) {
                    if (!_isAbleSendMsg) {
                      setState(() {
                        _isAbleSendMsg = true;
                      });
                    }
                  } else {
                    if (_isAbleSendMsg) {
                      setState(() {
                        _isAbleSendMsg = false;
                      });
                    }
                  }
                },
                controller: _textController,
                style: AppStyles.text_style_333333_12,
                decoration: InputDecoration(
                  fillColor: AppColors.color_ebebeb,
                  filled: true,
                  hintStyle: AppStyles.text_style_a0a0a0_12,
                  hintText: _commentSendType ==
                          CommentSendType.commentSendTypeNormal
                      ? InternationalLocalizations.videoInputMsgHint
                      : '${InternationalLocalizations.videoCommentReply} @$_commentName：',
                  contentPadding: EdgeInsets.only(
                      left: AppDimens.margin_10, top: AppDimens.margin_12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.color_transparent),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radius_size_21),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.color_3674ff),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radius_size_21),
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              if (Common.isAbleClick()) {
                String id;
                if (_commentSendType == CommentSendType.commentSendTypeNormal) {
                  id = _getVideoInfoDataBean?.id ?? '';
                } else {
                  id = _commentId ?? '';
                }
                _checkAbleVideoComment(id);
              }
            },
            child: Container(
              padding: EdgeInsets.all(AppDimens.margin_5),
              child: AutoSizeText(
                InternationalLocalizations.videoCommentSendMessage,
                style: _isAbleSendMsg
                    ? AppStyles.text_style_3674ff_14
                    : AppStyles.text_style_a0a0a0_14,
                minFontSize: 8,
              ),
            ),
          )
        ],
      ),
    );
  }

  int _getTotalItemCount() {
    int count = 1;
    if (_listComment != null && _listComment.isNotEmpty) {
      count += _listComment.length;
    }
    //评论tab
    count += 1;
    if (_listData != null && _listData.isNotEmpty) {
      count += _listData.length;
    }
    return count;
  }

  GlobalObjectKey<VideoAddMoneyWidgetState> _getAddMoneyViewKeyFromSymbol(
      String symbol) {
    if (!Common.checkIsNotEmptyStr(symbol)) {
      return GlobalObjectKey<VideoAddMoneyWidgetState>("default");
    }
    return GlobalObjectKey<VideoAddMoneyWidgetState>(symbol);
  }

  Decimal _getUserMaxPower() {
    return Common.getUserMaxPower(_cosInfoBean);
  }

  void _addVoterPowerToVideo() {
    if (_getVideoInfoDataBean != null &&
        _getVideoInfoDataBean?.vestStatus !=
            VideoInfoResponse.vestStatusFinish &&
        _getVideoInfoDataBean != null) {
      Decimal val = Decimal.parse(_getVideoInfoDataBean.votepower);
      val += _getUserMaxPower();
      print("origin voter power is ${_getVideoInfoDataBean.votepower}");
      _getVideoInfoDataBean.votepower = val.toStringAsFixed(0);
      print("new voter power is ${_getVideoInfoDataBean.votepower}");
      initTotalRevenue();
    }
  }

  void _addVoterPowerToTopComment(CommentListTopBean bean) {
    if (bean != null) {
      Decimal val = Decimal.parse(bean.votepower);
      val += _getUserMaxPower();
      bean.votepower = val.toStringAsFixed(0);
    }
  }

  void _addVoterPowerToNormalComment(CommentListDataListBean bean) {
    if (bean != null) {
      Decimal val = Decimal.parse(bean.votepower);
      val += _getUserMaxPower();
      bean.votepower = val.toStringAsFixed(0);
    }
  }
}
