import 'dart:async';
import 'dart:convert';

import 'package:costv_android/bean/app_update_version_bean.dart';
import 'package:costv_android/bean/cos_banner_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/dialog/app_update_dialog.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/tab_switch_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/banner_util.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/platform_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/widget/cos_banner.widget.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/page_title_widget.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/single_video_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:costv_android/event/setting_switch_event.dart';
import 'package:cosdart/types.dart';

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
  int _pageSize = 20, _curPage = 1;
  bool _hasNextPage = false,
      _isFetching = false,
      _isShowLoading = true,
      _isSuccessLoad = true,
      tmpHasMore = false,
      _isFirstLoad = true;
  List<GetVideoListNewDataListBean> _videoList = [];
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

//  @override
//  void didPushNext() {
//    super.didPushNext();
//    if (curTabIndex == 0) {
//      _stopPlayVideo(false);
//    }
//  }
//
//  @override
//  void didPopNext() {
//    super.didPopNext();
//    if (curTabIndex == 0) {
//      _autoPlayVideoOfIndex(videoItemIdx);
//    }
//  }

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
        color: Common.getColorFromHexString("3F3F3F", 0.05),
        child: LoadingView(
          isShow: _isShowLoading,
          child: Column(
            children: <Widget>[
              Container(
                color: Common.getColorFromHexString("FFFFFF", 1.0),
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
                      latestIdx = idx >= 2 ? idx - 2 : 0;
                      return _getVideoItem(idx);
                    },
                    onRefresh: _reloadData,
                    onLoadMore: _loadNextPageData,
//                    scrollEndCallBack: (last, cur) {
//                      _handelAutoPlay(cur);
//                    },
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

  SingleVideoItem _getVideoItem(int idx) {
    int listCnt = _videoList?.length ?? 0;
    if (idx >= 0 && idx < listCnt) {
      GetVideoListNewDataListBean video = _videoList[idx];
//      GlobalObjectKey<SingleVideoItemState> myKey = new GlobalObjectKey<SingleVideoItemState>(video.id);
//      keyMap[idx] = myKey;
      return SingleVideoItem(
//        key: myKey,
        videoData: video,
        exchangeRate: _rateInfo,
        dgpoBean: _chainDgpo,
        source: EnterSource.HomePage,
      );
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
        CosSdkUtil.instance
            .getChainState(fallCallBack: _handleChainStateFailCallBack),
        VideoUtil.requestExchangeRate(tag,
            failCallBack: _handleGetRateFailCallBack)
      ];
    } else {
      reqList = [
        _loadBannerList(),
        _loadOperationVideoList(false),
        CosSdkUtil.instance
            .getChainState(fallCallBack: _handleChainStateFailCallBack)
      ];
    }
    Future.wait(reqList).then((resList) {
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
            dgpo= bean.state.dgpo;
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
          _videoList = videoList;
          _curPage = 1;
          keyMap.clear();
          _hasNextPage = tmpHasMore;
        }

        if (isLBannerSuccess || isVideoSuccess) {
          //banner或是视频列表任意一个拉取成功都刷新并显示

          if (_isFirstLoad) {
            Map<String, dynamic> resMap = _getAPIResultMap();
            resMap[bannerNumKey] = bannerList?.length ?? 0;
            resMap[videoNumKey] = videoList?.length ?? 0;
            DataReportUtil.instance
                .reportData(eventName: homeAPIEvent, params: resMap);
          }

          _isFetching = false;
          _isShowLoading = false;
          _isSuccessLoad = true;
          setState(() {
//            if (curTabIndex == 0 && videoList.length > 0) {
//              Future.delayed(Duration(milliseconds: 500), () {
//                _handelAutoPlay(0);
//              });
//            }
          });
        } else {
          //banner和视频列表都拉取失败
          if (_isShowLoading && _isSuccessLoad) {
            _isSuccessLoad = false;
          } else {
            _showNetRequestFailTips();
          }

          if (_isFirstLoad) {
            String errStr = "fail to load data exception";
            Map<String, dynamic> resMap = _getAPIResultMap();
            resMap[reportFinalResKey] = "0";
            resMap[reportExtraErrKey] = errStr;
            resMap[chainStateNullKey] = dgpo == null ? "1" : "0";
            resMap[rateNullKey] = rateData == null ? "1" : "0";
            resMap[bannerNullKey] = bannerList == null ? "1" : "0";
            resMap[videoNullKey] = videoList == null ? "1" : "0";
            DataReportUtil.instance
                .reportData(eventName: homeAPIEvent, params: resMap);
          }
        }
      } else if (mounted &&
          resList == null &&
          _isShowLoading &&
          _isSuccessLoad &&
          !_checkHasBanner() &&
          !VideoUtil.checkVideoListIsNotEmpty(_videoList)) {
        _isSuccessLoad = false;

        if (_isFirstLoad) {
          String errStr = "resList is empty";
          Map<String, dynamic> resMap = _getAPIResultMap();
          resMap[reportFinalResKey] = "0";
          resMap[reportExtraErrKey] = errStr;
          DataReportUtil.instance
              .reportData(eventName: homeAPIEvent, params: resMap);
        }
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
      if (_isFirstLoad) {
        String errStr = "load data exception: the error is $err";
        Map<String, dynamic> resMap = _getAPIResultMap();
        resMap[reportFinalResKey] = "0";
        resMap[reportExtraErrKey] = errStr;
        DataReportUtil.instance
            .reportData(eventName: homeAPIEvent, params: resMap);
      }
    }).whenComplete(() {
      _isFetching = false;
      _isFirstLoad = false;
      if (mounted && _isShowLoading) {
        _isShowLoading = false;
        setState(() {});
      }
    });
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

  void _handleGetRateFailCallBack(String error) {
    if (_isFirstLoad) {
      _rateResMap[reportResKey] = "0";
      _rateResMap[reportErrKey] = error ?? "";
    }
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
  Future<List<GetVideoListNewDataListBean>> _loadOperationVideoList(
      bool isNextPage) async {
    List<GetVideoListNewDataListBean> list;
    if (isNextPage && !_hasNextPage) {
      return _videoList;
    }
    int page = isNextPage ? _curPage + 1 : 1;
    String lan = Common.getRequestLanCodeByLanguage(true);
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
          if (dataList.isNotEmpty) {
            _videoList.addAll(dataList);
            _curPage = page;
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
    }).whenComplete(() {});
    return list;
  }

  ///获取banner列表数据
  Future<List<CosBannerData>> _loadBannerList() async {
    List<CosBannerData> bannerList;
    String lan = Common.getRequestLanCodeByLanguage(true);
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
        Navigator.of(context).push(MaterialPageRoute(builder: (_) {
          return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
              vid: data.videoInfo?.id,
              uid: data.videoInfo?.uid,
              videoSource: data.videoInfo?.videosource));
        }));
      } else if (data.type == BannerType.ImageType.index.toString()) {
        if (data.linkUrl == null) {
          CosLogUtil.log(
              "$homeLogPrefix: fail to handle image banner click event,link url empty");
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(builder: (_) {
          return WebViewPage(data.linkUrl);
        }));
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
//  void _stopPlayVideo(bool isRestart) {
//    if (_videoList != null && _videoList.length > 0 && videoItemIdx != null) {
//      VideoUtil.stopPlayVideo(isRestart, videoItemIdx, keyMap);
//    }
//  }
}
