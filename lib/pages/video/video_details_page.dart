import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:common_utils/common_utils.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/bean/account_get_info_bean.dart';
import 'package:costv_android/bean/bank_property_bean.dart';
import 'package:costv_android/bean/comment_list_bean.dart';
import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/bean/cos_video_details_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/exclusive_relation_bean.dart';
import 'package:costv_android/bean/get_ticket_info_bean.dart';
import 'package:costv_android/bean/get_video_info_bean.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/bean/integral_user_info_bean.dart';
import 'package:costv_android/bean/integral_video_integral_bean.dart';
import 'package:costv_android/bean/relate_list_bean.dart';
import 'package:costv_android/bean/simple_bean.dart';
import 'package:costv_android/bean/simple_proxy_bean.dart';
import 'package:costv_android/bean/user_setting_bean.dart';
import 'package:costv_android/bean/video_comment_bean.dart';
import 'package:costv_android/bean/video_gift_info_bean.dart';
import 'package:costv_android/bean/video_report_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/emoji/emoji_picker.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/video_comment_children_list_event.dart';
import 'package:costv_android/event/video_detail_data_change_event.dart';
import 'package:costv_android/event/watch_video_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/overlay/bean/video_small_windows_bean.dart';
import 'package:costv_android/overlay/overlay_video_small_windows_utils.dart';
import 'package:costv_android/overlay/view/video_small_windows.dart';
import 'package:costv_android/pages/comment/bean/comment_list_item_parameter_bean.dart';
import 'package:costv_android/pages/comment/bean/open_comment_children_parameter_bean.dart';
import 'package:costv_android/pages/comment/widget/comment_list_item.dart';
import 'package:costv_android/pages/comment/widget/video_comment_children_list_widget.dart';
import 'package:costv_android/pages/user/others_home_page.dart';
import 'package:costv_android/pages/video/bean/video_detail_all_data_bean.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/bean/video_settlement_bean.dart';
import 'package:costv_android/pages/video/player/costv_controls.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/popupwindow/popup_window.dart';
import 'package:costv_android/popupwindow/popup_window_route.dart';
import 'package:costv_android/popupwindow/view/video_settlement_window.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/platform_util.dart';
import 'package:costv_android/utils/revenue_calculation_util.dart';
import 'package:costv_android/utils/time_format_util.dart';
import 'package:costv_android/utils/time_util.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:costv_android/utils/user_util.dart';
import 'package:costv_android/utils/video_detail_data_manager.dart';
import 'package:costv_android/utils/video_notification_util.dart';
import 'package:costv_android/utils/video_report_util.dart';
import 'package:costv_android/utils/web_view_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/animation/animation_rotate_widget.dart';
import 'package:costv_android/widget/animation/video_add_money_widget.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:costv_android/widget/video_auto_play_setting_widget.dart';
import 'package:costv_android/widget/video_time_widget.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'dialog/energy_not_enough_dialog.dart';
import 'dialog/video_comment_delete_dialog.dart';
import 'dialog/video_report_dialog.dart';
import 'player/costv_fullscreen.dart';

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
    with SingleTickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  static const String tag = '_VideoDetailsPageState';
  VideoDetailPageParamsBean _videoDetailPageParamsBean;
  final GlobalKey<ScaffoldState> _dialogSKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _pageKey = GlobalKey<ScaffoldState>();
  final GlobalObjectKey<VideoAutoPlaySettingWidgetState> _autoPlaySwitchKey =
      GlobalObjectKey<VideoAutoPlaySettingWidgetState>(
          "autoPlaySwitchKey" + DateTime.now().toString());

  static const int videoPageSize = 20;
  static const int commentPageSize = 10;
  static const String orderByHot = 'like_count';
  static const String orderByTime = 'created_at';
  static const int timeInterval = 1000;
  static const int timeTotalTime = 60 * 1000;
  static const int commentMaxLength = 300;

  static const int popRewardHot = 20;
  static const int popRewardNormal = 10;
  int settlementTime = Constant.isDebug ? 60 * 5 : 60 * 60 * 24 * 7;
  static const double _triggerY = AppDimens.item_size_100;

  AnimationController _animationController;
  List<RelateListItemBean> _listData = [];
  bool _isHaveMoreData = false;
  CommentType _commentTypeCurrent = CommentType.commentTypeHot;
  TextEditingController _textController;

  FocusNode _focusNode = FocusNode();
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
  List<CommentListItemBean> _listComment = [];
  List<RelateListItemBean> _listRelate;
  int _linkCount = 0;
  Map<String, dynamic> _mapRemoteResError;
  Map<String, dynamic> _mapVideoIntegralError;
  bool _isAbleSendMsg = false;
  bool _isShowCommentLength = false;
  int _superfluousLength;
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
  int _sendCommentIndex;
  String _uid;
  bool _isFirstLoad = true;
  Map<int, double> _visibleFractionMap = {};
  bool _isScrolling = false;
  DateTime _videoLoadStartTime;
  bool _hasReportedVideoPlay = false;
  bool _isVideoReportLoading = false, _isVideoReportSuccess = false;
  String _refreshingVid = '';
  String _pageFlag = DateTime.now().toString();
  int _forwardVideoCount = 0; //前向播放过的视频数量(如首页->A->B,那么B的前向播放过的视频数量为1)
  VideoCommentDeleteDialog _videoCommentDeleteDialog;
  GetTicketInfoDataBean _getTicketInfoDataBean;
  bool _isBuffering;
  int _bufferStartTime = -1;
  OpenCommentChildrenParameterBean _openCommentChildrenParameterBean;
  int _clickCommentIndex = 0;

//  bool _isShowCommentHint = true;
//  bool _isShowCommentHintIng = false;
  double _scrollPixels = 0.0;
  double _startY;
  bool _isShowSmallWindow = false;
  bool _isVideoChangedInit = false;
  bool _isCanReportVideoEnd = false;
  bool _isInputFace = false;
  ExclusiveRelationItemBean _exclusiveRelationItemBean;
  Category _selectCategory;
  bool _isInputFaceChildren = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoDetailPageParamsBean = widget._videoDetailPageParamsBean;
    _pageFlag =
        '${_videoDetailPageParamsBean?.getVid ?? ""}${DateTime.now().toString()}';
    VideoDetailDataMgr.instance.addPageCachedDataByKey(_pageFlag);
    VideoDetailDataMgr.instance.updateCurrentVideoParamsBeanByKey(
        _pageFlag, _videoDetailPageParamsBean);
    OverlayVideoSmallWindowsUtils.instance.removeVideoSmallWindow();
    Constant.backAnimationType = SlideAnimationRoute.animationTypeHorizontal;
