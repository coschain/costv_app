import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/follow_relation_list_bean.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/login_status_event.dart';
import 'package:costv_android/event/setting_switch_event.dart';
import 'package:costv_android/event/tab_switch_event.dart';
import 'package:costv_android/event/video_small_show_status_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/Follow/following_list_page.dart';
import 'package:costv_android/pages/user/others_home_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/video_report_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/utils/web_view_util.dart';
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

const String subscribeLogPrefix = "MySubScriptionPage";

class MySubscriptionPage extends StatefulWidget {
  MySubscriptionPage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _MySubscriptionPageState createState() => _MySubscriptionPageState();
}

class _MySubscriptionPageState extends State<MySubscriptionPage> with RouteAware {
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey = new GlobalKey<NetRequestFailTipsViewState>();
  static const tag = '_MySubscriptionPageState';
  int _pageSize = 20, _curPage = 1;
  bool _hasNextPage = false,
      _isFetching = false,
      _isShowLoading = true,
      _isSuccessLoad = true,
      tmpHasMore = false,
      _hasFollowing = true,
      _isFirstLoad = true,
      _isTokenErr = false,
      _isScrolling = false;
  List<FollowRelationData> _followingList = [];
  List<GetVideoListNewDataListBean> _videoList = [];
  ExchangeRateInfoData? _rateInfo;
  dynamic_properties? _chainDgpo;
  StreamSubscription? _eventSubscription;
  bool _isLoggedIn = false;
  String _uid = "";
  int videoItemIdx = 0;
  int latestIdx = 0;
  double videoItemHeight = 0, followingListHeight = 0;
  Map<int, GlobalObjectKey<SingleVideoItemState>> keyMap = {};
  GlobalObjectKey _followingListKey = GlobalObjectKey("followingList");
  GlobalObjectKey<RefreshAndLoadMoreListViewState> _subListViewKey = GlobalObjectKey<RefreshAndLoadMoreListViewState>("sbuscriptionListView");
  Map<int, double> _visibleFractionMap = {};

  @override
  void didUpdateWidget(MySubscriptionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void initState() {
    _isLoggedIn = Common.judgeHasLogIn();
    if (_isLoggedIn) {
      _uid = Constant.uid;
      _reloadData();
    }
    _listenEvent();
    super.initState();
  }

  @override
  void dispose() {
    _cancelListenEvent();
    routeObserver.unsubscribe(this);
    super.dispose();
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

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: AppThemeUtil.setDifferentModeColor(
        lightColor: Common.getColorFromHexString("F6F6F6", 1.0),
        darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
      ),
      child: _getPageBody(),
    );
  }

