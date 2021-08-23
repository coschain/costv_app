import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/setting_switch_event.dart';
import 'package:costv_android/event/tab_switch_event.dart';
import 'package:costv_android/event/video_small_show_status_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/hot/hot_topic_detail.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_long_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/video_report_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/page_title_widget.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:costv_android/widget/single_video_item.dart';
import 'package:flutter/material.dart';

class PopularPage extends StatefulWidget {
  PopularPage({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _PopularPageState createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage> with RouteAware {
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey =
      GlobalKey<NetRequestFailTipsViewState>();
  static const tag = '_PopularPageState';
  final logPrefix = "HotPage";
  int _pageSize = 20, _curPage = 1;
  bool _hasNextPage = false,
      _isFetching = false,
      _isLoading = true,
      _isSuccessLoad = true,
      _tmpHasMore = false,
      _isScrolling = false;
  double videoItemHeight = 0;
  List<GetVideoListNewDataListBean> _videoList = [];
  List<HotTopicModel> _hotList = [];
  Map<String, String> _historyVideoMap = new Map();
  ExchangeRateInfoData _rateInfo;
  dynamic_properties _chainDgpo;
  String _operateVid = '';
  List<String> tmpOpVid = [];
  int videoItemIdx = 0, topicListHeight = 0;
  int latestIdx = 0;
  Map<int, GlobalObjectKey<SingleVideoItemState>> keyMap = {};
  GlobalObjectKey<HotTopicListViewState> _topicListKey =
      GlobalObjectKey<HotTopicListViewState>("topicList");
  GlobalObjectKey<RefreshAndLoadMoreListViewState> _listViewKey =
      GlobalObjectKey<RefreshAndLoadMoreListViewState>("hotListView");
  var itemRectKeyMap = {};
  Map<int, double> itemHeightMap = {};
  StreamSubscription _eventHot;
  Map<int, double> _visibleFractionMap = {};

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _cancelListenEvent();
    super.dispose();
  }

  @override
  void initState() {
    _loadTopicData();
    _reloadHotData();
    _listenEvent();
    super.initState();
  }

  @override
  void didUpdateWidget(PopularPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void didPushNext() {
    super.didPushNext();
    EventBusHelp.getInstance().fire(VideoSmallShowStatusEvent(false));
  }

  @override
  void didPopNext() {
    super.didPopNext();
    EventBusHelp.getInstance().fire(VideoSmallShowStatusEvent(true));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: _getHotPageBody(),
      ),
    );
  }

  Widget _getHotPageBody() {
    if (!_isSuccessLoad) {
      return LoadingView(
        isShow: _isLoading,
        child: PageRemindWidget(
          remindType: RemindType.NetRequestFail,
          clickCallBack: () {
            _isLoading = true;
            _reloadHotData();
            setState(() {});
          },
        ),
      );
    }
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: AppThemeUtil.setDifferentModeColor(
        lightColor: AppColors.color_f6f6f6,
        darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
      ),
      child: Column(
        children: <Widget>[
          //顶部搜索
          _getSearchWidget(),
          Expanded(
            child: LoadingView(
              child: NetRequestFailTipsView(
                key: _failTipsKey,
                baseWidget: RefreshAndLoadMoreListView(
                  key: _listViewKey,
                  hasTopPadding: false,
                  itemCount: _getTotalItemCount(),
                  itemBuilder: (context, index) {
                    bool hasHotList = _judgeHasHotListData();
                    if (index == 0 && hasHotList) {
                      //热门主题列表
                      return HotTopicListView(
                        key: _topicListKey,
                        topicList: _hotList,
                        topicCallBack: (model) {
//                          _stopPlayVideo();
                        },
                      );
                    }
                    int idx = hasHotList ? index - 1 : index;
                    if (!_isScrolling) {
                      _visibleFractionMap[idx] = 1;
                    }
                    latestIdx = idx;
                    // 视频列表
                    return _getSingleVideoItem(idx);
                  },
                  isHaveMoreData: _hasNextPage,
                  isRefreshEnable: true,
                  isLoadMoreEnable: true,
                  bottomMessage: InternationalLocalizations.moMoreHotData,
                  onRefresh: _reloadHotData,
                  pageSize: _pageSize,
                  onLoadMore: () {
                    _loadNextPageData();
                  },
                  scrollEndCallBack: (last, cur) {
//                    _handelAutoPlay(cur);
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
                  },
                ),
              ),
              isShow: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取ListView的item个数
  int _getTotalItemCount() {
    int cnt = 1; //顶部热门列表第一期写死,所以至少有热门列表的item
    if (_videoList != null && _videoList.length > 0) {
      cnt += _videoList.length;
    }
    return cnt;
  }

  Widget _getSearchWidget() {
    return Container(
      color: AppThemeUtil.setDifferentModeColor(
        lightColorStr: "FFFFFFFF",
        darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr
      ),
      child: PageTitleWidget(tag),
    );
  }

  /// 获取video item
  SingleVideoItem _getSingleVideoItem(int idx) {
    int vListCnt = _videoList?.length ?? 0;
    if (idx >= 0 && idx < vListCnt) {
      GetVideoListNewDataListBean video = _videoList[idx];
//      GlobalObjectKey<SingleVideoItemState> myKey = new GlobalObjectKey<SingleVideoItemState>(video.id);
//      keyMap[idx] = myKey;
      SingleVideoItem item = SingleVideoItem(
//        key: myKey,
        videoData: video,
        exchangeRate: _rateInfo,
        dgpoBean: _chainDgpo,
        index: idx,
        playVideoCallBack: (video) {
//          _stopPlayVideo();
        },
        source: EnterSource.HotPage,
        visibilityChangedCallback: (int index, double visibleFraction) {
          if (_visibleFractionMap == null) {
            _visibleFractionMap = {};
          }
          _visibleFractionMap[index] = visibleFraction;
        },
      );
      return item;
    }
    return SingleVideoItem();
  }

  /// 是否有热门列表数据
  bool _judgeHasHotListData() {
    int num = _hotList?.length ?? 0;
    return num > 0;
  }

  Future<void> _loadNextPageData() async {
    if (_isFetching) {
      CosLogUtil.log("$logPrefix: is fething data when load next page data");
      return;
    }
    _isFetching = true;
    await _loadHotVideoList(true);
    _isFetching = false;
  }

  void _loadTopicData() {
    ///第一版写死顶部热门主题
    //游戏
    _hotList.add(HotTopicModel(
        topicType: HotTopicType.TopicGame,
        desc: InternationalLocalizations.hotTopicGame,
        bgPath: 'assets/images/ic_hot_game.png'));
    //有趣
    _hotList.add(HotTopicModel(
        topicType: HotTopicType.TopicFun,
        desc: InternationalLocalizations.hotTopicFun,
        bgPath: 'assets/images/ic_hot_fun.png'));
    //萌宠
    _hotList.add(HotTopicModel(
        topicType: HotTopicType.TopicCutePets,
        desc: InternationalLocalizations.hotTopicCutePets,
        bgPath: 'assets/images/ic_hot_cute_pets.png'));
    //音乐
    _hotList.add(HotTopicModel(
        topicType: HotTopicType.TopicMusic,
        desc: InternationalLocalizations.hotTopicMusic,
        bgPath: 'assets/images/ic_hot_music.png'));
  }

  ///重新拉取第一页的数据
  Future<void> _reloadHotData() async {
    if (_isFetching) {
      CosLogUtil.log("$logPrefix: is fething data when reload");
      return;
    }
    _isFetching = true;
    bool isNeedLoadRate = (_rateInfo == null) ? true : false;
    Iterable<Future> reqList;
    if (isNeedLoadRate) {
      reqList = [
        _loadHotVideoList(false),
        VideoUtil.requestExchangeRate(tag),
        CosSdkUtil.instance.getChainState()
      ];
    } else {
      reqList = [_loadHotVideoList(false), CosSdkUtil.instance.getChainState()];
    }
    await Future.wait(reqList).then((resList) {
      if (resList != null && mounted) {
        int resLen = resList.length;
        List<GetVideoListNewDataListBean> videoList;
        ExchangeRateInfoData rateData = _rateInfo;
        dynamic_properties dgpo = _chainDgpo;
        if (resLen >= 1) {
          videoList = resList[0];
        }
        if (isNeedLoadRate && resLen >= 2) {
          rateData = resList[1];
          if (rateData != null) {
            _rateInfo = rateData;
          }
        }

        if (resLen >= 3) {
          GetChainStateResponse bean = resList[2];
          if (bean != null && bean.state != null && bean.state.dgpo != null) {
            dgpo = bean.state.dgpo;
            _chainDgpo = dgpo;
          }
        }
        CosLongLogUtil.log(
            '$tag _reloadHotData() videoList = ${videoList?.toString()}');
        CosLongLogUtil.log(
            '$tag _reloadHotData() rateData = ${rateData?.toString()}');
        CosLongLogUtil.log('$tag _reloadHotData() dgpo = ${dgpo?.toString()}');
        if (videoList != null) {
          _videoList = videoList;
          _curPage = 1;
          VideoUtil.clearHistoryVidMap(_historyVideoMap);
          VideoUtil.addNewVidToHistoryVidMapFromList(
              videoList, _historyVideoMap);
          _getOperateVid(tmpOpVid);
          _isFetching = false;
          _isLoading = false;
          _isSuccessLoad = true;
          _hasNextPage = _tmpHasMore;
          keyMap.clear();
          setState(() {
//            if (curTabIndex == 1) {
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
        } else if (_isLoading && _isSuccessLoad) {
          _isSuccessLoad = false;
        } else {
          _showLoadFailTips();
        }
      } else if (mounted &&
          resList == null &&
          !VideoUtil.checkVideoListIsNotEmpty(_videoList)) {
        _isSuccessLoad = false;
      }
    }).catchError((err) {
      CosLogUtil.log("$logPrefix: fail to reload data, the error is $err");
      if (_isLoading &&
          _isSuccessLoad &&
          !VideoUtil.checkVideoListIsNotEmpty(_videoList)) {
        _isSuccessLoad = false;
      } else {
        _showLoadFailTips();
      }
    }).whenComplete(() {
      _isFetching = false;
      if (mounted && _isLoading) {
        _isLoading = false;
        setState(() {});
      }
    });
  }

  ///获取热门视频数据
  Future<List<GetVideoListNewDataListBean>> _loadHotVideoList(
      bool isNextPage) async {
    List<GetVideoListNewDataListBean> list;
    if (isNextPage && !_hasNextPage) {
      return _videoList;
    }
    int page = isNextPage ? _curPage + 1 : 1;
    String lan = Common.getRequestLanCodeByLanguage(false);
    //使用like_num并且按降序排序和前端保持一致
    await RequestManager.instance
        .getVideoListNew("",
            language: lan,
            page: page.toString(),
            pageSize: _pageSize.toString(),
            platform: '4',
            sort: 'like_num',
            orderBy: 'desc',
            operateVid: isNextPage ? _operateVid : '')
        .then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("$logPrefix: fail to request hot video list");
        list = null;
        return;
      }
      GetVideoListNewBean bean =
          GetVideoListNewBean.fromJson(json.decode(response.data));
      bool isSuccess = (bean.status == SimpleResponse.statusStrSuccess);
      List<GetVideoListNewDataListBean> dataList =
          isSuccess ? (bean.data?.list ?? []) : [];
      list = dataList;
      if (isSuccess) {
        _tmpHasMore = bean.data.hasNext == "1";
        if (isNextPage) {
          _hasNextPage = _tmpHasMore;
          list = VideoUtil.filterRepeatVideo(dataList, _historyVideoMap);
          if (list.isNotEmpty) {
            _videoList.addAll(list);
            VideoUtil.addNewVidToHistoryVidMapFromList(list, _historyVideoMap);
            _curPage = page;
          }
          setState(() {});
        } else {
          tmpOpVid = bean.data?.operateVids ?? [];
//          _getOperateVid(bean.data?.operateVids);
        }
      } else {
        CosLogUtil.log(
            "$logPrefix: fail to request hot video list of page:$page, "
            "the error msg is ${bean.message}, "
            "error code is ${bean.status}");
        list = null;
      }
    }).catchError((err) {
      CosLogUtil.log("$logPrefix: fail to load hot video list of page:$page, "
          "the error is $err");
      list = null;
    }).whenComplete(() {});
    return list;
  }

  /// 获取operate_vid
  void _getOperateVid(List<String> strList) {
    _operateVid = VideoUtil.parseOperationVid(strList);
  }

  void _showLoadFailTips() {
    if (_failTipsKey.currentState != null) {
      _failTipsKey.currentState.showWithAnimation();
    }
  }

//  void _handelAutoPlay(double position) {
//    if (_videoList == null || _videoList.length < 1) {
//      return;
//    }
//    int idx = 0;
//    if (_topicListKey != null && _topicListKey.currentContext != null) {
//      topicListHeight = (_topicListKey.currentContext.size.height).floor();
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
//    if (position > topicListHeight) {
//      double val = ((position - topicListHeight) / videoItemHeight);
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

  ///监听消息
  void _listenEvent() {
    if (_eventHot == null) {
      _eventHot = EventBusHelp.getInstance().on().listen((event) {
        if (event != null) {
          if (event is TabSwitchEvent) {
            if (event.from == BottomTabType.TabHot.index) {
              if (event.from == event.to &&
                  _listViewKey != null &&
                  _listViewKey.currentState != null) {
                _listViewKey.currentState.scrollToTop();
              }
            }
            if (event.from == 1) {
//              _stopPlayVideo(false);
            } else if (event.to == 1) {
              //上报点击热门内容
              DataReportUtil.instance.reportData(
                  eventName: "Click_hot", params: {"Click_hot": "1"});
//              _autoPlayVideoOfIndex(videoItemIdx);
            }
          } else if (event is SettingSwitchEvent) {
            SettingModel setting = event.setting;
            if (setting.isEnvSwitched || (setting.oldLan != setting.newLan)) {
              _clearData();
              if (_hotList != null && _hotList.isNotEmpty) {
                _hotList.clear();
                _loadTopicData();
              }
              _reloadHotData();
              setState(() {});
            }
          }
        }
      });
    }
  }

  ///取消监听消息事件
  void _cancelListenEvent() {
    if (_eventHot != null) {
      _eventHot.cancel();
    }
  }

  void _clearData() {
    if (_videoList != null && _videoList.isNotEmpty) {
      _videoList.clear();
    }
    _hasNextPage = false;
    _isFetching = false;
    _isLoading = true;
    _isSuccessLoad = true;
    _tmpHasMore = false;
    videoItemHeight = 0;
    videoItemIdx = 0;
    topicListHeight = 0;
    latestIdx = 0;
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
    if (_videoList == null || _videoList.isEmpty) {
      return;
    }
    List<int> visibleList = _getVisibleItemIndex();
    if (visibleList.isNotEmpty) {
      for (int i = 0; i < visibleList.length; i++) {
        int idx = visibleList[i];
        if (idx >= 0 && idx < _videoList.length) {
          GetVideoListNewDataListBean bean = _videoList[idx];
          VideoReportUtil.reportVideoExposure(
              VideoExposureType.HotPageType, bean.id ?? '', bean.uid ?? '');
        }
      }
    }
  }
}

typedef ClickTopicCallBack = Function(HotTopicModel topic);

/*
 topic list item
 */
class SingleTopicItem extends StatefulWidget {
  final HotTopicModel topic;
  final double bgWidth;
  final ExchangeRateInfoData rateInfo;
  final ClickTopicCallBack clickTopicCallBack;

  SingleTopicItem(
      {this.topic, this.bgWidth, this.rateInfo, this.clickTopicCallBack});

  @override
  State<StatefulWidget> createState() => _SingleTopicItemState();
}

class _SingleTopicItemState extends State<SingleTopicItem> {
  @override
  Widget build(BuildContext context) {
    double avatarWidth = 50.0;
    return Container(
      padding: EdgeInsets.all(8),
//        height: 65,
      width: widget.bgWidth,
      color: AppThemeUtil.setDifferentModeColor(
        lightColorStr: "FFFFFFFF",
        lightAlpha: 0.01,
        darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
    ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          color: AppThemeUtil.setDifferentModeColor(
            lightColorStr: "FFFFFFFF",
            darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
          ),
          child: InkWell(
            onTap: () {
              _reportTopicClickEvent();
              _jumpToTopicDetail(widget.topic);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                //avatar
                ClipOval(
                    child: SizedBox(
                      width: avatarWidth,
                      height: avatarWidth,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Image.asset(widget.topic?.bgPath ?? ""),
                          _getMask(),
                        ],
                      )

                    )
                ),

                //desc
                Container(
                  margin: EdgeInsets.only(top: 4),
//                    width: avatarWidth,
                  child: Text(
                    widget.topic?.desc ?? "",
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppThemeUtil.setDifferentModeColor(
                        lightColor: Common.getColorFromHexString("333333", 1.0),
                        darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                      ),
                      fontSize: 11,
                      inherit: false,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getMask() {
    if (AppThemeUtil.checkIsDarkMode()) {
      return Container(
        color: Common.getColorFromHexString("1D1D1D", 0.3),
      );
    }
    return Container();
  }

  void _jumpToTopicDetail(HotTopicModel topic) {
    if (topic == null) {
      CosLogUtil.log(
          "HotPage: can't jump to topic detail page due to uid is empty");
      return;
    }
    if (widget.clickTopicCallBack != null) {
      widget.clickTopicCallBack(widget.topic);
    }
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return HotTopicDetailPage(
          topicModel: widget.topic,
          rateInfo: widget.rateInfo,
        );
      },
    ));
  }

  //埋点上报
  void _reportTopicClickEvent() {
    if (widget.topic != null) {
      String eventName = "";
      Map<String, dynamic> params = {};
      if (widget.topic.topicType == HotTopicType.TopicGame) {
        eventName = "Click_game";
        params["Click_game"] = "1";
      } else if (widget.topic.topicType == HotTopicType.TopicFun) {
        eventName = "Click_fun";
        params["Click_fun"] = "1";
      } else if (widget.topic.topicType == HotTopicType.TopicCutePets) {
        eventName = "Click_pet";
        params["Click_pet"] = "1";
      } else if (widget.topic.topicType == HotTopicType.TopicMusic) {
        eventName = "Click_music";
        params["Click_music"] = "1";
      }
      DataReportUtil.instance.reportData(eventName: eventName, params: params);
    }
  }
}

/// 顶部热门标签列表
class HotTopicListView extends StatefulWidget {
  final List<HotTopicModel> topicList;
  final ClickTopicCallBack topicCallBack;

  HotTopicListView({Key key, this.topicList, this.topicCallBack})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return HotTopicListViewState();
  }
}

class HotTopicListViewState extends State<HotTopicListView> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.margin_10),
      width: screenWidth,
      decoration: BoxDecoration(
        color: AppThemeUtil.setDifferentModeColor(
          lightColorStr: "FFFFFFFF",
          darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
        ),
        border: Border(
          top: BorderSide(
              color: AppThemeUtil.setDifferentModeColor(
                lightColor:Common.getColorFromHexString("EBEBEB", 1),
                darkColorStr: "3E3E3E",
              ),
              width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: screenWidth,
            child: Row(
              children: _getTopicList(),
            ),
          ),
        ],
//        children: <Widget>[
//          Container(
//            width: screenWidth,
//            height: contentHeight,
//            child:  ListView.builder(
//                scrollDirection: Axis.horizontal,
//                physics: NeverScrollableScrollPhysics(),
//                itemCount: widget.topicList?.length ?? 0,
//                itemBuilder: (BuildContext context, int index) {
//                  return _getTopicItem(index);
//                }),
//          ),
//
//        ],
      ),
    );
  }

  SingleTopicItem _getTopicItem(int index) {
    int listCnt = widget.topicList?.length ?? 0;
    if (index >= 0 && index < listCnt) {
      return SingleTopicItem(
        topic: widget.topicList[index],
        bgWidth: MediaQuery.of(context).size.width / listCnt,
      );
    }
    return SingleTopicItem();
  }

  List<SingleTopicItem> _getTopicList() {
    List<SingleTopicItem> list = [];
    int listCnt = widget.topicList?.length ?? 0;
    for (var topic in widget.topicList) {
      list.add(SingleTopicItem(
        topic: topic,
        bgWidth: MediaQuery.of(context).size.width / listCnt,
        clickTopicCallBack: widget.topicCallBack,
      ));
    }
    return list;
  }
}