//    _focusNode.addListener(() {
//      if (_focusNode.hasFocus) {
//        if (_isShowCommentHintIng) {
//          setState(() {
//            _isShowCommentHintIng = false;
//          });
//        }
//      }
//    });
    _initPageData();
  }

  void _initPageData() {
    _animationController = AnimationController(
      vsync: this,
    );
    _textController = TextEditingController();
    _mapRemoteResError =
        InternationalLocalizations.mapNetValue['remoteResError'];
    _mapVideoIntegralError =
        InternationalLocalizations.mapNetValue['videoIntegralError'];
    _initTimeUtil();
    if (widget._videoDetailPageParamsBean.getFromType ==
        VideoDetailPageParamsBean.fromTypeVideoSmallWindows) {
      _getVideoInfoDataBean = widget._videoDetailPageParamsBean
          .getVideoSmallWindowsBean?.getVideoInfoDataBean;
      _linkCount =
          widget._videoDetailPageParamsBean.getVideoSmallWindowsBean?.linkCount;
      _popReward =
          widget._videoDetailPageParamsBean.getVideoSmallWindowsBean?.popReward;
      _videoGiftInfoDataBean = widget._videoDetailPageParamsBean
          .getVideoSmallWindowsBean?.videoGiftInfoDataBean;
      _integralUserInfoDataBean = widget._videoDetailPageParamsBean
          .getVideoSmallWindowsBean?.integralUserInfoDataBean;
      _bankPropertyDataBean = widget._videoDetailPageParamsBean
          .getVideoSmallWindowsBean?.bankPropertyDataBean;
      _exchangeRateInfoData = widget._videoDetailPageParamsBean
          .getVideoSmallWindowsBean?.exchangeRateInfoData;
      _isVideoLike = widget
          ._videoDetailPageParamsBean.getVideoSmallWindowsBean?.isVideoLike;
      _isFollow =
          widget._videoDetailPageParamsBean.getVideoSmallWindowsBean?.isFollow;
      _listRelate = widget
          ._videoDetailPageParamsBean.getVideoSmallWindowsBean?.listRelate;
      _listData =
          widget._videoDetailPageParamsBean.getVideoSmallWindowsBean?.listData;
      _videoPage =
          widget._videoDetailPageParamsBean.getVideoSmallWindowsBean?.videoPage;
      _isHaveMoreData = widget
          ._videoDetailPageParamsBean.getVideoSmallWindowsBean?.isHaveMoreData;
      _commentListDataBean = widget._videoDetailPageParamsBean
          .getVideoSmallWindowsBean?.commentListDataBean;
      _listComment = widget
          ._videoDetailPageParamsBean.getVideoSmallWindowsBean?.listComment;
      _commentPage = widget
          ._videoDetailPageParamsBean.getVideoSmallWindowsBean?.commentPage;
      _exclusiveRelationItemBean = widget._videoDetailPageParamsBean
          .getVideoSmallWindowsBean?.exclusiveRelationItemBean;
      initSettlementTime();
      _reportPageAllDataLoadSuccess();
      _updatePlayerControlInfo();
      _isInitFinish = true;
      _isFirstLoad = false;
    } else {
      _loadVideoDetailsInfo();
      if (Common.judgeHasLogIn()) {
        _initLoadUserSettingInfo(); //获取用户是否打开自动播放等配置信息
        _httpAddWatchHistory();
      }
    }
    _chainInfoInit();
    _cosAccountInfoInit();
    if (Common.checkIsNotEmptyStr(_videoDetailPageParamsBean.getVideoSource)) {
      Duration startAt;
      if (widget._videoDetailPageParamsBean.getFromType ==
          VideoDetailPageParamsBean.fromTypeVideoSmallWindows) {
        startAt =
            widget._videoDetailPageParamsBean.getVideoSmallWindowsBean?.startAt;
      }
      _initVideoPlayers(
          _videoDetailPageParamsBean.getVideoSource, false, startAt);
    }
    _loadFollowingRecommendVideo(
        _videoDetailPageParamsBean?.getUid, _videoDetailPageParamsBean?.getVid);
  }

  void _initTimeUtil() {
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive: // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
        break;
      case AppLifecycleState.resumed: // 应用程序可见，前台
        VideoNotificationUtil.instance.closeVideoNotification();
        break;
      case AppLifecycleState.paused: // 应用程序不可见，后台
        bool isPlay = _videoPlayerController?.value?.isPlaying ?? false;
        if (_getVideoInfoDataBean != null && isPlay) {
          VideoNotificationUtil.instance.openVideoNotification(
              json.encode(_getVideoInfoDataBean.toJson()));
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RequestManager.instance.cancelAllNetworkRequest(tag);
    VideoDetailDataMgr.instance.clearCachedDataByKey(_pageFlag);
    routeObserver.unsubscribe(this);
    if (_chewieController != null) {
      _chewieController.dispose();
      _chewieController = null;
    }
    if (!_isShowSmallWindow) {
      clearVideoPlayerController();
    }
    if (_animationController != null) {
      _animationController.dispose();
      _animationController = null;
    }
    if (_focusNode != null) {
      _focusNode.dispose();
      _focusNode = null;
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

  void clearVideoPlayerController() {
    if (_videoPlayerController != null) {
      _videoPlayerController.pause();
      _videoPlayerController.dispose();
      _videoPlayerController = null;
    }
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
    List<Future<Response>> listFuture = [
      RequestManager.instance.getVideoDetailsInfo(
        tag,
        _videoDetailPageParamsBean?.getVid ?? '',
        Common.getCurrencyMoneyByLanguage(),
        uid: Constant.uid ?? '',
        fuid: _videoDetailPageParamsBean?.getUid ?? '',
      ),
      RequestManager.instance.videoRelateList(
          tag, _videoDetailPageParamsBean?.getVid ?? '',
          page: _videoPage.toString(), pageSize: videoPageSize.toString()),
      RequestManager.instance.videoCommentListNew(
          tag,
          _videoDetailPageParamsBean?.getVid ?? '',
          _commentPage,
          commentPageSize,
          uid: Constant.uid ?? '',
          orderBy: VideoCommentListResponse.orderByHot),
    ];
    if (!ObjectUtil.isEmpty(Constant.uid)) {
      listFuture.add(RequestManager.instance.exclusiveRelation(
          tag, Constant.uid ?? ''));
    }
    Future.wait(listFuture).then((listResponse) {
      if (listResponse == null || !mounted) {
        return;
      }
      bool isHaveBasicData = true,
          isRelateListSuc = true,
          isCommentListSuc = true;
      //视频详情相关数据
      if (listResponse.length >= 1) {
        isHaveBasicData = _processVideoDetailsInfo(listResponse[0]);
      }
      //视频推荐列表
      if (listResponse.length >= 2) {
        isRelateListSuc = _processVideoRelateList(listResponse[1], false);
      }
      //评论列表
      if (listResponse.length >= 3) {
        isCommentListSuc =
            _processVideoCommentList(listResponse[2], false, false);
      }
      //查看是否解锁创作者表情
      if (listResponse.length >= 4) {
        _processExclusiveRelation(listResponse[3]);
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
      //视频数据、推荐、评论数据都拉取成功，则表示页面所有数据都能加载完成,上报所有内容都加载完成
      if (mounted) {
        if (isHaveBasicData && isRelateListSuc && isCommentListSuc) {
          _reportPageAllDataLoadSuccess();
        }
      }
    }).catchError((err) {
      CosLogUtil.log("$tag: load video info exception, the error is $err");
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      _isFirstLoad = false;
      if (_videoPlayerController == null &&
          !Common.checkIsNotEmptyStr(
              _videoDetailPageParamsBean?.getVideoSource)) {
        bool isFullScreen = false;
        if (_chewieController != null && _chewieController.isFullScreen) {
          isFullScreen = true;
        }
        _initVideoPlayers(
                _getVideoInfoDataBean?.videosource ?? '', isFullScreen, null)
            .then((_) {
          setState(() {});
        });
      }
      _updatePlayerControlInfo();
      setState(() {
        _isNetIng = false;
      });
      if (_judgeIsNeedLoadNextPageData(
          _videoDetailPageParamsBean?.getVid ?? '')) {
        _httpVideoRelateList(true);
      }
    });
  }

  bool _processVideoDetailsInfo(Response response) {
    if (response == null) {
      return false;
    }
    CosVideoDetailsBean bean =
        CosVideoDetailsBean.fromJson(json.decode(response.data));
    return _processVideoDetailsInfoByData(bean);
  }

  bool _processVideoDetailsInfoByData(CosVideoDetailsBean bean) {
    if (bean == null) {
      return false;
    }
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
            VideoDetailDataMgr.instance
                .updateFollowStatusByKey(_pageFlag, true);
          } else {
            _isFollow = false;
            VideoDetailDataMgr.instance
                .updateFollowStatusByKey(_pageFlag, false);
          }
        }
        return true;
      } else {
        CosLogUtil.log("VideoDetailPage: fetch empty video details info, "
            "vid is ${_videoDetailPageParamsBean?.getVid ?? ''}, "
            "uid is ${Constant.uid ?? ''}");
        return false;
      }
    } else {
      CosLogUtil.log("VideoDetailPage: fail to fetch video details info, "
          "the error code is ${bean.status}, msg is ${bean.msg}, "
          "vid is ${_videoDetailPageParamsBean?.getVid ?? ''}, "
          "uid is ${Constant.uid ?? ''}");
      return false;
    }
  }

  void _reportPageAllDataLoadSuccess() {
    String isFromVideoPage = "0";
    if (_videoDetailPageParamsBean.getEnterSource != null &&
            _videoDetailPageParamsBean.getEnterSource ==
                VideoDetailsEnterSource.VideoDetailsEnterSourceVideoDetail ||
        _videoDetailPageParamsBean.getEnterSource ==
            VideoDetailsEnterSource.VideoDetailsEnterSourceEndRecommend ||
        _videoDetailPageParamsBean.getEnterSource ==
            VideoDetailsEnterSource.VideoDetailsEnterSourceVideoRecommend ||
        _videoDetailPageParamsBean.getEnterSource ==
            VideoDetailsEnterSource.VideoDetailsEnterSourceAutoPlay ||
        _videoDetailPageParamsBean.getEnterSource ==
            VideoDetailsEnterSource.VideoDetailsEnterSourceVideoSmallWindows) {
      isFromVideoPage = "1";
    }
    DataReportUtil.instance.reportData(
      eventName: "VideoPage_display",
      params: {
        "vid": _getVideoId() ?? "",
        "uid": _getUidOfVideo(),
        "is_from_video": isFromVideoPage,
        "referrer": _getEnterSourcePageName(),
        "layer": _forwardVideoCount,
      },
    );
  }

  Future<void> _initLoadUserSettingInfo() async {
    if (!Common.judgeHasLogIn()) {
      return;
    }
    bool originVal = usrAutoPlaySetting;
    SettingData data = await _loadUserSettingInfo(true);
    bool isNeedRefresh = false;
    if (data != null && data.profilesList != null) {
      isNeedRefresh = originVal == usrAutoPlaySetting;
    } else {
      bool isEqual = await _getAutoPlaySettingFromLocal();
      if (!isEqual) {
        isNeedRefresh = true;
      }
    }
    if (isNeedRefresh &&
        _isInitFinish &&
        _listData != null &&
        _listData.isNotEmpty) {
      setState(() {});
    }
  }

  Future<SettingData> _loadUserSettingInfo(bool isSaveToLocal) async {
    SettingData data;
    if (!Common.judgeHasLogIn()) {
      //没登录就没必要去请求接口
      return null;
    }
    await RequestManager.instance
        .getUserSetting(
      Constant.uid ?? '',
      tag: tag,
    )
        .then((response) {
      if (response != null) {
        UserSettingBean bean =
            UserSettingBean.fromJson(json.decode(response.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          data = bean.data;
          if (isSaveToLocal) {
            _processUserSetting(data);
          }
        } else {
          CosLogUtil.log("$tag: fail to get user setting of "
              "${Constant.uid ?? ''}, the error is ${bean.status ?? ''}:${bean.msg ?? ''}");
          data = null;
        }
      } else {
        CosLogUtil.log("$tag: fail to get user setting of "
            "${Constant.uid ?? ''}, the response is null");
        data = null;
      }
    }).catchError((err) {
      CosLogUtil.log(
          "$tag: load user setting of ${Constant.uid ?? ''} exception, the error is $err");
      data = null;
    }).whenComplete(() {});
    return data;
  }

  bool _processUserSetting(SettingData data) {
    if (data == null) {
      return usrAutoPlaySetting;
    }
    if (data.profilesList != null && data.profilesList.isNotEmpty) {
      data.profilesList.forEach((profilesData) {
        if (profilesData.type ==
            UserSettingType.AutoPlaySetting.index.toString()) {
          bool isOpen = false;
          if ((profilesData.set == "1")) {
            isOpen = true;
          }
          if (usrAutoPlaySetting != isOpen) {
            usrAutoPlaySetting = isOpen;
            UserUtil.updateUserAutoPlaySetting(Constant.uid, isOpen);
          }
        }
      });
    }
    return usrAutoPlaySetting;
  }

  Future<bool> _updateAutoPlaySetting(bool isOpen) async {
    bool result = true;
    if (!Common.judgeHasLogIn()) {
      return false;
    }
    await RequestManager.instance
        .updateUserSetting(
      Constant.uid,
      UserSettingType.AutoPlaySetting.index,
      isOpen ? 1 : 0,
      tag: tag,
    )
        .then((response) {
      if (response == null) {
        result = false;
      } else {
        SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          result = true;
        } else {
          result = false;
          CosLogUtil.log(
              "$tag: update user:${Constant.uid ?? ""} fail, the error is ${bean.status ?? ""}: ${bean.msg ?? ""}");
        }
      }
    }).catchError((err) {
      result = false;
      CosLogUtil.log(
          "$tag: update user:${Constant.uid ?? ""} exception, the error is $err");
    });
    return result;
  }

  ///添加观看历史
  void _httpAddWatchHistory() {
    RequestManager.instance
        .addHistory(
            tag, Constant.uid ?? '', _videoDetailPageParamsBean?.getVid ?? '')
        .then((response) {
      if (response != null) {
        SimpleBean bean = SimpleBean.fromJson(json.decode(response?.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          EventBusHelp.getInstance()
              .fire(WatchVideoEvent(_videoDetailPageParamsBean.getVid ?? ""));
        }
      }
    });
  }

  void _loadFollowingRecommendVideo(String uid, String vid) {
    RequestManager.instance
        .getFollowingNewRecommendVideo(Constant.uid, uid ?? '', vid ?? '',
            tag: tag)
        .then((response) {
      String curUid = _videoDetailPageParamsBean?.getUid ?? '';
      String curVid = _videoDetailPageParamsBean?.getVid ?? '';
      if (response != null) {
        if (mounted) {
          if (curUid == uid && vid == curVid) {
            GetVideoListNewBean bean =
                GetVideoListNewBean.fromJson(json.decode(response.data));
            if (bean.status == SimpleResponse.statusStrSuccess &&
                bean.data != null &&
                bean.data.list != null) {
              VideoDetailDataMgr.instance.updateFollowingRecommendVideoByKey(
                  _pageFlag, bean.data.list);
              EventBusHelp.getInstance().fire(
                  FetchFollowingRecommendVideoFinishEvent(_pageFlag, true));
            }
          }
        }
      } else {
        CosLogUtil.log("loadFollowingRecommendVideo: response is empty");
        if (curUid == uid && vid == curVid) {
          EventBusHelp.getInstance()
              .fire(FetchFollowingRecommendVideoFinishEvent(_pageFlag, false));
        }
      }
    }).catchError((err) {
      CosLogUtil.log("loadFollowingRecommendVideo: fail to load following "
          "uid:${_videoDetailPageParamsBean?.getUid ?? ""}'s recommend "
          "video list, the error is $err");
      String curUid = _videoDetailPageParamsBean?.getUid ?? '';
      String curVid = _videoDetailPageParamsBean?.getVid ?? '';
      if (curUid == uid && vid == curVid) {
        EventBusHelp.getInstance()
            .fire(FetchFollowingRecommendVideoFinishEvent(_pageFlag, false));
      }
    }).whenComplete(() {});
  }

  ///视频观看次数上报接口
  void _httpVideoReport(String vid) {
    if (_isVideoReportLoading) {
      return;
    }
    _isVideoReportLoading = true;
    RequestManager.instance.videoReport(tag, vid).then((response) {
      if (response != null && !ObjectUtil.isEmptyString(response.data)) {
        VideoReportBean bean =
            VideoReportBean.fromJson(json.decode(response.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          _isVideoReportSuccess = true;
        }
      }
    }).whenComplete(() {
      _isVideoReportLoading = false;
    });
  }

  ///获取用户打赏视频详情
  void _httpGetTicketInfo(
      String vid, String uid, String replyId, String content) {
    RequestManager.instance.getTicketInfo(tag, vid, uid).then((response) {
      if (response != null && !ObjectUtil.isEmptyString(response.data)) {
        GetTicketInfoBean bean =
            GetTicketInfoBean.fromJson(json.decode(response.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          _getTicketInfoDataBean = bean.data;
          if (Constant.accountGetInfoDataBean == null) {
            _httpUserInfo(replyId, content);
          } else {
            refreshCommentTop(replyId, content);
            setState(() {
              _isNetIng = false;
            });
          }
        }
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

  Future<void> _initAuthorFollowStatus(String authorUid) async {
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
        .videoIsLike(
            tag, Constant.uid ?? '', _videoDetailPageParamsBean?.getVid ?? '')
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
      if (TextUtil.isEmpty(_videoDetailPageParamsBean.getUid)) {
        _videoDetailPageParamsBean.setUid = _getVideoInfoDataBean.uid ?? '';
      }
      return true;
    } else {
      _linkCount = 0;
    }
    return false;
  }

  Future<void> _initVideoPlayers(
      String videoUrl, bool isFullScreen, Duration startAt) async {
    _isVideoReportSuccess = false;
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    _hasReportedVideoPlay = false;
    _videoLoadStartTime = DateTime.now();
    _isBuffering = null;
    if (startAt == null) {
      startAt = Duration();
    }
    await _videoPlayerController.initialize().then((_) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          autoPlay: true,
          startAt: startAt,
          looping: false,
          showControlsOnInitialize: false,
          allowMuting: false,
          isLive: _videoPlayerController.value.duration == Duration.zero,
          customControls: CosTVControls(
            _pageFlag,
            playNextVideoCallBack: () {
              if (_listData != null && _listData.isNotEmpty) {
                VideoPlayerValue playerValue = _videoPlayerController?.value;
                if (playerValue != null) {
                  reportVideoEnd(playerValue);
                }
                _handlePlayNextVideo(_listData[0],
                    VideoDetailsEnterSource.VideoDetailsEnterSourceAutoPlay);
              }
            },
            videoPlayEndCallBack: () {
              _handleCurVideoPlayEnd();
            },
            clickRecommendVideoCallBack: (RelateListItemBean info) {
              if (info != null) {
                _handlePlayNextVideo(
                    info,
                    VideoDetailsEnterSource
                        .VideoDetailsEnterSourceEndRecommend);
              } else {
                CosLogUtil.log("Play Recommend: the video info is empty");
              }
            },
            refreshRecommendVideoCallBack: () {
              _refreshRecommendVideoInfo(_videoDetailPageParamsBean?.getVid);
            },
            handelFollowCallBack: () {
              _checkAbleAccountFollow();
            },
            fetchFollowingRecommendVideoCallBack: () {
              _loadFollowingRecommendVideo(_videoDetailPageParamsBean?.getUid,
                  _videoDetailPageParamsBean?.getVid);
            },
            playCreatorRecommendVideoCallBack:
                (GetVideoListNewDataListBean videoInfo) {
              if (videoInfo != null) {
                VideoDetailDataMgr.instance
                    .updateCachedNextVideoInfoByKey(_pageFlag, null);
                RelateListItemBean relateListItem =
                    RelateListItemBean.fromJson(videoInfo.toJson());
                _handlePlayNextVideo(
                    relateListItem,
                    VideoDetailsEnterSource
                        .VideoDetailsEnterSourceEndRecommend);
              }
            },
            playPreVideoCallBack: () {
              _handlePlayPreVideo();
            },
            clickZoomOutCallBack: () {
              if (Common.isAbleClick()) {
                if (_getVideoInfoDataBean != null) {
                  showVideoSmallWindows(context);
                }
                Navigator.pop(context);
              }
            },
          ),
          materialProgressColors: CosTVControlColor.MaterialProgressColors,
          routePageBuilder: CosTvFullScreenBuilder.of(
              _videoPlayerController.value.aspectRatio),
          deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
          isInitFullScreen: isFullScreen,
        );
        _isVideoChangedInit = true;
        _videoPlayerController.addListener(videoPlayerChanged);
      });
    });
  }

  void videoPlayerChanged() {
    VideoPlayerValue playerValue = _videoPlayerController?.value;
    if (playerValue == null) {
      return;
    }

    if (_isBuffering == null || playerValue.isBuffering != _isBuffering) {
      _isBuffering = playerValue.isBuffering;
      String vid = _getVideoId();
      String videoUrl = _videoDetailPageParamsBean?.getVideoSource ?? "";
      if (Common.checkIsNotEmptyStr(videoUrl)) {
        videoUrl = _getVideoInfoDataBean?.videosource ?? "";
      }
      if (_isBuffering) {
        _bufferStartTime = DateTime.now().millisecondsSinceEpoch;
        DataReportUtil.instance.reportData(
            eventName: "Play_buffer_start",
            params: {"vid": vid, "videourl": videoUrl});
      } else {
        int curTime = DateTime.now().millisecondsSinceEpoch;
        if (_bufferStartTime != null && _bufferStartTime != -1) {
          int bufferTime = curTime - _bufferStartTime;
          DataReportUtil.instance.reportData(
              eventName: "Play_buffer_end",
              params: {
                "vid": vid,
                "videourl": videoUrl,
                "buffertime": bufferTime
              });
        }
        _bufferStartTime = -1;
      }
    }

    // 对接看视频得POP倒计时
    if (playerValue.isPlaying) {
      if (_timerUtil != null && !_timerUtil.isActive()) {
        _timerUtil.startCountDown();
        String vid = _videoDetailPageParamsBean?.getVid ?? '';
        if (ObjectUtil.isEmptyString(vid)) {
          vid = _getVideoInfoDataBean?.id ?? '';
        }
        if (!_isVideoReportLoading &&
            !_isVideoReportSuccess &&
            !ObjectUtil.isEmptyString(vid)) {
          _httpVideoReport(vid);
        }
      }
    } else {
      if (_timerUtil != null && _timerUtil.isActive()) {
        _timerUtil.cancel();
      }
    }

    // 观看时长埋点
    if (playerValue.isPlaying) {
      if (!_isCanReportVideoEnd) {
        _isCanReportVideoEnd = true;
      }
      if (_currentPlayerPosition != playerValue.position) {
        _lastPlayerPosition = _currentPlayerPosition;
        _currentPlayerPosition = playerValue.position;

        if (_currentPlayerPosition.inSeconds >= 1 &&
            _lastPlayerPosition.inSeconds < 1) {
          if (widget._videoDetailPageParamsBean.isVideoSmallInit) {
            widget._videoDetailPageParamsBean.setIsVideoSmallInit = false;
          } else {
            DataReportUtil.instance.reportData(
              eventName: "Video_play",
              params: {
                "vid": _getVideoId(),
                "topic_class": _getVideoInfoDataBean?.topicClass ?? "",
                "type": _getVideoInfoDataBean?.type ?? "",
              },
            );
          }
        }

        if (playerValue.duration > Duration.zero) {
          Duration threshold = playerValue.duration * 0.9;
          if (_currentPlayerPosition >= threshold &&
              _lastPlayerPosition < threshold) {
            DataReportUtil.instance.reportData(
              eventName: "Video_done",
              params: {
                "vid": _getVideoId(),
                "watchtime": _currentPlayerPosition.inSeconds,
              },
            );
          }
//          Duration half = playerValue.duration * 0.5;
//          if (_currentPlayerPosition >= half &&
//              _isShowCommentHint &&
//              !_isShowCommentHintIng &&
//              mounted) {
//            setState(() {
//              _isShowCommentHintIng = true;
//              _isShowCommentHint = false;
//            });
//          }
        }
        if (_currentPlayerPosition.inSeconds ==
                playerValue.duration.inSeconds &&
            _isCanReportVideoEnd) {
          _isCanReportVideoEnd = false;
          reportVideoEnd(playerValue);
        }
      }
      reportVideoStartedPlaying();
    } else {
      if (_isVideoChangedInit) {
        _isVideoChangedInit = false;
      } else {
        if (!_isShowSmallWindow && _isCanReportVideoEnd) {
          _isCanReportVideoEnd = false;
          reportVideoEnd(playerValue);
        }
      }
    }
  }

  /// 视频开始播放时上报
  void reportVideoStartedPlaying() {
    if (!_hasReportedVideoPlay) {
      _hasReportedVideoPlay = true;
      String videoSource = _videoDetailPageParamsBean.getVideoSource ?? '';
      if (!Common.checkIsNotEmptyStr(videoSource)) {
        if (Common.checkIsNotEmptyStr(_getVideoInfoDataBean?.videosource)) {
          videoSource = _getVideoInfoDataBean?.videosource;
        }
      }
      DataReportUtil.instance.reportData(
        eventName: "Video_Start",
        params: {
          "vid": _getVideoId(),
          "uid": _getUidOfVideo(),
        },
      );

      if (_videoLoadStartTime != null) {
        DataReportUtil.instance.reportData(
          eventName: "Video_loading",
          params: {
            "vid": _getVideoId(),
            "uid": Constant.uid ?? "0",
            "loadingms": DateTime.now().millisecondsSinceEpoch -
                _videoLoadStartTime.millisecondsSinceEpoch,
            "videourl": videoSource
          },
        );
      }
    }
  }

  ///视频停止、切换、播放完成、退到后台时的上报
  void reportVideoEnd(VideoPlayerValue playerValue) {
    num playTimeProportion = NumUtil.getNumByValueDouble(
        NumUtil.multiply(
            NumUtil.divide(_currentPlayerPosition.inSeconds,
                playerValue.duration.inSeconds),
            100),
        2);
    DataReportUtil.instance.reportData(
      eventName: "Play_time_proportion",
      params: {
        "play_time_proportion": '$playTimeProportion%',
        "vid": _getVideoId(),
        "uid": _getUidOfVideo(),
      },
    );
    DataReportUtil.instance.reportData(
      eventName: "Play_time",
      params: {
        "play_time_proportion": '${_currentPlayerPosition.inSeconds}',
        "vid": _getVideoId(),
        "uid": _getUidOfVideo(),
      },
    );
    String eventName;
    if (playTimeProportion < 30) {
      eventName = "Play_time_proportion_lessthan30";
    } else if (playTimeProportion >= 30 && playTimeProportion < 50) {
      eventName = "Play_time_proportion_30";
    } else if (playTimeProportion >= 50 && playTimeProportion < 80) {
      eventName = "Play_time_proportion_50";
    } else {
      eventName = "Play_time_proportion_80";
    }
    DataReportUtil.instance.reportData(
      eventName: eventName,
      params: {
        "video_duration": playerValue.duration.inSeconds,
        "vid": _getVideoId(),
        "uid": _getUidOfVideo(),
      },
    );
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
        .videoLike(tag, _videoDetailPageParamsBean?.getVid ?? '',
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
                Common.getAddMoneyViewKeyFromSymbol(_getVideoInfoDataBean.id);
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
        if (response == null && mounted) {
          EventBusHelp.getInstance()
              .fire(FollowStatusChangeEvent(_pageFlag, false, false));
        }
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data == SimpleResponse.responseSuccess) {
          _isFollow = true;
          VideoDetailDataMgr.instance.updateFollowStatusByKey(_pageFlag, true);
          if (_getVideoInfoDataBean != null) {
            int originFollowCnt =
                int.parse(_getVideoInfoDataBean?.followerCount ?? "0");
            originFollowCnt += 1;
            _getVideoInfoDataBean.followerCount = originFollowCnt.toString();
          }
          EventBusHelp.getInstance()
              .fire(FollowStatusChangeEvent(_pageFlag, true, true));
        }
      } else {
        if (bean.status == "50007") {
          ToastUtil.showToast(InternationalLocalizations.followSelfErrorTips);
        } else {
          ToastUtil.showToast(bean.msg);
        }
        EventBusHelp.getInstance()
            .fire(FollowStatusChangeEvent(_pageFlag, true, false));
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
        if (response == null && mounted) {
          EventBusHelp.getInstance()
              .fire(FollowStatusChangeEvent(_pageFlag, false, false));
        }
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data == SimpleResponse.responseSuccess) {
          _isFollow = false;
          VideoDetailDataMgr.instance.updateFollowStatusByKey(_pageFlag, false);
          if (_getVideoInfoDataBean != null) {
            int originFollowCnt =
                int.parse(_getVideoInfoDataBean?.followerCount ?? "0");
            originFollowCnt -= 1;
            _getVideoInfoDataBean.followerCount = originFollowCnt.toString();
          }
          EventBusHelp.getInstance()
              .fire(FollowStatusChangeEvent(_pageFlag, false, true));
        }
      } else {
        ToastUtil.showToast(bean.msg);
        EventBusHelp.getInstance()
            .fire(FollowStatusChangeEvent(_pageFlag, false, false));
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
        VideoDetailDataMgr.instance.updateFollowStatusByKey(_pageFlag, true);
      } else {
        _isFollow = false;
        VideoDetailDataMgr.instance.updateFollowStatusByKey(_pageFlag, false);
      }
    }
  }

  /// 添加留言
  void _httpVideoComment(
      String accountName, String id, String content, String vid, String uid) {
    setState(() {
      _isNetIng = true;
    });
    RequestManager.instance
        .videoComment(tag, id, accountName, content)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      VideoCommentBean bean =
          VideoCommentBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleProxyResponse.statusStrSuccess &&
          bean.data != null) {
        if (bean.data.ret == SimpleProxyResponse.responseSuccess) {
          _httpGetTicketInfo(vid, uid, bean.data?.replyid ?? '', content);
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
        ToastUtil.showToast(bean?.data?.error ?? '');
        setState(() {
          _isNetIng = false;
        });
      }
    });
  }

  void refreshCommentTop(String replyId, String content) {
    if (_commentSendType == CommentSendType.commentSendTypeNormal) {
      CommentListItemBean commentListItemBean =
          _buildCommentBean(replyId, content);
      if (_commentListDataBean?.top != null) {
        _listComment.insert(1, commentListItemBean);
      } else {
        _listComment.insert(0, commentListItemBean);
      }
      if (!TextUtil.isEmpty(_commentListDataBean?.total)) {
        int total = int.parse(_commentListDataBean?.total);
        total++;
        _commentListDataBean?.total = total.toString();
      }
      Future.delayed(Duration(milliseconds: 1500), () {
        setState(() {
          commentListItemBean.isShowInsertColor = false;
        });
      });
    } else {
      if (_listComment.length > _sendCommentIndex &&
          _listComment[_sendCommentIndex] is CommentListItemBean) {
        CommentListItemBean commentListItemBean =
            _listComment[_sendCommentIndex];
        CommentListChildrenBean commentListChildrenBean =
            _buildCommentChildrenBean(
                commentListItemBean?.cid ?? '', replyId, content);
        if (!ObjectUtil.isEmptyList(commentListItemBean?.children)) {
          commentListItemBean.children.insert(0, commentListChildrenBean);
        } else {
          commentListItemBean.children = [commentListChildrenBean];
        }
        Future.delayed(Duration(milliseconds: 1500), () {
          setState(() {
            commentListChildrenBean.isShowInsertColor = false;
          });
        });
      }
    }
    clearCommentInput();
  }

  /// 读取用户信息
  void _httpUserInfo(String replyId, String content) {
    RequestManager.instance.accountGetInfo(tag, Constant.uid).then((response) {
      if (response == null || !mounted) {
        clearCommentInput();
        return;
      }
      AccountGetInfoBean bean =
          AccountGetInfoBean.fromJson(json.decode(response.data));
      if (bean != null &&
          bean.status == SimpleResponse.statusStrSuccess &&
          bean.data != null) {
        Constant.accountGetInfoDataBean = bean.data;
        refreshCommentTop(replyId, content);
      } else {
        clearCommentInput();
      }
    }).whenComplete(() {
      setState(() {
        _isNetIng = false;
      });
    });
  }

  void clearCommentInput() {
    _textController.text = '';
    _commentSendType = CommentSendType.commentSendTypeNormal;
    _isAbleSendMsg = false;
    //评论成功上报
    DataReportUtil.instance.reportData(
        eventName: "Comments",
        params: {"Comments": "1", "is_comment_videopage": "1"});
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
    if (isClearData) {
      _commentListDataBean = null;
      _listComment.clear();
    }
    String vid = _getVideoId();
    RequestManager.instance
        .videoCommentListNew(tag, vid, _commentPage, commentPageSize,
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
    return _processVideoCommentListByData(bean, isLoadMore, isClearData);
  }

  /// 处理当前用户与创作者之间的关系
  _processExclusiveRelation(Response response) {
    if (response == null) {
      return false;
    }
    ExclusiveRelationBean bean =
        ExclusiveRelationBean.fromJson(json.decode(response.data));
    if (bean != null &&
        bean.status == SimpleResponse.statusStrSuccess &&
        bean.data != null &&
        !ObjectUtil.isEmptyList(bean.data.list) &&
        bean.data.list[0] != null) {
      _exclusiveRelationItemBean = bean.data.list[0];
    }
  }

  bool _processVideoCommentListByData(
      CommentListBean bean, bool isLoadMore, bool isClearData) {
    if (bean == null) {
      return false;
    }
    if (bean.status == SimpleResponse.statusStrSuccess && bean.data != null) {
      if (!ObjectUtil.isEmptyList(bean.data.list) || bean.data.top != null) {
        _commentListDataBean = bean.data;
        if (!isLoadMore || isClearData) {
          _listComment.clear();
          if (_commentListDataBean.top != null) {
            _listComment.add(_commentListDataBean.top);
          }
        }
      }
      if (!ObjectUtil.isEmptyList(_commentListDataBean?.list)) {
        _listComment.addAll(_commentListDataBean.list);
        _commentPage++;
      }
//      if (bean.data.isCommented == CommentListDataBean.isCommentedNo &&
//          _isShowCommentHint &&
//          !_isShowCommentHintIng &&
//          mounted) {
//        setState(() {
//          _isShowCommentHintIng = true;
//          _isShowCommentHint = false;
//        });
//      }
      return true;
    } else if (bean.status == SimpleResponse.statusStrSuccess) {
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
          CommentListItemBean commentListItemBean = _listComment[index];
          commentListItemBean?.isLike = '1';
          if (!TextUtil.isEmpty(commentListItemBean?.likeCount)) {
            commentListItemBean?.likeCount =
                (int.parse(commentListItemBean?.likeCount) + 1).toString();
          }
          commentKey =
              Common.getAddMoneyViewKeyFromSymbol(commentListItemBean.cid);
          addVal = Common.calcCommentAddedIncome(
              _cosInfoBean,
              _exchangeRateInfoData,
              _chainStateBean,
              commentListItemBean.votepower);
          _addVoterPowerToComment(commentListItemBean);
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
      String curVid = _getVideoId();
      if (curVid == vid) {
        _processVideoRelateList(response, isLoadMore);
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNetIng = false;
      });
      if (_judgeIsNeedLoadNextPageData(vid)) {
        _httpVideoRelateList(true);
      }
    });
  }

  /// 处理视频相关推荐列表返回数据
  bool _processVideoRelateList(Response response, bool isLoading) {
    if (response == null) {
      return false;
    }
    RelateListBean bean = RelateListBean.fromJson(json.decode(response.data));
    return _processVideoRelateListByData(bean, isLoading);
  }

  bool _processVideoRelateListByData(RelateListBean bean, bool isLoading) {
    if (bean == null) {
      return false;
    }
    if (bean.status == SimpleResponse.statusStrSuccess &&
        bean.data != null &&
        bean.data[0] != null) {
      if (bean.data[0].list != null) {
        if (bean.data[0].list.isNotEmpty) {
          _listRelate = bean.data[0].list;
          _listData.addAll(_listRelate);
        }
        if (!isLoading) {
          Future.delayed(Duration(seconds: 1), () {
            if (!_isScrolling) {
              _reportVideoExposure();
            }
          });
        }
      }
      _videoPage++;
      _isHaveMoreData = bean.data[0].hasNext == "1";
      return true;
    } else if (bean.status == SimpleResponse.statusStrSuccess) {
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
    } else if (_videoDetailPageParamsBean != null &&
        _videoDetailPageParamsBean.getVid != null) {
      vid = _videoDetailPageParamsBean.getVid;
    }
    return vid;
  }

  String _getUidOfVideo() {
    String uid = '';
    if (_getVideoInfoDataBean != null && _getVideoInfoDataBean.uid != null) {
      uid = _getVideoInfoDataBean.uid;
    } else if (_videoDetailPageParamsBean != null &&
        _videoDetailPageParamsBean.getUid != null) {
      uid = _videoDetailPageParamsBean.getUid;
    }
    return uid;
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
    if (response == null) {
      return;
    }
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
        WebViewUtil.instance
            .openWebViewResult(Constant.logInWebViewUrl)
            .then((isSuccess) {
          if (isSuccess != null && isSuccess) {
            _httpVideoIsLike(true);
            _httpAddWatchHistory();
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
      WebViewUtil.instance
          .openWebViewResult(Constant.logInWebViewUrl)
          .then((isSuccess) async {
        if (isSuccess != null && isSuccess) {
          if (!_isNetIng) {
            setState(() {
              _isNetIng = true;
            });
          }
          bool oldStatus = _isFollow;
          await _initAuthorFollowStatus(_getVideoInfoDataBean?.uid ?? '');
          if (oldStatus == _isFollow) {
            _checkAbleAccountFollow();
          } else {
            EventBusHelp.getInstance()
                .fire(FollowStatusChangeEvent(_pageFlag, _isFollow, true));
            if (_isNetIng) {
              setState(() {
                _isNetIng = false;
              });
            }
          }
          _httpAddWatchHistory();
        }
      });
    }
  }

  void _checkAbleCommentLike(String isLike, String cid, int index) {
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      if (isLike == CommentListItemBean.isLikeNo) {
        if (_checkIsEnergyEnough()) {
          _httpCommentLike(cid, index, Constant.accountName);
        } else {
          _showEnergyNotEnoughDialog();
        }
      }
    } else {
      WebViewUtil.instance
          .openWebViewResult(Constant.logInWebViewUrl)
          .then((isSuccess) {
        if (isSuccess != null && isSuccess) {
          _checkAbleCommentLike(isLike, cid, index);
          _httpAddWatchHistory();
        }
      });
    }
  }

  void _checkAbleVideoComment(String id, String vid, String uid) {
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      if (_isAbleSendMsg) {
        String content;
        if (_commentSendType == CommentSendType.commentSendTypeNormal) {
          content = _textController.text.trim();
        } else {
          content = Constant.commentSendHtml(
              _uid, _commentName, _textController.text.trim());
        }
        if (_isInputFace) {
          _isInputFace = false;
          _selectCategory = null;
        } else {
          FocusScope.of(context).requestFocus(FocusNode());
        }
        _httpVideoComment(Constant.accountName, id, content, vid, uid);
      }
    } else {
      WebViewUtil.instance
          .openWebViewResult(Constant.logInWebViewUrl)
          .then((isSuccess) {
        if (isSuccess != null && isSuccess) {
          _checkAbleVideoComment(id, vid, uid);
          _httpAddWatchHistory();
        }
      });
    }
  }

  bool _checkIsEnergyEnough() {
    double energy = RevenueCalculationUtil.calCurrentEnergy(
        _cosInfoBean?.votePower?.toString(),
        _cosInfoBean?.vest?.value?.toString());
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
        _cosInfoBean?.votePower?.toString(),
        _cosInfoBean?.vest?.value?.toString());
    double maxEnergy = RevenueCalculationUtil.vestToEnergy(
        _cosInfoBean?.vest?.value?.toString());
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
            WebViewUtil.instance
                .openWebViewResult(Constant.logInWebViewUrl)
                .then((isSuccess) {
              if (isSuccess != null && isSuccess) {
                setState(() {});
                _httpAddWatchHistory();
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
    String avatar =
        _getVideoInfoDataBean?.anchorImageCompress?.avatarCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(avatar)) {
      avatar = _getVideoInfoDataBean?.anchorAvatar ?? '';
    }
    String introduction = _getVideoInfoDataBean?.introduction ?? '';
    bool isCertification = _getVideoInfoDataBean?.isCertification ==
        CommentListItemBean.isCertificationYes;
    return Container(
      margin: EdgeInsets.only(top: AppDimens.margin_10),
      child: Column(
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
                      style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_333333,
                          darkColorStr: DarkModelTextColorUtil
                              .firstLevelBrightnessColorStr,
                        ),
                        fontSize: AppDimens.text_size_16,
                        fontWeight: FontWeight.w700,
                      ),
                      minFontSize: 8,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: AppDimens.margin_5),
                    child: AnimationRotateWidget(
                      rotated: _isRotatedTitle,
                      child: Image.asset(AppThemeUtil.getIcnDownTitle()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
                left: AppDimens.margin_15,
                top: AppDimens.margin_8_5,
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
                        _videoGiftInfoDataBean?.rewardTotal ?? '0',
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
                              ToastUtil.showToast(InternationalLocalizations
                                  .videoLinkFinishHint);
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
                                      AppThemeUtil.getVideoLikedNoIcn()),
                              Container(
                                margin:
                                    EdgeInsets.only(top: AppDimens.margin_8),
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
                            Image.asset(AppThemeUtil.getVideoShareIcn()),
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
                            Image.asset(AppThemeUtil.getVideoReportIcn()),
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
              height: AppDimens.item_line_height_0_5,
              color: AppThemeUtil.setDifferentModeColor(
                lightColor: AppColors.color_ebebeb,
                darkColorStr: "3E3E3E",
              ),
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
                    style: TextStyle(
                      color: AppThemeUtil.setDifferentModeColor(
                        lightColor: AppColors.color_a0a0a0,
                        darkColorStr:
                            DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                      ),
                      fontSize: AppDimens.text_size_13,
                    ),
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
                          key: Common.getAddMoneyViewKeyFromSymbol(
                              _getVideoInfoDataBean?.id),
                          textStyle: TextStyle(
                            color: AppThemeUtil.setDifferentModeColor(
                              lightColor: AppColors.color_333333,
                              darkColorStr: DarkModelTextColorUtil
                                  .firstLevelBrightnessColorStr,
                            ),
                            fontSize: AppDimens.text_size_18,
                            fontWeight: FontWeight.w700,
                          ),
                          baseWidget: AutoSizeText(
                            '${Common.getCurrencySymbolByLanguage()} ${_videoSettlementBean.getTotalRevenue ?? ""}',
                            style: TextStyle(
                                color: AppThemeUtil.setDifferentModeColor(
                                  lightColor: AppColors.color_333333,
                                  darkColorStr: DarkModelTextColorUtil
                                      .firstLevelBrightnessColorStr,
                                ),
                                fontSize: AppDimens.text_size_18,
                                fontWeight: FontWeight.w700,
                                fontFamily: "DIN"),
                            minFontSize: 8,
                          )),
                      Container(
                        padding: EdgeInsets.only(left: AppDimens.margin_10),
                        child: AnimationRotateWidget(
                          rotated: _isRotatedMoney,
                          child: Image.asset(AppThemeUtil.getIcnDownTitle()),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: AppDimens.item_line_height_0_5,
            color: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_ebebeb,
              darkColorStr: "3E3E3E",
            ),
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
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.color_ebebeb,
                                width: AppDimens.item_line_height_0_5),
                            borderRadius:
                                BorderRadius.circular(AppDimens.item_size_20),
                          ),
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
                                  avatar,
                                ),
                              )
                            ],
                          ),
                        ),
                        onTap: () {
                          if (Common.isAbleClick()) {
                            Navigator.of(context)
                                .push(CupertinoPageRoute(builder: (_) {
                              return OthersHomePage(
                                OtherHomeParamsBean(
                                  uid: _getVideoInfoDataBean?.uid ?? '',
                                  avatar: avatar,
                                  nickName:
                                      _getVideoInfoDataBean?.anchorNickname ??
                                          '',
                                  isCertification:
                                      _getVideoInfoDataBean?.isCertification ??
                                          '',
                                  rateInfoData: _exchangeRateInfoData,
                                  dgpoBean: _chainStateBean?.dgpo,
                                ),
                              );
                            }));
                            Navigator.of(context).push(SlideAnimationRoute(
                              builder: (_) {
                                return OthersHomePage(
                                  OtherHomeParamsBean(
                                    uid: _getVideoInfoDataBean?.uid ?? '',
                                    avatar: avatar,
                                    nickName:
                                        _getVideoInfoDataBean?.anchorNickname ??
                                            '',
                                    isCertification: _getVideoInfoDataBean
                                            ?.isCertification ??
                                        '',
                                    rateInfoData: _exchangeRateInfoData,
                                    dgpoBean: _chainStateBean?.dgpo,
                                  ),
                                );
                              },
                            ));
                          }
                        },
                      ),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          child: Container(
                            margin: EdgeInsets.only(left: AppDimens.margin_10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Flexible(
                                        child: AutoSizeText(
                                      _getVideoInfoDataBean?.anchorNickname ??
                                          '',
                                      style: TextStyle(
                                        color: AppThemeUtil.setDifferentModeColor(
                                            lightColor: AppColors.color_333333,
                                            darkColorStr: DarkModelTextColorUtil
                                                .firstLevelBrightnessColorStr),
                                        fontSize: AppDimens.text_size_14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      minFontSize: 8,
                                    )),
                                    //认证标识
                                    Offstage(
                                      offstage: !isCertification,
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            left: AppDimens.margin_7),
                                        child: Image.asset(
                                          "assets/images/ic_comment_certification.png",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin:
                                      EdgeInsets.only(top: AppDimens.margin_3),
                                  child: AutoSizeText(
                                    '${_getVideoInfoDataBean?.followerCount ?? '0'} ${InternationalLocalizations.videoSubscriptionCount}',
                                    style: AppStyles.text_style_a0a0a0_12,
                                    minFontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            if (Common.isAbleClick()) {
                              Navigator.of(context).push(SlideAnimationRoute(
                                builder: (_) {
                                  return OthersHomePage(
                                    OtherHomeParamsBean(
                                      uid: _getVideoInfoDataBean?.uid ?? '',
                                      avatar: avatar,
                                      nickName: _getVideoInfoDataBean
                                              ?.anchorNickname ??
                                          '',
                                      isCertification: _getVideoInfoDataBean
                                              ?.isCertification ??
                                          '',
                                      rateInfoData: _exchangeRateInfoData,
                                      dgpoBean: _chainStateBean?.dgpo,
                                    ),
                                  );
                                },
                              ));
                            }
                          },
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            height: AppDimens.item_size_25,
                            child: Material(
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radius_size_21),
                              color: _isFollow
                                  ? AppColors.color_d6d6d6
                                  : AppColors.color_3674ff,
                              child: MaterialButton(
                                minWidth: AppDimens.item_size_70,
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppDimens.margin_12),
                                child: Text(
                                  _isFollow
                                      ? InternationalLocalizations
                                          .videoSubscriptionFinish
                                      : InternationalLocalizations
                                          .videoSubscription,
                                  style: AppStyles.text_style_ffffff_12,
                                  maxLines: 1,
                                ),
                                onPressed: () {
                                  _checkAbleAccountFollow();
                                },
                              ),
                            ),
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
//                        left: AppDimens.margin_15,
                        top: AppDimens.margin_5,
                        right: AppDimens.margin_15),
                    child: Column(
                      children: <Widget>[
                        Offstage(
                          offstage: ObjectUtil.isEmptyString(introduction),
                          child: Container(
                            alignment: Alignment.centerLeft,
                            margin: EdgeInsets.only(
                                left: AppDimens.margin_50,
                                top: AppDimens.margin_11),
                            child: Linkify(
                              onOpen: (link) async {
                                if (link.url
                                    .startsWith(Constant.costvWebOrigin)) {
                                  Uri uri;
                                  try {
                                    uri = Uri.parse(link.url);
                                  } catch (error) {
                                    CosLogUtil.log('$tag error: $error');
                                    return;
                                  }
                                  if (uri != null &&
                                      uri.path.startsWith(Constant
                                          .webPageVideoPlayPathLeading) &&
                                      uri.pathSegments.length ==
                                          Constant
                                              .webPageVideoPlayPathSegmentsLength) {
                                    String vid = uri.pathSegments[2];
                                    if (!TextUtil.isEmpty(vid)) {
                                      Navigator.of(context)
                                          .push(SlideAnimationRoute(
                                        builder: (_) {
                                          return VideoDetailsPage(
                                              VideoDetailPageParamsBean
                                                  .createInstance(
                                            vid: vid,
                                            enterSource: VideoDetailsEnterSource
                                                .VideoDetailsEnterSourceH5LikeRewardVideo,
                                          ));
                                        },
                                        settings: RouteSettings(
                                            name: videoDetailPageRouteName),
                                        isCheckAnimation: true,
                                      ));
                                    } else {
                                      if (await canLaunch(link.url)) {
                                        await launch(link.url);
                                      }
                                    }
                                  } else {
                                    if (await canLaunch(link.url)) {
                                      await launch(link.url);
                                    }
                                  }
                                } else {
                                  if (await canLaunch(link.url)) {
                                    await launch(link.url);
                                  }
                                }
                              },
                              text: introduction,
                              style: TextStyle(
                                color: AppThemeUtil.setDifferentModeColor(
                                  lightColor: AppColors.color_333333,
                                  darkColorStr: DarkModelTextColorUtil
                                      .firstLevelBrightnessColorStr,
                                ),
                                fontSize: AppDimens.text_size_13,
                              ),
                            ),
                          ),
                        ),
                        Offstage(
                          offstage: !_checkHasTag(),
                          child: Container(
                            alignment: Alignment.topLeft,
                            margin: EdgeInsets.only(
                                left: AppDimens.margin_50,
                                top: AppDimens.margin_5),
//                          height: AppDimens.item_size_30,
                            child: Wrap(
                              runSpacing: 8,
                              children: _getTagListWidget(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: AppDimens.margin_15),
                  child: Container(
                    height: AppDimens.item_line_height_0_5,
                    color: AppThemeUtil.setDifferentModeColor(
                      lightColor: AppColors.color_ebebeb,
                      darkColorStr: "3E3E3E",
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  bool _checkHasTag() {
    int cnt = _getVideoInfoDataBean?.tagName?.length ?? 0;
    if (cnt > 0) {
      return true;
    }
    return false;
  }

  List<Widget> _getTagListWidget() {
    List<Widget> list = [];
    int cnt = _getVideoInfoDataBean?.tagName?.length ?? 0;
    if (cnt > 0) {
      for (int i = 0; i < cnt; ++i) {
        TagNameBean tagName = _getVideoInfoDataBean?.tagName[i];
        var tagWidget = Container(
          margin: EdgeInsets.only(right: AppDimens.margin_7),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Material(
                color: Colors.transparent,
                shape: BeveledRectangleBorder(
                  //斜角矩形边框
                  side: BorderSide(
                    width: AppDimens.item_line_height_0_5,
                    color: AppColors.color_a0a0a0,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(1),
                    topRight: Radius.circular(1),
                  ),
                ),
                child: new Container(
                    padding: EdgeInsets.only(
                        left: 12,
                        top: AppDimens.margin_2,
                        bottom: AppDimens.margin_2,
                        right: AppDimens.margin_4),
                    height: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(3),
                              ),
                              border: Border.all(
                                  color: AppColors.color_a0a0a0,
                                  width: AppDimens.item_line_height_1)),
                        ),
                        Container(
                          child: AutoSizeText(
                            tagName?.content ?? "",
                            style: AppStyles.text_style_858585_11,
                            minFontSize: 8,
                          ),
                          margin: EdgeInsets.only(left: 5),
                        ),
                      ],
                    )),
              )
            ],
          ),
        );
        list.add(tagWidget);
      }
    }
    return list;
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

  Widget _buildTabStyle() {
    return InkWell(
      onTap: () {
        if (Common.isAbleClick()) {
          String sort;
          setState(() {
            if (_commentTypeCurrent == CommentType.commentTypeHot) {
              _commentTypeCurrent = CommentType.commentTypeTime;
              sort = 'time';
            } else {
              _commentTypeCurrent = CommentType.commentTypeHot;
              sort = 'hot';
            }
            _httpVideoCommentList(false, false);
          });
          DataReportUtil.instance.reportData(
              eventName: "Comments_Change_sorting",
              params: {"Comments_Change_sorting": sort});
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Image.asset(AppThemeUtil.getCommentSwitchICcn()),
          Container(
            margin: EdgeInsets.only(left: AppDimens.margin_6),
            child: Text(
                _commentTypeCurrent == CommentType.commentTypeHot
                    ? InternationalLocalizations.videoHotSort
                    : InternationalLocalizations.videoTimeSort,
                style: TextStyle(
                  color: AppThemeUtil.setDifferentModeColor(
                    lightColor: AppColors.color_333333,
                    darkColorStr:
                        DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                  ),
                  fontSize: AppDimens.text_size_14,
                )),
          )
        ],
      ),
    );
  }

  void openChildrenWindows(
      CommentListItemBean commentListItemBean, int index, bool isReply) {
    OpenCommentChildrenParameterBean bean = OpenCommentChildrenParameterBean();
    bean.isReply = isReply;
    bean.vid = commentListItemBean?.vid ?? '';
    bean.pid = commentListItemBean?.cid ?? '';
    bean.uid = Constant.uid;
    bean.mapRemoteResError = _mapRemoteResError;
    bean.vestStatus = _getVideoInfoDataBean?.vestStatus ?? '';
    bean.cosInfoBean = _cosInfoBean;
    bean.chainStateBean = _chainStateBean;
    bean.exchangeRateInfoData = _exchangeRateInfoData;
    bean.commentListItemBean = commentListItemBean;
    bean.creatorUid = _getVideoInfoDataBean?.uid ?? '';
    bean.isCertification = commentListItemBean?.user?.isCertification ?? '';
    setState(() {
      _openCommentChildrenParameterBean = bean;
      _clickCommentIndex = index;
    });
  }

  void changeCommentSendMsgReply(
      CommentListItemBean commentListItemBean, int index) {
    setState(() {
      _commentSendType = CommentSendType.commentSendTypeChildren;
      _commentId = commentListItemBean?.cid ?? '';
      _commentName = commentListItemBean?.user?.nickname ?? '';
      _sendCommentIndex = index;
      _uid = commentListItemBean?.uid ?? '';
    });
  }

  CommentListItemBean _buildCommentBean(String commentId, String content) {
    String vid = _getVideoInfoDataBean?.id ?? '';
    String uid = _getVideoInfoDataBean?.uid ?? '';
    int timestamp =
        (Decimal.parse(DateTime.now().millisecondsSinceEpoch.toString()) /
                Decimal.parse('1000'))
            .toInt();
    String nickName = Constant?.accountGetInfoDataBean?.nickname ?? '';
    String avatar = Constant?.accountGetInfoDataBean?.avatar ?? '';
    String isCreator = CommentListItemBean.isCreatorNo;
    String isCertification = "0";
    if (Constant.uid == uid) {
      isCreator = CommentListItemBean.isCreatorYes;
      isCertification = _getVideoInfoDataBean?.isCertification ?? "0";
    }
    CommentListItemBean commentListItemBean = CommentListItemBean(
      '',
      vid,
      '',
      content,
      uid,
      '',
      '',
      '0',
      commentId,
      '',
      '',
      '0',
      '0',
      '1',
      timestamp.toString(),
      timestamp.toString(),
      '',
      '',
      new CommentListUserBean(nickName, avatar, '',
          Constant?.accountGetInfoDataBean?.imageCompress, isCertification),
      '',
      null,
      '0',
      '0',
      _getTicketInfoDataBean?.isTicket ?? '0',
      _getTicketInfoDataBean?.isTop ?? '0',
      isCreator,
      "0",
    );
    commentListItemBean.isShowInsertColor = true;
    commentListItemBean.isShowDeleteComment = false;
    return commentListItemBean;
  }

  CommentListChildrenBean _buildCommentChildrenBean(
      String pid, String commentId, String content) {
    String vid = _getVideoInfoDataBean?.id ?? '';
    String uid = _getVideoInfoDataBean?.uid ?? '';
    int timestamp =
        (Decimal.parse(DateTime.now().millisecondsSinceEpoch.toString()) /
                Decimal.parse('1000'))
            .toInt();
    String nickName = Constant?.accountGetInfoDataBean?.nickname ?? '';
    String avatar = Constant?.accountGetInfoDataBean?.avatar ?? '';
    String isCreator = CommentListItemBean.isCreatorNo;
    String isCertification = "0";
    if (Constant.uid == uid) {
      isCreator = CommentListItemBean.isCreatorYes;
      isCertification = _getVideoInfoDataBean?.isCertification ?? "0";
    }
    CommentListChildrenBean commentListChildrenBean =
        new CommentListChildrenBean(
            '',
            vid,
            pid,
            content,
            uid,
            '0',
            commentId,
            '',
            '0',
            '0',
            '1',
            timestamp.toString(),
            timestamp.toString(),
            '',
            '',
            new CommentListChildrenUserBean(nickName, avatar,
                Constant?.accountGetInfoDataBean?.imageCompress),
            _getTicketInfoDataBean?.isTicket ?? '0',
            '0',
            isCreator,
            isCertification,
            "0");
    commentListChildrenBean.isShowInsertColor = true;
    return commentListChildrenBean;
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

    double videoDescWidth = MediaQuery.of(context).size.width / 2;
    String languageCode = Common.getLanCodeByLanguage();
    if (languageCode == InternationalLocalizations.languageCodeRu) {
      videoDescWidth = MediaQuery.of(context).size.width / 3;
    }
    String videoUrl =
        relateListItemBean?.videoImageCompress?.videoCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(videoUrl)) {
      videoUrl = relateListItemBean?.videoCoverBig ?? '';
    }
    return InkWell(
      child: VisibilityDetector(
        key: Key(relateListItemBean.id ?? index),
        onVisibilityChanged: (VisibilityInfo info) {
          if (_visibleFractionMap == null) {
            _visibleFractionMap = {};
          }
          _visibleFractionMap[index] = info.visibleFraction;
        },
        child: Column(
          children: <Widget>[
            Offstage(
              offstage: index != 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: AppDimens.item_line_height_0_5,
                    color: AppThemeUtil.setDifferentModeColor(
                      lightColor: AppColors.color_ebebeb,
                      darkColorStr: "3E3E3E",
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.only(
                      top: AppDimens.margin_15,
                      right: AppDimens.margin_5,
                      left: AppDimens.margin_15,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        //视频推荐描述
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: videoDescWidth,
                          ),
                          margin: EdgeInsets.only(right: AppDimens.margin_5),
                          child: AutoSizeText(
                            InternationalLocalizations.videoRecommendation,
                            style: TextStyle(
                              color: AppThemeUtil.setDifferentModeColor(
                                lightColor: AppColors.color_333333,
                                darkColorStr: DarkModelTextColorUtil
                                    .firstLevelBrightnessColorStr,
                              ),
                              fontSize: AppDimens.text_size_16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            minFontSize: 8,
                          ),
                        ),
                        //自动播放开关
                        Container(
                          child: VideoAutoPlaySettingWidget(
                            key: index == 0 ? _autoPlaySwitchKey : null,
                            clickQuestionCallBack:
                                (double globalX, double globalY) {},
                            autoPlaySwitchCallBack: (bool val) {
                              _handleAutoPlaySwitch(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                  left: AppDimens.margin_15,
                  top: AppDimens.margin_12,
                  right: AppDimens.margin_15),
              child: Row(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: <Widget>[
                      Container(
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
                          imageUrl: videoUrl,
                        ),
                      ),
                      _getVideoDurationWidget(),
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
                          style: TextStyle(
                            color: AppThemeUtil.setDifferentModeColor(
                              lightColor: AppColors.color_333333,
                              darkColorStr: DarkModelTextColorUtil
                                  .firstLevelBrightnessColorStr,
                            ),
                            fontSize: AppDimens.text_size_14,
                          ),
                          maxLines: 2,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              totalRevenue != null
                                  ? '${Common.getCurrencySymbolByLanguage()} ${totalRevenue ?? ''}'
                                  : '',
                              style: TextStyle(
                                  color: AppThemeUtil.setDifferentModeColor(
                                    lightColor: AppColors.color_333333,
                                    darkColorStr: DarkModelTextColorUtil
                                        .secondaryBrightnessColorStr,
                                  ),
                                  fontSize: AppDimens.text_size_15,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "DIN"),
                            ),
                            Container(
                              margin:
                                  EdgeInsets.only(top: AppDimens.margin_2_5),
                              child: Text(
                                relateListItemBean?.anchorNickname ?? '',
                                style: TextStyle(
                                  color: AppThemeUtil.setDifferentModeColor(
                                    lightColor: AppColors.color_333333,
                                    darkColorStr: DarkModelTextColorUtil
                                        .secondaryBrightnessColorStr,
                                  ),
                                  fontSize: AppDimens.text_size_15,
                                  fontWeight: FontWeight.w700,
                                ),
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
      ),
      onTap: () {
        if (Common.isAbleClick()) {
          VideoPlayerValue playerValue = _videoPlayerController?.value;
          if (playerValue != null) {
            reportVideoEnd(playerValue);
          }
          VideoDetailDataMgr.instance
              .updateCachedNextVideoInfoByKey(_pageFlag, null);
          _handlePlayNextVideo(relateListItemBean,
              VideoDetailsEnterSource.VideoDetailsEnterSourceVideoRecommend);
//          DataReportUtil.instance.reportData(
//            eventName: "Click_video",
//            params: {"Click_video": relateListItemBean?.id ?? ''},
//          );
          VideoReportUtil.reportClickVideo(
              ClickVideoSource.VideoDetail, relateListItemBean?.id ?? '');
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
      CommentListItemParameterBean bean = CommentListItemParameterBean();
      bean.showType = CommentListItemParameterBean.showTypeVideoComment;
      bean.commentListItemBean = _listComment[index];
      bean.total = _commentListDataBean?.total ?? '';
      bean.index = index;
      bean.commentLength = _listComment?.length ?? 0;
      bean.exchangeRateInfoData = _exchangeRateInfoData;
      bean.chainStateBean = _chainStateBean;
      bean.uid = _getVideoInfoDataBean?.uid ?? '';
      bean.isLoadMoreComment = _isLoadMoreComment;
      bean.commentPage = _commentPage;
      return CommentListItem(
          bean: bean,
          clickCommentLike: (commentListDataListBean, index) {
            if (commentListDataListBean?.vestStatus !=
                VideoInfoResponse.vestStatusFinish) {
              _checkAbleCommentLike(commentListDataListBean?.isLike ?? '',
                  commentListDataListBean?.cid ?? '', index);
            } else {
              ToastUtil.showToast(
                  InternationalLocalizations.videoLinkFinishHint);
            }
          },
          clickChildrenWindows:
              (commentListDataListBean, index, isOpenKeyboard) {
            openChildrenWindows(commentListDataListBean, index, isOpenKeyboard);
          },
          clickCommentDelete: (commentListDataListBean) {
            if (_videoCommentDeleteDialog == null) {
              _videoCommentDeleteDialog =
                  VideoCommentDeleteDialog(tag, _pageKey, _dialogSKey);
            }
            _videoCommentDeleteDialog.initData(
                commentListDataListBean?.id ?? '',
                commentListDataListBean?.vid ?? '',
                _getVideoInfoDataBean?.uid ?? '', () {
              if (index != null &&
                  _listComment != null &&
                  index < _listComment.length) {
                _listComment.removeAt(index);
                if (!TextUtil.isEmpty(_commentListDataBean?.total)) {
                  int total = int.parse(_commentListDataBean?.total);
                  total--;
                  _commentListDataBean?.total = total.toString();
                }
                setState(() {
                  _isNetIng = false;
                });
              }
            }, handleDeleteCallBack: (isProcessing, isSuccess) {});
            _videoCommentDeleteDialog.showVideoCommentDeleteDialog();
          },
          clickCommentChildren: (commentChildrenParameterBean) {
            setState(() {
              _commentSendType = CommentSendType.commentSendTypeChildren;
              _commentId = commentChildrenParameterBean.cid;
              _commentName = commentChildrenParameterBean.commentName;
              _sendCommentIndex = commentChildrenParameterBean.index;
              _uid = commentChildrenParameterBean.uid;
            });
          },
          clickLoadMoreComment: () {
            if (_commentPage == 0) {
              _commentPage = 1;
              _httpVideoCommentList(true, true);
            } else {
              _httpVideoCommentList(true, false);
            }
          },
          clickCommentFold: () {
            setState(() {
              _listComment.removeRange(5, _listComment.length);
              _commentPage = 0;
            });
          });
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
              style: TextStyle(
                color: AppThemeUtil.setDifferentModeColor(
                  lightColor: AppColors.color_333333,
                  darkColorStr:
                      DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                ),
                fontSize: AppDimens.text_size_16,
                fontWeight: FontWeight.w700,
              ),
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
                _videoDetailPageParamsBean.getVideoSource))) {
      if (_openCommentChildrenParameterBean == null) {
        double marginBottom;
        if (!_isShowCommentLength) {
          marginBottom = AppDimens.item_size_45;
        } else {
          marginBottom = AppDimens.item_size_100;
        }
        body = Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(bottom: marginBottom),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  //播放器
                  _buildPlayerWidget(),
                  //视频详情、评论、推荐视频列表
                  _buildVideoDetailInfoWidget(),
                ],
              ),
            ),
            //输入框
            _buildCommentInputWidget(),
          ],
        );
      } else {
        body = Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            //播放器
            _buildPlayerWidget(),
            //子评论页面
            VideoCommentChildrenListWidget(
                _dialogSKey, _pageKey, _openCommentChildrenParameterBean, () {
              refreshCommentTotal();
            }, (bool isInputFace) {
              _isInputFaceChildren = isInputFace;
            }, this._exclusiveRelationItemBean),
          ],
        );
      }
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
              color: AppThemeUtil.setDifferentModeColor(
                lightColor: AppColors.color_ffffff,
                darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
              ),
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: GestureDetector(
                child: body,
                onTap: () {
                  _hideAutoPlayFunctionDesc();
                  if (_isInputFaceChildren) {
                    _isInputFaceChildren = false;
                    EventBusHelp.getInstance().fire(
                        VideoCommentChildrenListEvent(
                            VideoCommentChildrenListEvent.typeCloseInputFace));
                  } else {
                    if (_isInputFace) {
                      setState(() {
                        _isInputFace = false;
                        _selectCategory = null;
                      });
                    } else {
                      //键盘弹出了,收起键盘
                      if (MediaQuery.of(context).viewInsets.bottom > 0) {
                        FocusScope.of(context).requestFocus(FocusNode());
                      }
                    }
                  }
                },
              ),
            ),
            onWillPop: () async {
              if (Common.isAbleClick()) {
                if (_isInputFaceChildren) {
                  _isInputFaceChildren = false;
                  EventBusHelp.getInstance().fire(VideoCommentChildrenListEvent(
                      VideoCommentChildrenListEvent.typeCloseInputFace));
                  return false;
                }
                if (_isInputFace) {
                  setState(() {
                    _isInputFace = false;
                    _selectCategory = null;
                  });
                  return false;
                }
                if (_openCommentChildrenParameterBean != null) {
                  refreshCommentTotal();
                  return false;
                } else {
                  showVideoSmallWindows(context);
                  Navigator.pop(context);
                }
              }
              return false;
            }),
      ),
      isShow: _isNetIng,
    );
  }

  void refreshCommentTotal() {
    setState(() {
      if (_openCommentChildrenParameterBean?.changeCommentTotal != null) {
        CommentListItemBean commentListItemBean =
            _listComment[_clickCommentIndex];
        commentListItemBean?.childrenCount =
            _openCommentChildrenParameterBean?.changeCommentTotal?.toString();
      }
      _openCommentChildrenParameterBean = null;
    });
  }

  /// 显示视频小窗口
  void showVideoSmallWindows(BuildContext context) {
    if (_getVideoInfoDataBean != null) {
      _videoPlayerController?.removeListener(videoPlayerChanged);
      _videoPlayerController?.pause();
      _isShowSmallWindow = true;
      _videoPlayerController?.pause();
      VideoSmallWindowsBean bean = VideoSmallWindowsBean();
      bean.isVideoDetailsInit = true;
      bean.listDataItem.add(_getVideoInfoDataBean);
      if (!ObjectUtil.isEmptyList(_listData)) {
        bean.listDataItem.addAll(_listData);
      }
      bean.startAt = _videoPlayerController?.value?.position;
      bean.vid = _videoDetailPageParamsBean.getVid;
      bean.uid = _videoDetailPageParamsBean.getUid;
      bean.videoSource = _videoDetailPageParamsBean.getVideoSource;
      bean.getVideoInfoDataBean = _getVideoInfoDataBean;
      bean.linkCount = _linkCount;
      bean.popReward = _popReward;
      bean.videoGiftInfoDataBean = _videoGiftInfoDataBean;
      bean.integralUserInfoDataBean = _integralUserInfoDataBean;
      bean.bankPropertyDataBean = _bankPropertyDataBean;
      bean.exchangeRateInfoData = _exchangeRateInfoData;
      bean.isVideoLike = _isVideoLike;
      bean.isFollow = _isFollow;
      bean.listRelate = _listRelate;
      bean.listData = _listData;
      bean.videoPage = _videoPage;
      bean.isHaveMoreData = _isHaveMoreData;
      bean.commentListDataBean = _commentListDataBean;
      bean.listComment = _listComment;
      bean.commentPage = _commentPage;
      bean.videoPlayerController = _videoPlayerController;
      bean.exclusiveRelationItemBean = _exclusiveRelationItemBean;
      OverlayVideoSmallWindowsUtils.instance
          .showVideoSmallWindow(context, VideoSmallWindows(bean));
      Constant.backAnimationType = SlideAnimationRoute.animationTypeVertical;
    }
  }

  ///创建播放器相关widget
  Widget _buildPlayerWidget() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (DragStartDetails details) {
        _startY = details.globalPosition.dy;
      },
      onVerticalDragUpdate: (DragUpdateDetails details) {
        double endY = details.globalPosition.dy;
        double moveY = endY - _startY;
        if (moveY > 0 && moveY >= _triggerY) {
          if (_getVideoInfoDataBean != null) {
            showVideoSmallWindows(context);
            Navigator.pop(context);
          }
        }
      },
      child: Container(
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
    );
  }

  ///创建视频详情、评论、推荐列表等相关widget
  Widget _buildVideoDetailInfoWidget() {
    if (_isFirstLoad) {
      return Container();
    }
    return Expanded(
      child: RefreshAndLoadMoreListView(
        itemBuilder: (context, index) {
          if (!_isScrolling) {
            _visibleFractionMap[index] = 1;
          }
          return _buildListItem(index);
        },
        itemCount: _getTotalItemCount(),
        onLoadMore: () {
          _httpVideoRelateList(true);
          return;
        },
        scrollEndCallBack: (last, cur) {
          _isScrolling = false;
          Future.delayed(Duration(milliseconds: 500), () {
            if (!_isScrolling) {
              _reportVideoExposure();
            }
          });
        },
        scrollStatusCallBack: (scrollNotification) {
          if (scrollNotification is ScrollStartCallBack ||
              scrollNotification is ScrollUpdateNotification) {
            _isScrolling = true;
          }
          _scrollPixels = scrollNotification.metrics.pixels;
        },
        pageSize: videoPageSize,
        isHaveMoreData: _isHaveMoreData,
        isRefreshEnable: false,
        isShowItemLine: false,
        hasTopPadding: false,
        scrollPixels: _scrollPixels,
      ),
    );
  }

  ///创建评论回复的输入框相关widget
  Widget _buildCommentInputWidget() {
    if (_getVideoInfoDataBean == null &&
        (_listComment == null || _listComment.isEmpty)) {
      return Container();
    }
    double inputHeight;
    if (!_isShowCommentLength) {
      inputHeight = AppDimens.item_size_32;
    }
    String imgInput;
    if (_isInputFace) {
      imgInput = AppThemeUtil.getCommentInputText();
    } else {
      imgInput = AppThemeUtil.getCommentInputEmoji();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(
              vertical: AppDimens.margin_6_5, horizontal: AppDimens.margin_15),
          decoration: BoxDecoration(
            color: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_ffffff,
              darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.30),
                offset: Offset(0, 0),
                blurRadius: 4,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                  child: Container(
                height: inputHeight,
                constraints: BoxConstraints(
                  maxHeight: AppDimens.item_size_87,
                ),
                child: TextField(
                  onChanged: (str) {
                    commentChange(str);
                  },
                  controller: _textController,
                  focusNode: _focusNode,
                  readOnly: _isInputFace,
                  style: TextStyle(
                    color: AppThemeUtil.setDifferentModeColor(
                      lightColor: AppColors.color_333333,
                      darkColorStr:
                          DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                    ),
                    fontSize: AppDimens.text_size_12,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    fillColor: AppThemeUtil.setDifferentModeColor(
                      lightColor: AppColors.color_ebebeb,
                      darkColorStr: "333333",
                    ),
                    filled: true,
                    hintStyle: TextStyle(
                      color: AppThemeUtil.setDifferentModeColor(
                        lightColor: AppColors.color_a0a0a0,
                        darkColorStr:
                            DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                      ),
                      fontSize: AppDimens.text_size_12,
                    ),
                    hintText: _commentSendType ==
                            CommentSendType.commentSendTypeNormal
                        ? InternationalLocalizations.videoCommentInputHint
                        : '${InternationalLocalizations.videoCommentReply} @$_commentName：',
                    contentPadding: EdgeInsets.only(
                        left: AppDimens.margin_10,
                        top: AppDimens.margin_6_5,
                        bottom: AppDimens.margin_6_5),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.color_transparent),
                      borderRadius:
                          BorderRadius.circular(AppDimens.radius_size_15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.color_3674ff),
                      borderRadius:
                          BorderRadius.circular(AppDimens.radius_size_15),
                    ),
                  ),
                ),
              )),
              InkWell(
                onTap: () {
                  if (Common.isAbleClick()) {
                    setState(() {
                      _isInputFace = !_isInputFace;
                      _selectCategory = null;
                      if (!_isInputFace) {
                        FocusScope.of(context).requestFocus(_focusNode);
                      }
                    });
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(left: AppDimens.margin_10),
                  padding: EdgeInsets.all(AppDimens.margin_5),
                  child: Image.asset(imgInput),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: AppDimens.margin_5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Offstage(
                      offstage: !_isShowCommentLength,
                      child: Container(
                        margin: EdgeInsets.only(right: AppDimens.margin_5),
                        child: Text(
                          '$_superfluousLength',
                          style: AppStyles.text_style_c20a0a_12,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (Common.isAbleClick()) {
                          String id;
                          if (_commentSendType ==
                              CommentSendType.commentSendTypeNormal) {
                            id = _getVideoInfoDataBean?.id ?? '';
                          } else {
                            id = _commentId ?? '';
                          }
                          _checkAbleVideoComment(
                              id,
                              _getVideoInfoDataBean?.id ?? '',
                              Constant?.uid ?? '');
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
              )
            ],
          ),
        ),
        Offstage(
          offstage: !_isInputFace,
          child: EmojiPicker(
            rows: 5,
            columns: 10,
            bgColor: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_f3f3f3,
              darkColor: AppColors.color_3e3e3e,
            ),
            buttonMode: ButtonMode.MATERIAL,
            categoryIcons: CategoryIcons(
                epamoji: Image.asset('assets/images/ic_face_voepa.png')),
            level: _exclusiveRelationItemBean?.level ??
                ExclusiveRelationItemBean.levelLock,
            selectedCategory: _selectCategory,
            onEmojiSelected: (emoji, category) {
              CosLogUtil.log('$tag $category $emoji');
              _textController.text = _textController.text + emoji.emoji;
              commentChange(_textController.text);
            },
            onSelectCategoryChange: (selectedCategory) {
              _selectCategory = selectedCategory;
            },
          ),
        )
      ],
    );
  }

  /// 处理输入框文字变化
  void commentChange(String str) {
    if (str != null && str.trim().isNotEmpty) {
      if (str.trim().length > commentMaxLength) {
        setState(() {
          _superfluousLength = commentMaxLength - str.trim().length;
          if (_isAbleSendMsg) {
            _isAbleSendMsg = false;
          }
          if (!_isShowCommentLength) {
            _isShowCommentLength = true;
          }
        });
      } else {
        setState(() {
          if (!_isAbleSendMsg) {
            _isAbleSendMsg = true;
          }
          if (_isShowCommentLength) {
            _isShowCommentLength = false;
          }
        });
      }
    } else {
      if (_isAbleSendMsg) {
        setState(() {
          _isAbleSendMsg = false;
        });
      }
      if (_isShowCommentLength) {
        setState(() {
          _isShowCommentLength = false;
        });
      }
    }
  }

  int _getTotalItemCount() {
    int count = 1; //评论tab
    if (_listComment != null && _listComment.isNotEmpty) {
      count += _listComment.length;
    }
    count += 1;
    if (_listData != null && _listData.isNotEmpty) {
      count += _listData.length;
    }
    return count;
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
      _getVideoInfoDataBean.votepower = val.toStringAsFixed(0);
      initTotalRevenue();
    }
  }

  void _addVoterPowerToComment(CommentListItemBean bean) {
    if (bean != null) {
      Decimal val = Decimal.parse(bean.votepower);
      val += _getUserMaxPower();
      bean.votepower = val.toStringAsFixed(0);
    }
  }

  List<int> _getVisibleItemIndex() {
    List<int> idxList = [];
    _visibleFractionMap.forEach((int key, double val) {
      if (val > 0) {
        idxList.add(key);
      }
    });
    return idxList;
  }

  //视频曝光上报
  void _reportVideoExposure() {
    if (_listRelate == null || _listRelate.isEmpty) {
      return;
    }
    List<int> visibleList = _getVisibleItemIndex();
    if (visibleList.isNotEmpty) {
      for (int i = 0; i < visibleList.length; i++) {
        int idx = visibleList[i];
        if (idx >= 0 && idx < _listRelate.length) {
          RelateListItemBean bean = _listRelate[idx];
          VideoReportUtil.reportVideoExposure(
              VideoExposureType.VideoDetailType, bean.id ?? '', bean.uid ?? '');
        }
      }
    }
  }

  void _handleAutoPlaySwitch(bool isOpen) {
    if (Common.judgeHasLogIn()) {
      _doUpdateAutoPlaySetting(isOpen);
    } else {
      //没有登录先登录
      Navigator.of(context).push(SlideAnimationRoute(
        builder: (_) {
          return WebViewPage(Constant.logInWebViewUrl);
        },
      )).then((isSuccess) async {
        if (isSuccess != null && isSuccess) {
          if (!mounted) {
            return;
          }
          //登录成功,判断用户是否已经打开了自动播放的开关
          setState(() {
            _isNetIng = true;
          });
          SettingData settingData = await _loadUserSettingInfo(false);
          if (settingData == null) {
            //获取失败,则当修改失败处理因为不知道具体状态
            ToastUtil.showToast(
              InternationalLocalizations.networkErrorTips,
            );
          } else {
            bool isOpenStatus = _processUserSetting(settingData);
            if (isOpenStatus != isOpen) {
              _doUpdateAutoPlaySetting(isOpen);
            }
          }
          setState(() {
            _isNetIng = false;
          });
        } else {
          _updateAutoPlaySwitchValue(!isOpen);
        }
      });
    }
  }

  ///上报是否自动播放配置到服务端
  Future<void> _doUpdateAutoPlaySetting(bool val) async {
    _updateAutoPlaySwitchEnableStatus(false);
    if (!_isNetIng && mounted) {
      setState(() {
        _isNetIng = true;
      });
    }
    bool res = await _updateAutoPlaySetting(val);
    if (!mounted) {
      return;
    }
    if (!res) {
      //将开关变回修改之前的状态
      _updateAutoPlaySwitchValue(!val);
      ToastUtil.showToast(
        InternationalLocalizations.networkErrorTips,
      );
    } else {
      usrAutoPlaySetting = val;
      EventBusHelp.getInstance().fire(AutoPlaySwitchEvent(_pageFlag, val));
    }
    if (_isNetIng) {
      setState(() {
        _isNetIng = false;
      });
    }
    _updateAutoPlaySwitchEnableStatus(true);
  }

  Future<bool> _getAutoPlaySettingFromLocal() async {
    bool isEqual = true;
    bool isOpen = await UserUtil.getUserAutoPlaySetting(Constant.uid);
    if (isOpen != usrAutoPlaySetting) {
      usrAutoPlaySetting = isOpen;
      isEqual = false;
    }
    return isEqual;
  }

  void _updateAutoPlaySwitchEnableStatus(bool enable) {
    if (_autoPlaySwitchKey != null && _autoPlaySwitchKey.currentState != null) {
      _autoPlaySwitchKey.currentState.updateSwitchEnableStatus(enable);
    }
  }

  void _updateAutoPlaySwitchValue(bool val) {
    if (_autoPlaySwitchKey != null && _autoPlaySwitchKey.currentState != null) {
      _autoPlaySwitchKey.currentState.updateValue(val);
    }
  }

  void _hideAutoPlayFunctionDesc() {
    if (_autoPlaySwitchKey != null && _autoPlaySwitchKey.currentState != null) {
      _autoPlaySwitchKey.currentState.updateFunctionDescShowingStatus(false);
    }
  }

  void _updatePlayerControlInfo() {
    VideoDetailDataMgr.instance.updateCurrentVideoDetailDataByKey(
        _pageFlag, _getVideoInfoDataBean, _listData);
    EventBusHelp.getInstance().fire(VideoDetailDataChangeEvent(
      _pageFlag,
      _getVideoInfoDataBean,
      _listData,
      false,
    ));
  }

  void _resetPlayerControlInfo() {
    VideoDetailDataMgr.instance
        .updateCurrentVideoDetailDataByKey(_pageFlag, null, []);
    EventBusHelp.getInstance().fire(VideoDetailDataChangeEvent(
      _pageFlag,
      null,
      [],
      true,
    ));
  }

  Future<void> _handlePlayNextVideo(RelateListItemBean relateListItem,
      VideoDetailsEnterSource enterSource) async {
    if (relateListItem != null) {
      if (!_isNetIng) {
        _forwardVideoCount += 1;
        VideoDetailDataMgr.instance.updateLoadStatuesByKey(_pageFlag, true);
        _resetPlayerControlInfo();
        bool isCachedNextVideo = false;
        VideoDetailAllDataBean cachedNextVideoInfo =
            VideoDetailDataMgr.instance.getCachedNextVideoDataByKey(_pageFlag);
        if (cachedNextVideoInfo != null &&
            cachedNextVideoInfo.videoDetailsBean != null) {
          if (_listData != null && _listData.isNotEmpty) {
            RelateListItemBean recVideo = _listData[0];
            String recVid = recVideo?.id ?? "";
            String cachedVid = cachedNextVideoInfo
                ?.videoDetailsBean?.data?.videoGetVideoInfo?.id;
            if (cachedVid == recVid) {
              isCachedNextVideo = true;
            }
          }
        }
        VideoDetailPageParamsBean oldBean =
            _copyPageParamsBean(_videoDetailPageParamsBean);
        VideoDetailDataMgr.instance
            .pushPreVideoPageParamsByKey(_pageFlag, oldBean);
        _resetPageData();
        _videoDetailPageParamsBean.setVid = relateListItem?.id ?? '';
        _videoDetailPageParamsBean.setUid = relateListItem.uid ?? '';
        _videoDetailPageParamsBean.setVideoSource = relateListItem.videosource;
        _videoDetailPageParamsBean.setEnterSource = enterSource;
        _handelReplaceVideoSource(cachedNextVideoInfo, isCachedNextVideo,
            relateListItem?.videosource);
      }
    }
  }

  Future<void> _handlePlayPreVideo() async {
    if (!_isNetIng) {
      if (!VideoDetailDataMgr.instance.getHasPreVideo(_pageFlag)) {
        return;
      }
      VideoPlayerValue playerValue = _videoPlayerController?.value;
      if (playerValue != null) {
        reportVideoEnd(playerValue);
      }
      if (_forwardVideoCount > 1) {
        _forwardVideoCount--;
      }
      VideoDetailPageParamsBean pageParamsBean =
          VideoDetailDataMgr.instance.popPreVideoPageParamsByKey(_pageFlag);
      if (pageParamsBean == null) {
        return;
      }
      VideoDetailDataMgr.instance.updateLoadStatuesByKey(_pageFlag, true);
      _resetPlayerControlInfo();
      _resetPageData();
      _videoDetailPageParamsBean = pageParamsBean;
      _handelReplaceVideoSource(null, false, pageParamsBean?.getVideoSource);
    }
  }

  VideoDetailPageParamsBean _copyPageParamsBean(
      VideoDetailPageParamsBean origin) {
    if (origin != null) {
      VideoDetailPageParamsBean bean = VideoDetailPageParamsBean();
      bean.setVid = origin.getVid;
      bean.setUid = origin.getUid;
      bean.setVideoSource = origin.getVideoSource;
      bean.setEnterSource = origin.getEnterSource;
      return bean;
    }
    return null;
  }

  void _resetPageData() {
    _refreshingVid = '';
    VideoDetailDataMgr.instance.updateCachedNextVideoInfoByKey(_pageFlag, null);
    VideoDetailDataMgr.instance
        .updateFollowingRecommendVideoByKey(_pageFlag, []);
    VideoDetailDataMgr.instance.updateFollowStatusByKey(_pageFlag, false);
    _isFollow = false;
    _hasReportedVideoPlay = false;
    _autoPlayWhenBack = false;
    _isScrolling = false;
    _isRotatedTitle = false;
    _isRotatedMoney = false;
    _isBuffering = null;
    _bufferStartTime = -1;
    VideoDetailDataMgr.instance.updateCurrentVideoParamsBeanByKey(
        _pageFlag, _videoDetailPageParamsBean);
    if (_listData != null && _listData.isNotEmpty) {
      _listData.clear();
    }
    if (_listComment != null && _listComment.isNotEmpty) {
      _listComment.clear();
    }
    _commentListDataBean = null;
    _listRelate = [];
    _linkCount = 0;
    _videoPage = 1;
    _commentPage = 1;
    _getVideoInfoDataBean = null;
    _commentTypeCurrent = CommentType.commentTypeHot;
    _videoSettlementBean = VideoSettlementBean();
    _videoGiftInfoDataBean = null;
    _integralUserInfoDataBean = null;
    _isGetVideoPop = false;
    _lastPlayerPosition = Duration.zero;
    _currentPlayerPosition = Duration.zero;
    _visibleFractionMap = {};
    _timeFormatUtil = TimeFormatUtil();
    _commentSendType = CommentSendType.commentSendTypeNormal;
    _commentId = "";
    _commentName = "";
    _uid = "";
    _isVideoLike = false;
    _isVideoReportLoading = false;
    _popReward = popRewardHot;
    if (_timerUtil != null) {
      _timerUtil.cancel();
      _timerUtil = null;
    }
    _initTimeUtil();
    _openCommentChildrenParameterBean = null;
  }

  Future<void> _handelReplaceVideoSource(
      VideoDetailAllDataBean cachedNextVideoInfo,
      bool isCachedNextVideo,
      String videoSource) async {
    final oldPlayerController = _videoPlayerController;
    final oldChewieController = _chewieController;
    oldPlayerController?.removeListener(videoPlayerChanged);
    bool isFullScreen = _chewieController?.isFullScreen ?? false;
    _videoPlayerController = null;
    _chewieController = null;
    oldPlayerController?.pause();

    if (!isCachedNextVideo) {
      _isInitFinish = false;
      _isNetIng = true;
      _isHideVideoMsg = true;
      _isLoadMoreComment = false;
      _isHaveMoreData = false;
      _isAbleSendMsg = false;
      _isFirstLoad = true;
      _isHaveMoreData = false;
      _loadVideoDetailsInfo();
      _loadUserSettingInfo(true);
      _loadFollowingRecommendVideo(
          _videoDetailPageParamsBean.getUid, _videoDetailPageParamsBean.getVid);
    } else {
      _isInitFinish = true;
      _isNetIng = false;
      _isFirstLoad = false;
      bool isVideoSuccess = false,
          isRelateListSuc = false,
          isCommentListSuc = false;
      isVideoSuccess =
          _processVideoDetailsInfoByData(cachedNextVideoInfo.videoDetailsBean);
      isRelateListSuc = _processVideoRelateListByData(
          cachedNextVideoInfo.recommendListBean, false);
      isCommentListSuc = _processVideoCommentListByData(
          cachedNextVideoInfo.commentListDataBean, false, true);
      VideoDetailDataMgr.instance
          .updateCachedNextVideoInfoByKey(_pageFlag, null);
      initTotalRevenue();
      if (isVideoSuccess && isRelateListSuc && isCommentListSuc) {
        _reportPageAllDataLoadSuccess();
      }
      setState(() {});
      if (Common.judgeHasLogIn()) {
        _httpAddWatchHistory();
      }
      _loadFollowingRecommendVideo(_videoDetailPageParamsBean?.getUid,
          _videoDetailPageParamsBean?.getVid);
      if (_judgeIsNeedLoadNextPageData(
          _videoDetailPageParamsBean?.getVid ?? '')) {
        _httpVideoRelateList(true);
      }
    }
    await _initVideoPlayers(videoSource ?? '', isFullScreen, null);
    _updatePlayerControlInfo();
    if (isFullScreen) {
      Future.delayed(Duration(milliseconds: 500), () {
        VideoDetailDataMgr.instance.updateLoadStatuesByKey(_pageFlag, false);
      });
    } else {
      VideoDetailDataMgr.instance.updateLoadStatuesByKey(_pageFlag, false);
    }

    Future.delayed(Duration(seconds: 3), () {
      oldPlayerController?.dispose();
      oldChewieController?.dispose();
    });
  }

  void _handleCurVideoPlayEnd() {
    _bufferStartTime = -1;
    if (usrAutoPlaySetting && ((_listData?.isNotEmpty) ?? false)) {
      RelateListItemBean recVideo = _listData[0];
      VideoDetailPageParamsBean nextVideoParams =
          VideoDetailPageParamsBean.createInstance(
              vid: recVideo.id ?? "", uid: recVideo?.uid ?? "");
      String curVid = _videoDetailPageParamsBean?.getVid ?? "";
      VideoDetailAllDataBean cachedVideoInfo =
          VideoDetailDataMgr.instance.getCachedNextVideoDataByKey(_pageFlag);
      if (cachedVideoInfo == null) {
        //没有缓存下一个视频,提前请求接口拉取下一个视频的数据
        advanceLoadNextVideoInfo(curVid, nextVideoParams);
        return;
      }
      RelateListItemBean nextRecVideoInfo = _listData[0];
      String nextVid = nextRecVideoInfo?.id ?? "";
      if (TextUtil.isEmpty(nextVid)) {
        CosLogUtil.log(
            "AutoPlay: next video id is empty when advance fetch next video info");
        return;
      }

      String cachedVid =
          cachedVideoInfo?.videoDetailsBean?.data?.videoGetVideoInfo?.id ?? "";

      if (TextUtil.isEmpty(cachedVid) || cachedVid != nextVid) {
        VideoDetailDataMgr.instance
            .updateCachedNextVideoInfoByKey(_pageFlag, null);
        advanceLoadNextVideoInfo(curVid, nextVideoParams);
      }
    }
  }

  void advanceLoadNextVideoInfo(
      String curVid, VideoDetailPageParamsBean nextVideoInfo) {
    if (nextVideoInfo == null ||
        !Common.checkIsNotEmptyStr(nextVideoInfo.getVid)) {
      return;
    }
    Future.wait([
      RequestManager.instance.getVideoDetailsInfo(
        tag,
        nextVideoInfo?.getVid ?? '',
        Common.getCurrencyMoneyByLanguage(),
        uid: Constant.uid ?? '',
        fuid: nextVideoInfo?.getUid ?? '',
      ),
      RequestManager.instance.videoRelateList(tag, nextVideoInfo?.getVid ?? '',
          page: _videoPage.toString(), pageSize: videoPageSize.toString()),
      RequestManager.instance.videoCommentListNew(
          tag, nextVideoInfo?.getVid ?? '', _commentPage, commentPageSize,
          uid: Constant.uid ?? '',
          orderBy: VideoCommentListResponse.orderByHot),
    ]).then((listResponse) {
      if (listResponse == null || !mounted) {
        return;
      }
      CosVideoDetailsBean videoDetailsBean;
      CommentListBean commentListDataBean;
      RelateListBean recommendListBean;
      bool isVideoInfoSuccess = false,
          isRelateListSuc = false,
          isCommentListSuc = false;
      //视频详情相关数据
      if (listResponse.length >= 1) {
        if (listResponse[0] == null) {
          return;
        }
        CosVideoDetailsBean bean =
            CosVideoDetailsBean.fromJson(json.decode(listResponse[0].data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          String vid = bean?.data?.videoGetVideoInfo?.id ?? "";
          if (TextUtil.isEmpty(vid)) {
            return;
          }
          if (curVid != (_videoDetailPageParamsBean?.getVid ?? "")) {
            return;
          }
          videoDetailsBean = bean;
          isVideoInfoSuccess = true;
        } else {
          return;
        }
      }
      //视频推荐列表
      if (listResponse.length >= 2) {
        if (listResponse[1] != null) {
          RelateListBean relateListBean =
              RelateListBean.fromJson(json.decode(listResponse[1].data));
          if (relateListBean.status == SimpleResponse.statusStrSuccess) {
            isRelateListSuc = true;
            recommendListBean = relateListBean;
          }
        }
      }
      //评论列表
      if (listResponse.length >= 3) {
        if (listResponse[2] != null) {
          CommentListBean commentListBean =
              CommentListBean.fromJson(json.decode(listResponse[2].data));
          if (commentListBean.status == SimpleResponse.statusStrSuccess) {
            isCommentListSuc = true;
            commentListDataBean = commentListBean;
          }
        }
      }
      if (isVideoInfoSuccess && isRelateListSuc && isCommentListSuc) {
        VideoDetailAllDataBean videoDetailAllDataBean = VideoDetailAllDataBean(
            videoDetailsBean, commentListDataBean, recommendListBean);
        VideoDetailDataMgr.instance
            .updateCachedNextVideoInfoByKey(_pageFlag, videoDetailAllDataBean);
      }
    }).catchError((err) {
      CosLogUtil.log("AutoPlay: advance load next "
          "vid:${nextVideoInfo?.getVid ?? ""} exception, the error is $err");
    }).whenComplete(() {});
  }

  String _getEnterSourcePageName() {
    if (_videoDetailPageParamsBean.getEnterSource == null) {
      return "misc";
    }
    VideoDetailsEnterSource enterSource =
        _videoDetailPageParamsBean.getEnterSource;
    if (enterSource == VideoDetailsEnterSource.VideoDetailsEnterSourceHome) {
      return "home";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceHot) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceSubscription) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceWatchHistory) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceWatchHistoryList) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceUserLikedList) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceSearch) {
      return "search";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceTopicGame) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceTopicFun) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceTopicCutePet) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceTopicMusic) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceH5LikeRewardVideo) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceH5WorksOrDynamic) {
      return "video_list";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceOtherCenter) {
      return "channel";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceVideoRecommend) {
      return "video_recommend";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceAutoPlay) {
      return "video_autoplay";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceEndRecommend) {
      return "video_ended_recommend";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceNotification) {
      return "notification";
    } else if (enterSource ==
        VideoDetailsEnterSource.VideoDetailsEnterSourceVideoSmallWindows) {
      return "video_small_windows";
    }
    return "misc";
  }

  Future<void> _refreshRecommendVideoInfo(String vid) async {
    if (!Common.checkIsNotEmptyStr(vid)) {
      return;
    }
    if (!mounted) {
      return;
    }
    if (vid != (_videoDetailPageParamsBean?.getVid ?? "")) {
      return;
    }
    if (Common.checkIsNotEmptyStr(_refreshingVid) && _refreshingVid == vid) {
      return;
    }
    _refreshingVid = vid;
    setState(() {
      _isNetIng = true;
    });
    RequestManager.instance
        .videoRelateList(tag, vid ?? '',
            page: "1", pageSize: videoPageSize.toString())
        .then((response) {
      if (response != null) {
        if (mounted) {
          if (vid == (_videoDetailPageParamsBean?.getVid ?? "") &&
              _listData != null &&
              _listData.isEmpty) {
            RelateListBean bean =
                RelateListBean.fromJson(json.decode(response.data));
            bool result = _processVideoRelateListByData(bean, false);
            if (result) {
              EventBusHelp.getInstance()
                  .fire(RefreshRecommendVideoFinishEvent(_pageFlag, true));
            } else {
              EventBusHelp.getInstance()
                  .fire(RefreshRecommendVideoFinishEvent(_pageFlag, false));
            }
          }
        }
        setState(() {
          _isNetIng = false;
        });
      }
    }).catchError((err) {
      CosLogUtil.log("refreshRecommendVideoInfo: fail to refresh vid:$vid's "
          "recommend video, the error is $err");
      if (vid == (_videoDetailPageParamsBean?.getVid ?? "")) {
        EventBusHelp.getInstance()
            .fire(RefreshRecommendVideoFinishEvent(_pageFlag, false));
      }
    }).whenComplete(() {
      _refreshingVid = '';
    });
  }

  bool _judgeIsNeedLoadNextPageData(String vid) {
    String curVid = _getVideoId();
    if ((_listData == null || _listData.length < videoPageSize) &&
        _isHaveMoreData &&
        curVid == vid) {
      return true;
    }
    return false;
  }
}