  Widget _getPageBody() {
    if (!_isLoggedIn) {
      //未登录提醒用户登录
      return PageRemindWidget(
        clickCallBack: _startLogIn,
        remindType: RemindType.SubscriptionPageLogIn,
      );
    } else {
      if (!_isSuccessLoad) {
        //第一次数据拉取失败
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
      } else if (!_hasFollowing) {
        //没有关注任何人
        return LoadingView(
          isShow: _isShowLoading,
          child: PageRemindWidget(
            remindType: RemindType.SubscriptionPageFollow,
          ),
        );
      }
      return LoadingView(
        isShow: _isShowLoading,
        child: Column(
          children: <Widget>[
            _getSearchWidget(),
            Expanded(
              child: NetRequestFailTipsView(
                key: _failTipsKey,
                baseWidget: RefreshAndLoadMoreListView(
                  key: _subListViewKey,
                  hasTopPadding: false,
                  pageSize: _pageSize,
                  isHaveMoreData: _hasNextPage,
                  itemCount: _getTotalItemCount(),
                  itemBuilder: (context, index) {
                    bool hasFollowData = _checkHasFollowingData();
                    if (index == 0 && hasFollowData) {
                      // following item
                      return _topFollowingListContainer();
                    }
                    int idx = hasFollowData ? index - 1 : index;
                    if (!_isScrolling) {
                      _visibleFractionMap[idx] = 1;
                    }
                    latestIdx = idx >= 2 ? idx : 0;
                    return _getVideoItem(idx);
                  },
                  onLoadMore: () {
                    _loadNextPageData();
                  },
                  onRefresh: _reloadData,
                  isShowItemLine: false,
                  bottomMessage: InternationalLocalizations.noMoreSubscribeVideo,
                  isRefreshEnable: true,
                  isLoadMoreEnable: true,
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
                    if (scrollNotification is ScrollStartCallBack || scrollNotification is ScrollUpdateNotification) {
                      _isScrolling = true;
                    }
                  },
                ),
              ),
            )
          ],
        ),
      );
    }
  }

  //top following list
  Widget _topFollowingListContainer() {
    double screenWidth = MediaQuery.of(context).size.width;
    double btnWidth = 40.0;
    return Container(
      key: _followingListKey,
      width: screenWidth,
      padding: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: AppThemeUtil.setDifferentModeColor(
                lightColor: Common.getColorFromHexString("EBEBEB", 1),
                darkColorStr: "3E3E3E",
              ),
              width: 0.5),
        ),
      ),
      child: Container(
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0), darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
//        padding: EdgeInsets.only(left: listPadding),
        width: screenWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              alignment: AlignmentDirectional.topEnd,
              children: <Widget>[
                Container(
                  width: screenWidth - btnWidth,
                  height: AppDimens.item_size_96_5,
                  color: AppThemeUtil.setDifferentModeColor(
                    lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
                    darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
                  ),
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: _followingList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _getFollowItem(index);
                      }),
                ),
                Image.asset(
                  "assets/images/img_subscription_projection.png",
                  fit: BoxFit.contain,
                ),
              ],
            ),
            //left list

            //right button
            Material(
              child: Ink(
                child: InkWell(
                  child: Container(
                    width: btnWidth,
                    height: AppDimens.item_size_96_5,
                    padding: EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: AppThemeUtil.setDifferentModeColor(lightColor: Common.getColorFromHexString("F6F6F6", 1.0), darkColorStr: "3E3E3E"),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          offset: Offset(-2, 0),
                          spreadRadius: 0,
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Align(
                      alignment: FractionalOffset.center,
                      child: IconButton(
                        icon: Image.asset(
                          AppThemeUtil.getRightIcn(),
                          fit: BoxFit.contain,
                          width: 15,
                          height: 15,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  onTap: () {
                    _jumpToUserFollowingListPage(_uid);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///登录
  void _startLogIn() {
    WebViewUtil.instance.openWebView(Constant.logInWebViewUrl, context);
  }

  SingleFollowItem _getFollowItem(int index) {
    int fListCnt = _followingList.length;
    if (index >= 0 && index < fListCnt) {
      return SingleFollowItem(
        relationData: _followingList[index],
        rateInfo: _rateInfo,
        chainDgpo: _chainDgpo,
      );
    }
    return SingleFollowItem();
  }

  Widget _getSearchWidget() {
    return Container(
      color: AppThemeUtil.setDifferentModeColor(lightColorStr: "FFFFFFFF", darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
      child: PageTitleWidget(tag),
    );
  }

  SingleVideoItem _getVideoItem(int index) {
    int vListCnt = _videoList.length;
    if (index >= 0 && index < vListCnt) {
      GetVideoListNewDataListBean video = _videoList[index];
      GlobalObjectKey<SingleVideoItemState> myKey = new GlobalObjectKey<SingleVideoItemState>(video.id);
      keyMap[index] = myKey;
      return SingleVideoItem(
        key: myKey,
        videoData: video,
        exchangeRate: _rateInfo,
        dgpoBean: _chainDgpo,
        index: index,
        source: EnterSource.SubscribePage,
        visibilityChangedCallback: (int index, double visibleFraction) {
          if (_visibleFractionMap == null) {
            _visibleFractionMap = {};
          }
          _visibleFractionMap[index] = visibleFraction;
        },
      );
    }
    return SingleVideoItem();
  }

  ///监听消息事件
  void _listenEvent() {
    if (_eventSubscription == null) {
      _eventSubscription = EventBusHelp.getInstance().on().listen((event) {
        if (event != null) {
          //登出成功
          if (event is LoginStatusEvent) {
            if (event.type == LoginStatusEvent.typeLoginSuccess) {
              if (Common.checkIsNotEmptyStr(event.uid ?? "")) {
                _uid = event.uid ?? "'";
                _isLoggedIn = true;
                _reloadData();
                setState(() {});
              } else {
                CosLogUtil.log("$subscribeLogPrefix: success log in but get empty uid");
              }
            } else if (event.type == LoginStatusEvent.typeLogoutSuccess) {
              _resetPageData();
              setState(() {});
            }
          } else if (event is TabSwitchEvent) {
            if (event.from == BottomTabType.TabSubscription.index) {
              if (event.from == event.to) {
                if (_hasFollowing) {
                  if (VideoUtil.checkVideoListIsNotEmpty(_videoList) && _subListViewKey.currentState != null) {
                    _subListViewKey.currentState?.scrollToTop();
                  }
                } else if (!_hasFollowing && _isLoggedIn && _isSuccessLoad) {
                  //没有关注任何人,点击tab刷新数据
                  _isShowLoading = true;
                  _reloadData();
                }
              }
            } else if (event.to == BottomTabType.TabSubscription.index) {
              if (!_hasFollowing && _isLoggedIn && _isSuccessLoad) {
                _isShowLoading = true;
                _reloadData();
              }
            }
//            if (event.from == 2) {
//              _stopPlayVideo(false);
//            } else if (event.to == 2) {
//              _autoPlayVideoOfIndex(videoItemIdx);
//            }
          } else if (event is SettingSwitchEvent) {
            SettingModel setting = event.setting;
            if (setting.isEnvSwitched || (setting.oldLan != setting.newLan)) {
              _resetPageData();
              if (!setting.isEnvSwitched) {
                _isLoggedIn = Common.judgeHasLogIn();
                if (_isLoggedIn) {
                  _reloadData();
                }
              }
              setState(() {});
            }
          }
        }
      });
    }
  }

  void _resetPageData() {
    _isLoggedIn = false;
    _isShowLoading = true;
    _hasNextPage = false;
    _isFetching = false;
    _isSuccessLoad = true;
    _hasFollowing = true;
    _isFirstLoad = true;
    tmpHasMore = false;
    if (_videoList.isNotEmpty) {
      _videoList.clear();
    }
    if (_followingList.isNotEmpty) {
      _followingList.clear();
    }
    if (keyMap.isNotEmpty) {
      keyMap.clear();
    }
    _curPage = 1;
    _isScrolling = false;
    if (_visibleFractionMap.isNotEmpty) {
      _visibleFractionMap.clear();
    }
  }

  ///取消监听消息事件
  void _cancelListenEvent() {
    if (_eventSubscription != null) {
      _eventSubscription?.cancel();
    }
  }

//  void _handelAutoPlay(double position) {
//    if (_videoList == null || _videoList.length < 1) {
//      return;
//    }
//    int idx = 0;
//    double followingListHeight = 0;
//    if (_followingListKey != null && _followingListKey.currentContext != null) {
//      followingListHeight = _followingListKey.currentContext.size.height;
//    }
//    double itemHeight = 0;
//    if (keyMap != null && keyMap.containsKey(latestIdx) && keyMap[latestIdx].currentContext != null) {
//      itemHeight = keyMap[latestIdx].currentContext.size.height;
//      if (itemHeight >= videoItemHeight) {
//        videoItemHeight = itemHeight;
//      }
//    }
//
//    if (videoItemHeight <= 0 ) {
//      return;
//    }
//    if (position > followingListHeight) {
//      double val = ((position - followingListHeight) / videoItemHeight);
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

  void _jumpToUserFollowingListPage(String uid) {
    if (uid.length < 1) {
      CosLogUtil.log("$subscribeLogPrefix: can't jump to following list page duto empty uid");
      return;
    }
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return FollowingListPage(
          uid: uid,
        );
      },
    ));
  }

  ///得到总的item数(搜索+ (顶部following contain) + 视频个数)
  int _getTotalItemCount() {
    int cnt = 0;
    if (_checkHasFollowingData()) {
      ///following 列表作为listView的第一个item
      cnt += 1;
    }
    if (_videoList.isNotEmpty) {
      cnt += _videoList.length;
    }
    return cnt;
  }

  ///检查following列表是否为空
  bool _checkHasFollowingData() {
    if (_followingList.isNotEmpty) {
      return true;
    }
    return false;
  }

  ///检查是否有following或是视频数据
  bool _checkHasPageData() {
    if (_checkHasFollowingData() || VideoUtil.checkVideoListIsNotEmpty(_videoList)) {
      return true;
    }
    return false;
  }

  /// 拉取订阅视频列表
  Future<List<GetVideoListNewDataListBean>?> _loadSubscribeVideoList(bool isNextPage) async {
    List<GetVideoListNewDataListBean>? list;
    if (isNextPage && !_hasNextPage) {
      return _videoList;
    }
    int page = isNextPage ? _curPage + 1 : 1;
    await RequestManager.instance.getSubscribeVideoList(tag, _uid, page, _pageSize).then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("$subscribeLogPrefix: fail to request uid:$_uid's "
            "video list");
        list = null;
        return;
      }
      GetVideoListNewBean bean = GetVideoListNewBean.fromJson(json.decode(response.data));
      bool isSuccess = (bean.status == SimpleResponse.statusStrSuccess);
      List<GetVideoListNewDataListBean> dataList = isSuccess ? (bean.data?.list ?? []) : [];
      list = dataList;
      if (isSuccess) {
        tmpHasMore = bean.data?.hasNext == "1";
        if (isNextPage) {
          _hasNextPage = tmpHasMore;
          if (dataList.isNotEmpty) {
            _videoList.addAll(dataList);
            _curPage = page;
          }
          setState(() {});
        }
      } else {
        CosLogUtil.log("$subscribeLogPrefix: fail to request uid:$_uid's "
            "video list of page:$page, the error msg is ${bean.msg}, "
            "error code is ${bean.status}");
        if (bean.status == "1200001") {
          //没有关注任何人
          list = [];
        } else if (bean.status == tokenErrCode) {
          //token错误，当过期处理
          _isTokenErr = true;
          list = null;
        } else {
          list = null;
        }
      }
    }).catchError((err) {
      CosLogUtil.log("$subscribeLogPrefix: fail to load video list of "
          "uid:$_uid, the error is $err");
      list = null;
    }).whenComplete(() {});
    return list;
  }

  /// 拉取following列表
  Future<List<FollowRelationData>?> _loadFollowingList() async {
    List<FollowRelationData>? list;
    await RequestManager.instance.getUserFollowingList(tag, _uid, 1, _pageSize).then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("$subscribeLogPrefix: fail to fetch following list of"
            " uid:$_uid's first page data");
        list = null;
        return;
      }
      FollowRelationListBean bean = FollowRelationListBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        list = bean.data.list;
      } else {
        CosLogUtil.log("$subscribeLogPrefix: fail to load following list "
            "of uid:$_uid, the error is ${bean.status}");
        if (bean.status == tokenErrCode) {
          //token错误，当过期处理
          _isTokenErr = true;
        }
        list = null;
      }
    }).catchError((error) {
      CosLogUtil.log("$subscribeLogPrefix: fail to request following list of "
          "uid:$_uid's first page data, the error is $error");
      list = null;
    }).whenComplete(() {});
    return list;
  }

  Future<void> _loadNextPageData() async {
    if (_isFetching) {
      CosLogUtil.log("$subscribeLogPrefix: is fething data when load next page");
      return;
    }
    _isFetching = true;
    await _loadSubscribeVideoList(true);
    _isFetching = false;
    if (_isTokenErr) {
      _resetPageData();
      _isTokenErr = false;
      setState(() {});
    }
  }

  /// 下拉刷新重新拉取数据
  Future<void> _reloadData() async {
    if (_isFetching) {
      CosLogUtil.log("$subscribeLogPrefix: is fething data when reload");
      return;
    }
    _isFetching = true;
    bool isNeedLoadRate = (_rateInfo == null) ? true : false;
    Iterable<Future> reqList;
    if (isNeedLoadRate) {
      reqList = [_loadFollowingList(), _loadSubscribeVideoList(false), CosSdkUtil.instance.getChainState(), VideoUtil.requestExchangeRate(tag)];
    } else {
      reqList = [_loadFollowingList(), _loadSubscribeVideoList(false), CosSdkUtil.instance.getChainState(), VideoUtil.requestExchangeRate(tag)];
    }
    await Future.wait(
      reqList,
    ).then((valList) {
      if (mounted) {
        int resLen = valList.length;
        List<FollowRelationData>? followingList;
        List<GetVideoListNewDataListBean>? videoList;
        ExchangeRateInfoData? rateData = _rateInfo;
        dynamic_properties? dgpo = _chainDgpo;
        bool isGetFollowSuccess = false, isGetVideoSuccess = false;
        int followCnt = 0, videoCnt = 0;
        if (resLen >= 1) {
          followingList = valList[0];
        }

        if (resLen >= 2) {
          videoList = valList[1];
        }
        if (resLen >= 3) {
          GetChainStateResponse bean = valList[2];
          dgpo = bean.state.dgpo;
          _chainDgpo = dgpo;
        }

        if (isNeedLoadRate && resLen >= 4) {
          rateData = valList[3];
          if (rateData != null) {
            _rateInfo = rateData;
          }
        }

        if (followingList != null) {
          isGetFollowSuccess = true;
          _followingList = followingList;
          if (followingList.isEmpty) {
            followingListHeight = 0;
          }
          followCnt = followingList.length;
        }

        if (videoList != null) {
          isGetVideoSuccess = true;
          _videoList = videoList;
          _curPage = 1;
          _hasNextPage = tmpHasMore;
          keyMap.clear();
          videoItemHeight = 0;
          videoCnt = videoList.length;
        }

        if (isGetVideoSuccess || isGetFollowSuccess) {
          //关注列表或是视频列表任意拉取成功,都刷新并显示
          _isFetching = false;
          _isShowLoading = false;
          _isSuccessLoad = true;
          _isFirstLoad = false;
          if (followCnt == 0 && videoCnt == 0) {
            //没有关注任何人
            _hasFollowing = false;
          } else {
            _hasFollowing = true;
          }
          setState(() {
//             if (curTabIndex == 2) {
//               Future.delayed(Duration(milliseconds: 500), () {
//                 _handelAutoPlay(0);
//               });
//             }
            Future.delayed(Duration(seconds: 1), () {
              if (!_isScrolling) {
                _reportVideoExposure();
              }
            });
          });
        } else {
          if (_isFirstLoad && _isSuccessLoad) {
            _isSuccessLoad = false;
          } else if (_checkHasPageData()) {
            _showLoadDataFailTips();
          }
        }
      }
    }).catchError((err) {
      CosLogUtil.log("$subscribeLogPrefix: fail to reload data, the error is $err");
      if (!_checkHasPageData()) {
        if (_isFirstLoad && _isSuccessLoad) {
          _isSuccessLoad = false;
        }
      } else {
        _showLoadDataFailTips();
      }
    }).whenComplete(() {
      _isFetching = false;
      _isFirstLoad = false;
      if (mounted && (_isShowLoading || _isTokenErr)) {
        _isShowLoading = false;
        if (_isTokenErr) {
          //清空数据回到未登录状态
          _resetPageData();
          _isTokenErr = false;
        }
        setState(() {});
      }
    });
    return;
  }

  void _showLoadDataFailTips() {
    if (_failTipsKey.currentState != null) {
      _failTipsKey.currentState?.showWithAnimation();
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
    if (_videoList.isEmpty) {
      return;
    }
    List<int> visibleList = _getVisibleItemIndex();
    if (visibleList.isNotEmpty) {
      for (int i = 0; i < visibleList.length; i++) {
        int idx = visibleList[i];
        if (idx >= 0 && idx < _videoList.length) {
          GetVideoListNewDataListBean bean = _videoList[idx];
          VideoReportUtil.reportVideoExposure(VideoExposureType.SubscribePageType, bean.id, bean.uid);
        }
      }
    }
  }
}

