import 'dart:async';
import 'dart:convert';

import 'package:cosdart/types.dart';
import 'package:costv_android/bean/app_update_version_bean.dart';
import 'package:costv_android/bean/cos_banner_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/dialog/app_update_dialog.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/setting_switch_event.dart';
import 'package:costv_android/event/tab_switch_event.dart';
import 'package:costv_android/event/video_small_show_status_event.dart';
import 'package:costv_android/event/video_small_windows_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/overlay/overlay_video_small_windows_utils.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/banner_util.dart';
import 'package:costv_android/utils/black_list_util.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/platform_util.dart';
import 'package:costv_android/utils/video_report_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/widget/cos_banner.widget.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/page_title_widget.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:costv_android/widget/single_video_item.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

const homeLogPrefix = "HomePage";
const reportResKey = "result";
const reportFinalResKey = "finalResult";
const reportErrKey = "errMsg";
const reportExtraErrKey = "extraErr";
const homeAPIEvent = "homeStatistics";
const bannerEventKey = "banner";
const chainStateEventKey = "chainState";
const rateEventKey = "rate";
const videoListEventKey = "videoList";
const bannerNumKey = "bannerNum";
const videoNumKey = "videoNum";
const chainStateNullKey = "isChainStateNull";
const rateNullKey = "isRateNull";
const bannerNullKey = "isBannerNull";
const videoNullKey = "isVideoNull";
const loadTimeKey = "loadTime";
const apiLoadEvent = "loadStatistics";
const apiLoadAllEvent = "allLoadStatistics";
const pageKey = "page";

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey =
      new GlobalKey<NetRequestFailTipsViewState>();
  GlobalObjectKey<CosBannerWidgetState> _bannerListKey =
      GlobalObjectKey<CosBannerWidgetState>("bannerList");
  GlobalObjectKey<RefreshAndLoadMoreListViewState> _homeListViewKey =
      GlobalObjectKey<RefreshAndLoadMoreListViewState>("homeListView");
  static const tag = '_HomePageState';
  static const int adFirstFlag = 3;
  static const int adInsertFlag = 5;
  static const int itemTypeAd = 1;
  int _pageSize = 20, _curPage = 1;
  bool _hasNextPage = false,
      _isFetching = false,
      _isShowLoading = true,
      _isSuccessLoad = true,
      tmpHasMore = false,
      _isFirstLoad = true,
      _isScrolling = false;
  List<dynamic> _videoList = [];
  List<CosBannerData> _bannerList = [];
  ExchangeRateInfoData _rateInfo;
  dynamic_properties _chainDgpo;
  static const platformUpdate =
      const MethodChannel('com.contentos.plugin/update');
  double videoItemHeight = 0;
  Map<int, GlobalObjectKey<SingleVideoItemState>> keyMap = {};
  int videoItemIdx = 0, bannerListHeight = 0;
  int latestIdx = 0;
  StreamSubscription _eventHome;
  Map<String, dynamic> _bannerResMap = {reportResKey: "1"};
  Map<String, dynamic> _rateResMap = {reportResKey: "1"};
  Map<String, dynamic> _chainStateResMap = {reportResKey: "1"};
  Map<String, dynamic> _videoListResMap = {reportResKey: "1"};
  Map<int, double> _visibleFractionMap = {};
  int _currentPlayIdx = -1;

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _cancelListenEvent();
    super.dispose();
  }

  @override
  void didPushNext() {
    super.didPushNext();
    EventBusHelp.getInstance().fire(VideoSmallShowStatusEvent(false));
    if (curTabIndex == BottomTabType.TabHome.index) {
      _stopPlayVideo();
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    EventBusHelp.getInstance().fire(VideoSmallShowStatusEvent(true));
    if (!_judgeSmallVideoIsShowing()) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          _startPlayVideo();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _reloadData();
    _httpAppUpdateVersion();
    _listenEvent();
  }

  /// 软件更新
  void _httpAppUpdateVersion() {
    RequestManager.instance.appUpdateAppVersion(tag).then((response) async {
      if (response == null || !mounted) {
        return;
      }
      AppUpdateVersionBean bean =
          AppUpdateVersionBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess && bean.data != null) {
        String version = await PlatformUtil.getVersion();
        if (Common.isUpdate(version, bean.data.vercode ?? '0.0.0')) {
          AppUpdateDialog dialog = AppUpdateDialog();
          await dialog.initData(bean.data);
          dialog.showAppUpdateDialog(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _getHomePageBody();
  }

  Widget _getHomePageBody() {
    if (_isSuccessLoad) {
      return Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: AppColors.color_f6f6f6,
            darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
        child: LoadingView(
          isShow: _isShowLoading,
          child: Column(
            children: <Widget>[
              Container(
                color: AppThemeUtil.setDifferentModeColor(
                    lightColorStr: "FFFFFF",
                    darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
                child: PageTitleWidget(tag),
              ),
              Expanded(
                child: NetRequestFailTipsView(
                  key: _failTipsKey,
                  baseWidget: RefreshAndLoadMoreListView(
                    key: _homeListViewKey,
                    hasTopPadding: false,
                    isRefreshEnable: true,
                    isLoadMoreEnable: true,
                    isHaveMoreData: _hasNextPage,
                    bottomMessage:
                        InternationalLocalizations.noMoreOperateVideo,
                    itemCount: _getTotalItemCount(),
                    itemBuilder: (context, index) {
                      bool hasBanner = _checkHasBanner();
                      int totalCnt = _getTotalItemCount();
                      if (index == 0 && hasBanner) {
                        return CosBannerWidget(
                          key: _bannerListKey,
                          dataList: _bannerList,
                          clickCallBack: _onClickBanner,
                          hasBottomSeparate: totalCnt > 1 ? true : false,
                        );
                      }
                      int idx = hasBanner ? index - 1 : index;
//                      if (!_isScrolling) {
//                        _visibleFractionMap[idx] = 1;
//                      }
                      latestIdx = idx >= 2 ? idx - 2 : 0;
                      return _getVideoItem(idx);
                    },
                    onRefresh: _reloadData,
                    onLoadMore: _loadNextPageData,
                    scrollEndCallBack: (last, cur) {
//                      _handelAutoPlay(cur);
                      _isScrolling = false;
//                      _stopPlayVideo();
                      Future.delayed(Duration(milliseconds: 500), () {
                        if (!_isScrolling) {
                          int curIndex = _getFirstCompletelyVisibleItemIndex();
                          if (_currentPlayIdx >= 0 &&
                              curIndex >= 0 &&
                              curIndex != _currentPlayIdx) {
                            _stopPlayVideoByIndex(_currentPlayIdx);
                          }

                          if (!_judgeSmallVideoIsShowing()) {
                            _startPlayVideo();
                          }
                          _reportVideoExposure();
                        }
                      });
                    },
                    scrollStatusCallBack: (scrollNotification) {
                      if (scrollNotification is ScrollStartNotification ||
                          scrollNotification is ScrollUpdateNotification) {
//                        _stopPlayVideo();
                        _isScrolling = true;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return LoadingView(
        isShow: _isShowLoading,
        child: PageRemindWidget(
          clickCallBack: () {
            _isShowLoading = true;
            _reloadData();
            setState(() {});
          },
          remindType: RemindType.NetRequestFail,
        ),
      );
    }
  }

  double _getItemWidth() {
    double itemWidth = MediaQuery.of(context).size.width - 20;
    return itemWidth;
  }

  double _getCoverHeight() {
    double itemWidth = _getItemWidth();
    double imgRatio = 9 / 16;
    double imgHeight = imgRatio * itemWidth;
    return imgHeight;
  }

  void filterListByBlack(){
    List<dynamic> resultList = [];
    for (var item in _videoList) {
      if (item is GetVideoListNewDataListBean ){
        GetVideoListNewDataListBean video = item;
        if (BlackListUtil().IsBlackUser(video.uid)){
          continue;
        } else if ( BlackListUtil().IsBlackVideo(video.id)){
          continue;
        }
      }
      resultList.add(item);
    }
    _videoList = resultList;
  }

  Widget _getVideoItem(int idx) {
    int listCnt = _videoList?.length ?? 0;
    if (idx >= 0 && idx < listCnt) {
      if (_videoList[idx] is GetVideoListNewDataListBean) {
        GetVideoListNewDataListBean video = _videoList[idx];
        GlobalObjectKey<SingleVideoItemState> myKey =
            GlobalObjectKey<SingleVideoItemState>(video.id);
        keyMap[idx] = myKey;
        bool isNeedAutoPlay = false;
        if (!_judgeSmallVideoIsShowing() && idx == 0) {
          isNeedAutoPlay = true;
        }
        return SingleVideoItem(
          key: myKey,
          videoData: video,
          exchangeRate: _rateInfo,
          dgpoBean: _chainDgpo,
          source: EnterSource.HomePage,
          index: idx,
          visibilityChangedCallback: (int index, double visibleFraction) {
            if (_visibleFractionMap == null) {
              _visibleFractionMap = {};
            }
            _visibleFractionMap[index] = visibleFraction;
            if (index > -1 &&
                index == _currentPlayIdx &&
                visibleFraction < 1.0) {
              _currentPlayIdx = -1;
            }
          },
          isNeedAutoPlay: isNeedAutoPlay,
          isNeedMoreAction: true,
          playVideoCallBack: (GetVideoListNewDataListBean video) {},
          blockCallBack: (int action){
            if (action == 0){
              BlackListUtil.instance.AddVideoIdToBlackList(video.id);
              filterListByBlack();
              setState(() {});
            } else if (action == 1){
              BlackListUtil.instance.AddUserIdToBlackList(video.uid);
              filterListByBlack();
              setState(() {});
            }
          },
        );
      } else if (_videoList[idx] == itemTypeAd) {
        if(Platform.isIOS){
          return Container();
        }
        return Container(
          margin: EdgeInsets.only(
              left: AppDimens.margin_10,
              right: AppDimens.margin_10,
              bottom: AppDimens.margin_10),
          child: FacebookNativeAd(
            placementId: Constant.facebookPlacementId,
            adType: NativeAdType.NATIVE_AD,
            width: _getItemWidth(),
            height: _getCoverHeight(),
            backgroundColor: AppThemeUtil.setDifferentModeColor(
                lightColor: AppColors.color_ffffff,
                darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
            titleColor: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_333333,
              darkColorStr: DarkModelTextColorUtil
                  .firstLevelBrightnessColorStr,
            ),
            descriptionColor: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_333333,
              darkColorStr: DarkModelTextColorUtil
                  .firstLevelBrightnessColorStr,
            ),
            buttonColor: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_3674ff,
              darkColor: AppColors.color_285ed8,
            ),
            buttonTitleColor: AppColors.color_ffffff,
            keepAlive: true,
            listener: (result, value) {
              CosLogUtil.log("Native Ad: $result --> $value");
            },
          ),
        );
      } else {
        return SingleVideoItem();
      }
    }
    return SingleVideoItem();
  }

  ///重新拉取首页数据
  Future<void> _reloadData() async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    bool isNeedLoadRate = (_rateInfo == null) ? true : false;
    Iterable<Future> reqList;
    if (isNeedLoadRate) {
      reqList = [
        _loadBannerList(),
        _loadOperationVideoList(false),
        CosSdkUtil.instance.getChainState(
            fallCallBack: _handleChainStateFailCallBack,
            loadTimeCallBack: _handleChainStateLoadTimeCallBack),
        VideoUtil.requestExchangeRate(tag,
            failCallBack: _handleGetRateFailCallBack,
            loadTimeCallBack: _handleGetRateLoadTime)
      ];
    } else {
      reqList = [
        _loadBannerList(),
        _loadOperationVideoList(false),
        CosSdkUtil.instance
            .getChainState(fallCallBack: _handleChainStateFailCallBack)
      ];
    }
    int sTimeStamp = DateTime.now().millisecondsSinceEpoch;
    await Future.wait(reqList).then((resList) {
      if (resList != null && mounted) {
        int resLen = resList.length ?? 0;
        List<CosBannerData> bannerList;
        List<GetVideoListNewDataListBean> videoList;
        ExchangeRateInfoData rateData = _rateInfo;
        dynamic_properties dgpo = _chainDgpo;
        bool isLBannerSuccess = false, isVideoSuccess = false;
        if (resLen >= 1) {
          bannerList = resList[0];
        }

        if (resLen >= 2) {
          videoList = resList[1];
        }
        if (resLen >= 3) {
          GetChainStateResponse bean = resList[2];
          if (bean != null && bean.state != null && bean.state.dgpo != null) {
            dgpo = bean.state.dgpo;
            _chainDgpo = dgpo;
          }
        }

        if (isNeedLoadRate && resLen >= 4) {
          rateData = resList[3];
          if (rateData != null) {
            _rateInfo = rateData;
          }
        }

        if (bannerList != null) {
          isLBannerSuccess = true;
          _bannerList = bannerList;
          if (bannerList.length < 1) {
            bannerListHeight = 0;
          }
        }

        if (videoList != null) {
          isVideoSuccess = true;
          _videoList.clear();
          if (videoList.isNotEmpty) {
            List<List<GetVideoListNewDataListBean>> listData =
                Common.splitList(videoList, adInsertFlag, adFirstFlag);
            listData.forEach((listVideoBean) {
              _videoList.addAll(listVideoBean);
              _videoList.add(itemTypeAd);
            });
            filterListByBlack();
          } else {
            _videoList = [];
          }
          _curPage = 1;
          keyMap.clear();
          _hasNextPage = tmpHasMore;
        }

        if (isLBannerSuccess || isVideoSuccess) {
          //banner或是视频列表任意一个拉取成功都刷新并显示

          Map<String, dynamic> resMap = _getAPIResultMap();
          resMap[bannerNumKey] = bannerList?.length ?? 0;
          resMap[videoNumKey] = videoList?.length ?? 0;
          if (_isFirstLoad) {
            DataReportUtil.instance
                .reportData(eventName: homeAPIEvent, params: resMap);
          }
          int eTimeStamp = DateTime.now().millisecondsSinceEpoch;
          int loadTime = eTimeStamp - sTimeStamp;
          resMap[loadTimeKey] = loadTime;
          DataReportUtil.instance
              .reportData(eventName: apiLoadAllEvent, params: resMap);
          _isFetching = false;
          _isShowLoading = false;
          _isSuccessLoad = true;
          if (_judgeIsNeedLoadNextPageData()) {
            _loadNextPageData();
          }
          setState(() {
//            if (curTabIndex == 0 && videoList.length > 0) {
//              Future.delayed(Duration(milliseconds: 500), () {
//                _handelAutoPlay(0);
//              });
//            }
            Future.delayed(Duration(seconds: 1), () {
              if (!_isScrolling) {
                _reportVideoExposure();
              }
            });
          });
        } else {
          //banner和视频列表都拉取失败
          if (_isShowLoading && _isSuccessLoad) {
            _isSuccessLoad = false;
          } else {
            _showNetRequestFailTips();
          }

          String errStr = "fail to load data exception";
          Map<String, dynamic> resMap = _getAPIResultMap();
          resMap[reportFinalResKey] = "0";
          resMap[reportExtraErrKey] = errStr;
          resMap[chainStateNullKey] = dgpo == null ? "1" : "0";
          resMap[rateNullKey] = rateData == null ? "1" : "0";
          resMap[bannerNullKey] = bannerList == null ? "1" : "0";
          resMap[videoNullKey] = videoList == null ? "1" : "0";
          if (_isFirstLoad) {
            DataReportUtil.instance
                .reportData(eventName: homeAPIEvent, params: resMap);
          }
          int eTimeStamp = DateTime.now().millisecondsSinceEpoch;
          int loadTime = eTimeStamp - sTimeStamp;
          resMap[loadTimeKey] = loadTime;
          DataReportUtil.instance
              .reportData(eventName: apiLoadAllEvent, params: resMap);
        }
      } else if (mounted &&
          resList == null &&
          _isShowLoading &&
          _isSuccessLoad &&
          !_checkHasBanner() &&
          !VideoUtil.checkVideoListIsNotEmpty(_videoList)) {
        _isSuccessLoad = false;

        String errStr = "resList is empty";
        Map<String, dynamic> resMap = _getAPIResultMap();
        resMap[reportFinalResKey] = "0";
        resMap[reportExtraErrKey] = errStr;
        if (_isFirstLoad) {
          DataReportUtil.instance
              .reportData(eventName: homeAPIEvent, params: resMap);
        }
        int eTimeStamp = DateTime.now().millisecondsSinceEpoch;
        int loadTime = eTimeStamp - sTimeStamp;
        resMap[loadTimeKey] = loadTime;
        DataReportUtil.instance
            .reportData(eventName: apiLoadAllEvent, params: resMap);
      }
    }).catchError((err) {
      CosLogUtil.log(
          "$homeLogPrefix: fail to get reload data, the error is $err");
      if (_isShowLoading &&
          _isSuccessLoad &&
          !_checkHasBanner() &&
          !VideoUtil.checkVideoListIsNotEmpty(_videoList)) {
        _isSuccessLoad = false;
      } else {
        _showNetRequestFailTips();
      }
      String errStr = "load data exception: the error is $err";
      Map<String, dynamic> resMap = _getAPIResultMap();
      resMap[reportFinalResKey] = "0";
      resMap[reportExtraErrKey] = errStr;
      if (_isFirstLoad) {
        DataReportUtil.instance
            .reportData(eventName: homeAPIEvent, params: resMap);
      }
      int eTimeStamp = DateTime.now().millisecondsSinceEpoch;
      int loadTime = eTimeStamp - sTimeStamp;
      resMap[loadTimeKey] = loadTime;
      DataReportUtil.instance
          .reportData(eventName: apiLoadAllEvent, params: resMap);
    }).whenComplete(() {
      _isFetching = false;
      _isFirstLoad = false;
      if (mounted && _isShowLoading) {
        _isShowLoading = false;
        setState(() {});
      }
    });
    _reportChainStateLoadTime();
    _reportExchangeRateLoadTime();
  }

  Map<String, dynamic> _getAPIResultMap() {
    Map<String, dynamic> resMap = {};
    resMap[bannerEventKey] = _bannerResMap.toString() ?? {};
    resMap[chainStateEventKey] = _chainStateResMap.toString() ?? {};
    resMap[rateEventKey] = _rateResMap.toString() ?? {};
    resMap[videoListEventKey] = _videoListResMap.toString() ?? {};
    resMap[reportFinalResKey] = "1";
    return resMap;
  }

  void _handleChainStateFailCallBack(String error) {
    if (_isFirstLoad) {
      _chainStateResMap[reportResKey] = "0";
      _chainStateResMap[reportErrKey] = error ?? "";
    }
  }

  void _handleChainStateLoadTimeCallBack(int milliseconds) {
    _chainStateResMap[loadTimeKey] = milliseconds.toString() ?? "-1";
  }

  void _handleGetRateFailCallBack(String error) {
    if (_isFirstLoad) {
      _rateResMap[reportResKey] = "0";
      _rateResMap[reportErrKey] = error ?? "";
    }
  }

  void _handleGetRateLoadTime(int milliseconds) {
    _rateResMap[loadTimeKey] = milliseconds?.toString() ?? "-1";
  }

  ///拉取下页视频数据
  Future<void> _loadNextPageData() async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    await _loadOperationVideoList(true);
    _isFetching = false;
  }

  ///获取视频列表
  Future<List<dynamic>> _loadOperationVideoList(bool isNextPage) async {
    List<GetVideoListNewDataListBean> list;
    if (isNextPage && !_hasNextPage) {
      return _videoList;
    }
    int page = isNextPage ? _curPage + 1 : 1;
    String lan = Common.getRequestLanCodeByLanguage(true);
    int sTimeStamp = DateTime.now().millisecondsSinceEpoch;
    await RequestManager.instance
        .getOperationList(tag, lan, page.toString(), _pageSize.toString())
        .then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("$homeLogPrefix: fail to request operation video list");
        list = null;
        if (_isFirstLoad) {
          _videoListResMap[reportResKey] = "0";
          String errDesc = "";
          if (response == null) {
            errDesc += "load video list response is null";
          }
          if (!mounted) {
            errDesc += "load video list, home page is not mounted";
          }
          _videoListResMap[reportErrKey] = errDesc;
        }
        return;
      }
      GetVideoListNewBean bean =
          GetVideoListNewBean.fromJson(json.decode(response.data));
      bool isSuccess = (bean.status == SimpleResponse.statusStrSuccess);
      List<GetVideoListNewDataListBean> dataList =
          isSuccess ? (bean.data?.list ?? []) : [];
      list = dataList;
      if (isSuccess) {
        tmpHasMore = bean.data.hasNext == "1";
        if (isNextPage) {
          _hasNextPage = tmpHasMore;
          _curPage = page;
          if (dataList.isNotEmpty) {
            List<List<GetVideoListNewDataListBean>> listData =
                Common.splitList(dataList, adInsertFlag);
            listData.forEach((listVideoBean) {
              _videoList.addAll(dataList);
              _videoList.add(itemTypeAd);
            });
            filterListByBlack();
            list = _videoList;
          }
          setState(() {});
        }
      } else {
        CosLogUtil.log(
            "$homeLogPrefix: fail to request operation video list of page:$page, the error msg is ${bean.message}, "
            "error code is ${bean.status}");
        list = null;
        if (_isFirstLoad) {
          _videoListResMap[reportResKey] = "0";
          _videoListResMap[reportErrKey] =
              "code:${bean.status ?? ''}" + "msg:${bean.message ?? ''}";
        }
      }
    }).catchError((err) {
      CosLogUtil.log(
          "$homeLogPrefix: fail to load operation video list of,the error is $err");
      list = null;
      if (_isFirstLoad) {
        _videoListResMap[reportResKey] = "0";
        _videoListResMap[reportErrKey] =
            "load video list exception: the error is $err";
      }
    }).whenComplete(() {
      if (_judgeIsNeedLoadNextPageData()) {
        _loadNextPageData();
      }
    });
    int eTimeStamp = DateTime.now().millisecondsSinceEpoch;
    _videoListResMap[loadTimeKey] = eTimeStamp - sTimeStamp;
    Map<String, dynamic> videoResMap = {};
    videoResMap[videoListEventKey] = _videoListResMap.toString() ?? "";
    videoResMap[pageKey] = page.toString();
    DataReportUtil.instance
        .reportData(eventName: apiLoadEvent, params: videoResMap);
    return list;
  }

  ///获取banner列表数据
  Future<List<CosBannerData>> _loadBannerList() async {
    List<CosBannerData> bannerList;
    String lan = Common.getRequestLanCodeByLanguage(true);
    int sTimeStamp = DateTime.now().millisecondsSinceEpoch;
    await RequestManager.instance
        .getBannerList(tag, language: lan)
        .then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("$homeLogPrefix: fail to request banner list");
        bannerList = null;
        String errDesc = "";
        if (response == null) {
          errDesc += "load banner response is null";
        }
        if (!mounted) {
          errDesc += "page is not mounted";
        }
        if (_isFirstLoad) {
          _bannerResMap[reportResKey] = "0";
          _bannerResMap[reportErrKey] = errDesc;
        }
        return;
      }
      CosBannerBean bean = CosBannerBean.fromJson(json.decode(response.data));
      bool isSuccess = (bean.status == SimpleResponse.statusStrSuccess);
      List<CosBannerData> dataList = isSuccess ? (bean.data ?? []) : [];
      if (isSuccess) {
//        setState(() {
//          _bannerList = dataList;
//        });
        bannerList = dataList;
      } else {
        CosLogUtil.log(
            "$homeLogPrefix: fail to load banner list,the error msg is ${bean.msg}, "
            "error code is ${bean.status}");
        bannerList = null;
        if (_isFirstLoad) {
          _bannerResMap[reportResKey] = "0";
          _bannerResMap[reportErrKey] =
              "code:${bean.status ?? ''}" + "msg:${bean.msg ?? ''}";
        }
      }
    }).catchError((err) {
      CosLogUtil.log(
          "$homeLogPrefix: fail to request banner list of,the error is $err");
      bannerList = null;
      if (_isFirstLoad) {
        _bannerResMap[reportResKey] = "0";
        _bannerResMap[reportErrKey] =
            "load banner exception: the error is $err";
      }
    }).whenComplete(() {});
    int eTimeStamp = DateTime.now().millisecondsSinceEpoch;
    _bannerResMap[loadTimeKey] = eTimeStamp - sTimeStamp;
    Map<String, dynamic> bannerResMap = {};
    bannerResMap[bannerEventKey] = _bannerResMap.toString() ?? "";
    DataReportUtil.instance
        .reportData(eventName: apiLoadEvent, params: bannerResMap);
    return bannerList;
  }

  ///检查是否有banner数据
  bool _checkHasBanner() {
    if (_bannerList != null && _bannerList.isNotEmpty) {
      return true;
    }
    return false;
  }

  ///获取listView的总的item数量
  int _getTotalItemCount() {
    int cnt = 0;
    if (_checkHasBanner()) {
      cnt += 1;
    }
    if (_videoList != null && _videoList.length > 0) {
      cnt += _videoList.length;
    }
    return cnt;
  }

  ///监听消息
  void _listenEvent() {
    if (_eventHome == null) {
      _eventHome = EventBusHelp.getInstance().on().listen((event) {
        if (event != null) {
          if (event is TabSwitchEvent) {
            if (event.from == BottomTabType.TabHome.index) {
              if (event.from == event.to &&
                  _homeListViewKey != null &&
                  _homeListViewKey.currentState != null) {
                _homeListViewKey.currentState.scrollToTop();
              } else {
                _stopPlayVideo();
              }
            } else if (event.to == BottomTabType.TabHome.index) {
              if (!_judgeSmallVideoIsShowing()) {
                //没有小窗口才重新出发自动播放
                Future.delayed(Duration(seconds: 1), () {
                  if (mounted) {
                    _startPlayVideo();
                  }
                });
              }
            }
//            if (event.from == 0) {
//              _stopPlayVideo(false);
//            } else if (event.to == 0) {
//              _autoPlayVideoOfIndex(videoItemIdx);
//            }
          } else if (event is SettingSwitchEvent) {
            SettingModel setting = event.setting;
            if (setting.isEnvSwitched || (setting.oldLan != setting.newLan)) {
              _clearData();
              _reloadData();
              setState(() {});
            }
          } else if (event is VideoSmallWindowsEvent) {
            if (event.status != null) {
              if (event.status ==
                  VideoSmallWindowsEvent.statusSmallWindowsShow) {
                _stopPlayVideo();
              } else {
                if (curTabIndex == BottomTabType.TabHome.index) {
                  if (mounted && ModalRoute.of(context).isCurrent) {
                    _startPlayVideo();
                  }
                }
              }
            }
          }
        }
      });
    }
  }

  ///取消监听消息事件
  void _cancelListenEvent() {
    if (_eventHome != null) {
      _eventHome.cancel();
    }
  }

  void _clearData() {
    if (_videoList != null && _videoList.isNotEmpty) {
      _videoList.clear();
    }
    if (_bannerList != null && _bannerList.isNotEmpty) {
      _bannerList.clear();
    }
    _hasNextPage = false;
    _isFetching = false;
    _isShowLoading = true;
    _isSuccessLoad = true;
    tmpHasMore = false;
    _currentPlayIdx = -1;
  }

  void _onClickBanner(CosBannerData data) {
    if (data != null) {
      if (data.type == BannerType.VideoType.index.toString()) {
        if (data.videoInfo == null) {
          CosLogUtil.log(
              "$homeLogPrefix: fail to handle video banner click event,video info empty");
          return;
        } else if (!Common.checkIsNotEmptyStr(data.videoInfo.id)) {
          CosLogUtil.log("$homeLogPrefix: fail to handle video banner click "
              "event,video info wrong, vid is ${data.videoInfo.id}, uid is ${Constant.uid}");
          return;
        }
        Navigator.of(context).push(
          SlideAnimationRoute(
            builder: (_) {
              return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
                vid: data.videoInfo?.id,
                uid: data.videoInfo?.uid,
                videoSource: data.videoInfo?.videosource,
                enterSource:
                    VideoDetailsEnterSource.VideoDetailsEnterSourceHome,
              ));
            },
            settings: RouteSettings(name: videoDetailPageRouteName),
            isCheckAnimation: true,
          ),
        );
      } else if (data.type == BannerType.ImageType.index.toString()) {
        if (data.linkUrl == null) {
          CosLogUtil.log(
              "$homeLogPrefix: fail to handle image banner click event,link url empty");
          return;
        }
        Navigator.of(context).push(SlideAnimationRoute(
          builder: (_) {
            return WebViewPage(data.linkUrl);
          },
        ));
      }
    } else {
      CosLogUtil.log(
          "$homeLogPrefix: fail to handle banner click event, banner info empty");
    }
  }

  void _showNetRequestFailTips() {
    if (_failTipsKey.currentState != null) {
      _failTipsKey.currentState.showWithAnimation();
    }
  }

//  void _handelAutoPlay(double position) {
//    if (_videoList == null || _videoList.length < 1) {
//      return;
//    }
//    int idx = 0;
//    if (_bannerListKey != null && _bannerListKey.currentContext != null) {
//      bannerListHeight = (_bannerListKey.currentContext.size.height).floor();
//    }
//    double itemHeight = 0;
//    if (keyMap != null && keyMap.containsKey(latestIdx) && keyMap[latestIdx].currentContext != null) {
//      itemHeight = keyMap[latestIdx].currentContext.size.height;
//      if (itemHeight >= videoItemHeight) {
//        videoItemHeight = itemHeight;
//      }
//    }
//    if (videoItemHeight <= 0 ) {
//      return;
//    }
//    if (position > bannerListHeight) {
//      double val = ((position - bannerListHeight) / videoItemHeight);
//      int index = val.ceil();
//      idx = index;
//    } else {
//      idx = 0;
//    }
//    _autoPlayVideoOfIndex(idx);
//  }
//
//  void _autoPlayVideoOfIndex(int idx) {
//    VideoUtil.autoPlayVideoOfIndex(idx, videoItemIdx, keyMap);
//    if (idx != videoItemIdx) {
//      videoItemIdx = idx;
//    }
//  }
//
  void _stopPlayVideo() {
    if (_videoList != null && _videoList.length > 0) {
      int visibleIdx = _getFirstCompletelyVisibleItemIndex();
      if (visibleIdx >= 0 && keyMap.containsKey(visibleIdx)) {
        var itemKey = keyMap[visibleIdx];
        if (itemKey != null && itemKey.currentState != null) {
          itemKey.currentState.stopPlay();
        }
      }
    }
  }

  void _stopPlayVideoByIndex(int idx) {
    if (idx >= 0 &&
        _videoList != null &&
        _videoList.length > 0 &&
        idx < _videoList.length) {
      if (keyMap.containsKey(idx)) {
        var itemKey = keyMap[idx];
        if (itemKey != null && itemKey.currentState != null) {
          itemKey.currentState.stopPlay();
        }
      }
    }
  }

  void _startPlayVideo() {
//    if (!NetWorkUtil.instance.checkIsWifi()) {
//      //wifi 情况下才播放
//      return;
//    }
    if (_judgeSmallVideoIsShowing()) {
      return;
    }
    if (_videoList != null && _videoList.length > 0) {
      int visibleIdx = _getFirstCompletelyVisibleItemIndex();
      _currentPlayIdx = visibleIdx;
      if (visibleIdx >= 0 && keyMap.containsKey(visibleIdx)) {
        var itemKey = keyMap[visibleIdx];
        if (itemKey != null && itemKey.currentState != null) {
          itemKey.currentState.startPlay();
        }
      }
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

  int _getFirstCompletelyVisibleItemIndex() {
    int idx = -1;
    _visibleFractionMap.forEach((int key, double val) {
      if (val >= 1.0) {
        if (idx < 0) {
          idx = key;
        } else if (key <= idx) {
          idx = key;
        }
      }
    });
    return idx;
  }

  //视频曝光上报
  void _reportVideoExposure() {
    if (_videoList == null || _videoList.isEmpty) {
      return;
    }
    List<int> visibleList = _getVisibleItemIndex();
    if (visibleList.isNotEmpty) {
      for (int i = 0; i < visibleList.length; i++) {
        int idx = visibleList[i];
        if (idx >= 0 && idx < _videoList.length) {
          if (_videoList[idx] is GetVideoListNewDataListBean) {
            GetVideoListNewDataListBean bean = _videoList[idx];
            VideoReportUtil.reportVideoExposure(
                VideoExposureType.HomePageType, bean.id ?? '', bean.uid ?? '');
          }
        }
      }
    }
  }

  bool _judgeIsNeedLoadNextPageData() {
    if ((_videoList == null || _videoList.length < _pageSize) && _hasNextPage) {
      return true;
    }
    return false;
  }

  void _reportChainStateLoadTime() {
    if (_chainStateResMap != null) {
      Map<String, dynamic> chainStateResMap = {};
      chainStateResMap[chainStateEventKey] = _chainStateResMap.toString() ?? "";
      DataReportUtil.instance
          .reportData(eventName: apiLoadEvent, params: chainStateResMap);
    }
  }

  void _reportExchangeRateLoadTime() {
    if (_rateResMap != null) {
      Map<String, dynamic> rateResMap = {};
      rateResMap[rateEventKey] = _rateResMap.toString() ?? "";
      DataReportUtil.instance
          .reportData(eventName: apiLoadEvent, params: rateResMap);
    }
  }

  bool _judgeSmallVideoIsShowing() {
    return OverlayVideoSmallWindowsUtils.instance.checkIsShowWindow();
  }
}