/*
 following list item
 */
class SingleFollowItem extends StatefulWidget {
  final FollowRelationData? relationData;
  final ExchangeRateInfoData? rateInfo;
  final dynamic_properties? chainDgpo;

  SingleFollowItem({this.relationData, this.rateInfo, this.chainDgpo});

  @override
  State<StatefulWidget> createState() => _SingleFollowItemState();
}

class _SingleFollowItemState extends State<SingleFollowItem> {
  @override
  Widget build(BuildContext context) {
    double avatarWidth = 50.0, bgWidth = 67;
    String avatar = widget.relationData?.anchorImageCompress?.avatarCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(avatar)) {
      avatar = widget.relationData?.avatar ?? '';
    }
    return Container(
      alignment: Alignment.center,
      width: bgWidth,
      color: AppThemeUtil.setDifferentModeColor(
          lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0), darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
            darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
          ),
          child: InkWell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.color_ebebeb, width: AppDimens.item_line_height_0_5),
                    borderRadius: BorderRadius.circular(avatarWidth / 2),
                  ),
                  child: Stack(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: AppColors.color_ffffff,
                        radius: avatarWidth / 2,
                        backgroundImage: AssetImage('assets/images/ic_default_avatar.png'),
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.color_transparent,
                        radius: avatarWidth / 2,
                        backgroundImage: CachedNetworkImageProvider(
                          avatar,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: AppDimens.margin_6),
                  alignment: Alignment.center,
                  width: avatarWidth,
                  height: AppDimens.item_size_15,
                  child: Text(
                    widget.relationData?.nickname ?? "",
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppThemeUtil.setDifferentModeColor(
                        lightColor: Colors.black,
                        darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                      ),
                      fontSize: 11,
                      inherit: false,
                    ),
                  ),
                )
              ],
            ),
            onTap: () {
              _jumpToUserCenter(widget.relationData?.uid ?? "");
            },
          ),
        ),
      ),
    );
  }

  void _jumpToUserCenter(String uid) {
//    if (uid == null || uid.length < 1) {
//      CosLogUtil.log("$subscribeLogPrefix: can't open webview due to uid is empty");
//      return;
//    }
    String avatar = widget.relationData?.anchorImageCompress?.avatarCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(avatar)) {
      avatar = widget.relationData?.avatar ?? '';
    }
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return OthersHomePage(OtherHomeParamsBean(
          uid: widget.relationData?.uid ?? "",
          nickName: widget.relationData?.nickname ?? '',
          avatar: avatar,
          rateInfoData: widget.rateInfo,
          dgpoBean: widget.chainDgpo,
        ));
      },
    ));
  }
}
