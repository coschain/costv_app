import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/login_status_event.dart';
import 'package:costv_android/event/tab_switch_event.dart';
import 'package:costv_android/event/video_small_show_status_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/history/user_liked_video_page.dart';
import 'package:costv_android/pages/history/video_watch_history.dart';
import 'package:costv_android/pages/history/user_uploaded_video_page.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/platform_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/utils/web_view_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/dark_mode_switch_entrance.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/page_title_widget.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:costv_android/widget/video_time_widget.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/event/setting_switch_event.dart';
import 'package:costv_android/event/watch_video_event.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/video_report_util.dart';


String videoHistoryLogPrefix = "VideoHistoryPage";

class RecentlyWatchedPage extends StatefulWidget {
  RecentlyWatchedPage({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  @override
  _RecentlyWatchedPageState createState() => _RecentlyWatchedPageState();
}

class _RecentlyWatchedPageState extends State<RecentlyWatchedPage>
    with RouteAware {
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey =
      new GlobalKey<NetRequestFailTipsViewState>();
  static const tag = '_RecentlyWatchedPageState';
  final String logPrefix = "WatchHistory";
  List<GetVideoListNewDataListBean> _videoList = [];
  List<HistoryVideoItemModel> _videoEntranceList = [];
  bool _isFetching = false, _isShowLoading = false, _isSuccessLoad = true;
  String _pageSize = "20";
  bool _isLoggedIn = false, _watchedNewVideo = false;
  StreamSubscription _eventSubscription;
  String _uid = "";
  String _version;

  @override
  void initState() {
    PlatformUtil.getVersion().then((value) {
      _version = value;
    });
    _initHistoryVideoItemData();
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
  void didUpdateWidget(RecentlyWatchedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void didPushNext() {
    super.didPushNext();
    EventBusHelp.getInstance().fire(VideoSmallShowStatusEvent(false));
  }

  void didPopNext() {
    super.didPopNext();
    EventBusHelp.getInstance().fire(VideoSmallShowStatusEvent(true));
    if (curTabIndex == BottomTabType.TabWatchHistory.index) {
      if (_checkIsNeedToReloadData()) {
        _isShowLoading = true;
        _reloadData();
        _watchedNewVideo = false;
        setState(() {});
      }
    }
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
        body: Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: AppThemeUtil.setDifferentModeColor(
        lightColor: AppColors.color_f6f6f6,
        darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
      ),
      child: _getCurPageBody(),
    ));
  }

  void _initHistoryVideoItemData() {
    if (_videoEntranceList == null) {
      _videoEntranceList = [];
    } else if (_videoEntranceList.isNotEmpty) {
      _videoEntranceList.clear();
    }
    _videoEntranceList.add(HistoryVideoItemModel(
      type: HistoryVideoType.RecentlyWatched,
      icon: AppThemeUtil.getUserWatchHistoryIcn(),
      desc: InternationalLocalizations.watchHistory,
    ));
    _videoEntranceList.add(HistoryVideoItemModel(
      type: HistoryVideoType.Liked,
      icon: AppThemeUtil.getUserLikedIcn(),
      desc: InternationalLocalizations.likedVideo,
    ));
    _videoEntranceList.add(HistoryVideoItemModel(
      type: HistoryVideoType.Uploaded,
      icon: AppThemeUtil.getUploadIcn(),
      desc: InternationalLocalizations.myUploadedVideos,
    ));
    _videoEntranceList.add(HistoryVideoItemModel(
      type: HistoryVideoType.ProblemFeedback,
      icon: AppThemeUtil.getFeedbackIcn(),
      desc: InternationalLocalizations.problemFeedback,
    ));
  }

  ///重新拉取第一页数据
  Future<void> _reloadData() async {
    _loadWatchedVideoList();
  }

  ///获取观看历史数据
  Future<void> _loadWatchedVideoList() async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    RequestManager.instance
        .getVideoWatchHistoryList(tag, _uid, "0", pageSize: _pageSize)
        .then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("$logPrefix: fail to request uid:$_uid's "
            "watched video list");
        if (mounted) {
          if (VideoUtil.checkVideoListIsNotEmpty(_videoList)) {
            _showLoadDataFailTips();
          } else {
            _isSuccessLoad = false;
          }
        }
        return;
      }
      GetVideoListNewBean bean =
          GetVideoListNewBean.fromJson(json.decode(response.data));
      bool isSuccess = (bean.status == SimpleResponse.statusStrSuccess);
      List<GetVideoListNewDataListBean> dataList =
          isSuccess ? (bean.data?.list ?? []) : [];
      if (isSuccess) {
        _videoList = dataList;
        _isSuccessLoad = true;
      } else if (bean.status == tokenErrCode) {
        //token 错误,清空数据,重新登录
        _resetPageData();
      } else if (_isShowLoading && _isSuccessLoad) {
        _isSuccessLoad = false;
      } else {
        _showLoadDataFailTips();
      }
    }).catchError((err) {
      CosLogUtil.log("$logPrefix: fail to load watched video list of "
          "uid:$_uid, the error is $err");
      if (_isShowLoading && _isSuccessLoad) {
        _isSuccessLoad = false;
      } else {
        _showLoadDataFailTips();
      }
    }).whenComplete(() {
      _isFetching = false;
      _isShowLoading = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _getCurPageBody() {
    if (!_isLoggedIn) {
      //未登录提醒用户登录
      return PageRemindWidget(
        clickCallBack: _startLogIn,
        remindType: RemindType.WatchHistoryPageLogIn,
      );
    } else {
      if (!_isSuccessLoad) {
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
      _initHistoryVideoItemData();
      return LoadingView(
        child: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Container(
            color: AppThemeUtil.setDifferentModeColor(
                lightColor: Common.getColorFromHexString("F6F6F6", 1.0),
                darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
            child: Column(
              children: <Widget>[
                //顶部搜索
                _getSearchWidget(),
                Expanded(
                  child: NetRequestFailTipsView(
                    key: _failTipsKey,
                    baseWidget: RefreshAndLoadMoreListView(
                      itemCount: _getListViewItemCount(),
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return RecentWatchView(
                            videoList: _videoList,
                          );
                        }
                        if (index == _getListViewItemCount() - 1) {
                          //暗夜模式开关
                          return Container(
                            margin: EdgeInsets.only(top: AppDimens.margin_10),
                            child: DarkModeSwitchEntrance(),
                          );
                        } else if (index == _getListViewItemCount() - 2) {
                          return Container(
                            margin: EdgeInsets.only(top: AppDimens.margin_10),
                            child: _getEntranceItem(index - 1),
                          );
                        } else {
                          return _getEntranceItem(index - 1);
                        }
                      },
                      bottomMessage: "",
                      isRefreshEnable: true,
                      isLoadMoreEnable: false,
                      hasTopPadding: false,
                      contentTopPadding: 10,
                      onRefresh: _reloadData,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: AppDimens.margin_15),
                  child: Text(
                    'V $_version',
                    style: AppStyles.text_style_a0a0a0_13,
                  ),
                )
              ],
            ),
          ),
        ),
        isShow: _isShowLoading,
      );
    }
  }

  Widget _getSearchWidget() {
    return Container(
      child: Container(
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
            darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
        child: PageTitleWidget(tag),
      ),
    );
  }

  ///获取观看历史等入口的item
  VideoHistoryEntranceItem _getEntranceItem(int idx) {
    int listCnt = _videoEntranceList?.length ?? 0;
    if (idx >= 0 && idx < listCnt) {
      return VideoHistoryEntranceItem(
        data: _videoEntranceList[idx],
        uid: _uid,
      );
    }
    return VideoHistoryEntranceItem(
      uid: _uid,
    );
  }

  ///获取listView的item个数
  int _getListViewItemCount() {
    int cnt = 1; //最近观看
    if (_videoEntranceList != null && _videoEntranceList.length > 0) {
      cnt += _videoEntranceList.length;
    }
    //暗夜模式开关
    cnt += 1;
    return cnt;
  }

  ///监听消息事件
  void _listenEvent() {
    if (_eventSubscription == null) {
      _eventSubscription = EventBusHelp.getInstance().on().listen((event) {
        if (event != null) {
          //登录成功
          if (event is LoginStatusEvent) {
            if (event.type == LoginStatusEvent.typeLoginSuccess) {
              if (Common.checkIsNotEmptyStr(event.uid)) {
                _uid = event.uid;
                _isLoggedIn = true;
                _reloadData();
                setState(() {});
              } else {
                CosLogUtil.log("$logPrefix: success log in but get empty uid");
              }
            } else if (event.type == LoginStatusEvent.typeLogoutSuccess) {
              _resetPageData();
              setState(() {});
            }
          } else if (event is TabSwitchEvent) {
            if (event.to == 3) {
              DataReportUtil.instance.reportData(
                eventName: "Click_history",
                params: {"Click_history": "1"},
              );
              if (_checkIsNeedToReloadData()) {
                _isShowLoading = true;
                _reloadData();
                _watchedNewVideo = false;
                setState(() {});
              }
            }
          } else if (event is SettingSwitchEvent) {
            SettingModel setting = event.setting;
            if (setting.isEnvSwitched || (setting.oldLan != setting.newLan)) {
              _resetPageData();
              if ((setting.oldLan != setting.newLan) &&
                  _videoEntranceList != null &&
                  _videoEntranceList.isNotEmpty) {
                _videoEntranceList.clear();
                _initHistoryVideoItemData();
              }
              if (!setting.isEnvSwitched) {
                _isLoggedIn = Common.judgeHasLogIn();
                if (_isLoggedIn) {
                  _reloadData();
                }
              }
              setState(() {});
            }
          } else if (event is WatchVideoEvent) {
            if (_isLoggedIn) {
              _watchedNewVideo = true;
            }
          }
        }
      });
    }
  }

  void _resetPageData() {
    _isLoggedIn = false;
    _isFetching = false;
    _isShowLoading = false;
    _isSuccessLoad = true;
    _watchedNewVideo = false;
    if (_videoList != null && _videoList.isNotEmpty) {
      _videoList.clear();
    }
  }

  ///取消监听消息事件
  void _cancelListenEvent() {
    if (_eventSubscription != null) {
      _eventSubscription.cancel();
    }
  }

  bool _checkIsNeedToReloadData() {
    if (_isLoggedIn && _watchedNewVideo) {
      return true;
    }
    return false;
  }

  ///登录
  void _startLogIn() {
    if (Platform.isAndroid) {
      WebViewUtil.instance.openWebView(Constant.logInWebViewUrl);
    } else {
      Navigator.of(context).push(SlideAnimationRoute(
        builder: (_) {
          return WebViewPage(
            Constant.logInWebViewUrl,
          );
        },
      ));
    }
  }

  void _showLoadDataFailTips() {
    if (_failTipsKey.currentState != null) {
      _failTipsKey.currentState.showWithAnimation();
    }
  }
}

//单个视频item
class HistoryVideoItem extends StatefulWidget {
  final GetVideoListNewDataListBean video;

  HistoryVideoItem({this.video});

  @override
  State<StatefulWidget> createState() {
    return _HistoryVideoItemState();
  }
}

class _HistoryVideoItemState extends State<HistoryVideoItem> {
  @override
  Widget build(BuildContext context) {
    double itemWidth = 139, coverHeight = 78.0, fontSize = 11;
    String imageUrl = widget.video?.videoImageCompress?.videoCompressUrl ?? "";
    if (ObjectUtil.isEmptyString(imageUrl)) {
      imageUrl = widget.video?.videoCoverBig ?? '';
    }
    return Material(
      color: Colors.transparent,
      child: Ink(
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
            darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
        child: InkWell(
          onTap: () {},
          child: Container(
            color: AppThemeUtil.setDifferentModeColor(
                lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
                darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
            width: itemWidth,
            padding: EdgeInsets.only(left: 12),
            child: Material(
                color: Colors.transparent,
                child: Ink(
                  color: AppThemeUtil.setDifferentModeColor(
                      lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
                      darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
                  child: InkWell(
                    onTap: () {
                      _onClickToPlayVideo(widget.video?.id, widget.video?.uid,
                          widget.video?.videosource);
                    },
                    child: Column(
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            Container(
                              width: itemWidth,
                              height: coverHeight,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(3)),
//                                color: Common.getColorFromHexString("D6D6D6", 1.0),
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
                                fit: BoxFit.fitHeight,
                                placeholder:
                                    (BuildContext context, String url) {
                                  return Container(
                                    color: Common.getColorFromHexString(
                                        "D6D6D6", 1.0),
                                  );
                                },
                                imageUrl: imageUrl,
                                errorWidget: (context, url, error) => Container(),
                              ),
                            ),
                            _getVideoDurationWidget(),
                          ],
                        ),
                        //视频封面

                        //标题
                        Container(
                          width: itemWidth,
                          margin: EdgeInsets.only(top: 10),
                          child: Text(
                            widget.video?.title ?? "",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: fontSize,
                              color: AppThemeUtil.setDifferentModeColor(
                                  lightColor: Common.getColorFromHexString(
                                      "333333", 1.0),
                                  darkColorStr: DarkModelTextColorUtil
                                      .firstLevelBrightnessColorStr),
                            ),
                          ),
                        ),
                        //作者
                        Container(
                          margin: EdgeInsets.only(top: 2),
                          width: itemWidth,
                          child: Text(
                            widget.video?.anchorNickname ?? "",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: fontSize,
                              color: AppThemeUtil.setDifferentModeColor(
                                  lightColor: Common.getColorFromHexString(
                                      "858585", 1.0),
                                  darkColorStr: DarkModelTextColorUtil
                                      .secondaryBrightnessColorStr),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ),
        ),
      ),
    );
  }

  Widget _getVideoDurationWidget() {
    if (Common.checkVideoDurationValid(widget.video?.duration)) {
      return Positioned(
        right: 0,
        bottom: 0,
        child:
            VideoTimeWidget(Common.formatVideoDuration(widget.video?.duration)),
      );
    }
    return Container();
  }

  void _onClickToPlayVideo(String vid, String uid, String videoSource) {
    _reportVideoClick();
    if (!Common.checkIsNotEmptyStr(vid)) {
      CosLogUtil.log(
          "$videoHistoryLogPrefix: fail to jumtp to video detail page "
          "due to empty vid");
      return;
    }

//    if (!Common.checkIsNotEmptyStr(uid)) {
//      CosLogUtil.log("$videoHistoryLogPrefix: fail to jumtp to video detail page"
//          "due to empty uid");
//      return;
//    }
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
            vid: vid,
            uid: uid,
            videoSource: videoSource,
            enterSource:
            VideoDetailsEnterSource.VideoDetailsEnterSourceWatchHistory));
      },
      settings: RouteSettings(name: videoDetailPageRouteName),
      isCheckAnimation: true,
    ));
  }

  void _reportVideoClick() {
    if (widget?.video?.id != null) {
//      DataReportUtil.instance.reportData(
//          eventName: "Click_video", params: {"Click_video": widget.video.id});
      VideoReportUtil.reportClickVideo(
          ClickVideoSource.History, widget.video?.id ?? '');
    }
  }
}

///顶部最近观看模块view
class RecentWatchView extends StatefulWidget {
  final List<GetVideoListNewDataListBean> videoList;

  RecentWatchView({this.videoList});

  @override
  State<StatefulWidget> createState() {
    return _RecentWatchViewState();
  }
}

class _RecentWatchViewState extends State<RecentWatchView> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.fromLTRB(0, 15, 10, 10),
      width: screenWidth,
      decoration: BoxDecoration(
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("FFFFFF", 1.0),
            darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
        border: Border(
            bottom: BorderSide(
                color: AppThemeUtil.setDifferentModeColor(
                    lightColor: Common.getColorFromHexString("EBEBEB", 1),
                    darkColorStr: "3E3E3E"),
                width: 0.5)),
      ),
      child: Column(
        children: <Widget>[
          //最近观看文字
          Container(
            width: screenWidth - 13,
            margin: EdgeInsets.only(left: 10),
            child: Text(
              InternationalLocalizations.recentlyWatched,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 15,
                  color: AppThemeUtil.setDifferentModeColor(
                    lightColor: Common.getColorFromHexString("333333", 1.0),
                    darkColorStr:
                        DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                  )),
            ),
          ),
          //视频列表
          Container(
            margin: EdgeInsets.only(top: 13),
            constraints: BoxConstraints(
              maxHeight: 140,
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: widget?.videoList?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                return _getVideoItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  HistoryVideoItem _getVideoItem(int idx) {
    int listCnt = widget?.videoList?.length ?? 0;
    if (idx >= 0 && idx < listCnt) {
      return HistoryVideoItem(
        video: widget.videoList[idx],
      );
    }

    return HistoryVideoItem();
  }
}

class VideoHistoryEntranceItem extends StatefulWidget {
  final HistoryVideoItemModel data;
  final String uid;

  VideoHistoryEntranceItem({this.data, this.uid});

  @override
  State<StatefulWidget> createState() {
    return _VideoHistoryEntranceItemState();
  }
}

class _VideoHistoryEntranceItemState extends State<VideoHistoryEntranceItem> {
  @override
  Widget build(BuildContext context) {
    double itemWidth = MediaQuery.of(context).size.width,
        lIconSize = 16.0,
        rIconWidth = 15,
        descLeftMargin = 10,
        itemPadding = 15.0;
    return Material(
      color: Colors.transparent,
      child: Ink(
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
            darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
        child: InkWell(
          child: Container(
            width: itemWidth,
//            height: 50,
            padding: EdgeInsets.all(itemPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //左侧icon
                SizedBox(
                  width: lIconSize,
                  height: lIconSize,
                  child: Image.asset(
                    widget.data?.icon ?? "",
                    fit: BoxFit.contain,
                  ),
                ),
                //描述
                Container(
                  width: itemWidth -
                      descLeftMargin -
                      itemPadding * 2 -
                      lIconSize -
                      17,
                  margin: EdgeInsets.only(left: descLeftMargin),
                  child: Text(
                    widget.data?.desc ?? "",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppThemeUtil.setDifferentModeColor(
                          lightColorStr: "333333",
                          darkColorStr: DarkModelTextColorUtil
                              .firstLevelBrightnessColorStr),
                    ),
                  ),
                ),
                //right arrow icon
                Container(
                  margin: EdgeInsets.only(left: 2),
                  child: Image.asset(
                    AppThemeUtil.getHistoryEntranceRightIcn(),
                    width: rIconWidth,
                    height: rIconWidth,
                    fit: BoxFit.contain,
                  ),
                )
              ],
            ),
          ),
          onTap: () {
            _onClickEntrance();
          },
        ),
      ),
    );
  }

  String _getMoreIcn() {
    if (AppThemeUtil.checkIsDarkMode()) {
      return AppThemeUtil.getRightIcn();
    }
    return "assets/images/ic_history_more.png";
  }

  void _onClickEntrance() {
    HistoryVideoType tp = widget.data?.type;
    if (tp != null) {
      if (tp == HistoryVideoType.RecentlyWatched) {
        Navigator.of(context).push(SlideAnimationRoute(
          builder: (_) {
            return WatchVideoHistory(
              uid: widget.uid,
            );
          },
        ));
      } else if (tp == HistoryVideoType.Liked) {
        Navigator.of(context).push(SlideAnimationRoute(
          builder: (_) {
            return UserLikedVideoPage(
              uid: widget.uid,
            );
          },
        ));
      } else if (tp == HistoryVideoType.Uploaded) {
        Navigator.of(context).push(SlideAnimationRoute(
          builder: (_) {
            return UploadedVideos(
              uid: widget.uid,
            );
          },
        ));
      } else if (tp == HistoryVideoType.ProblemFeedback) {
        Navigator.of(context).push(SlideAnimationRoute(
          builder: (_) {
            return WebViewPage(Constant.problemFeedbackUrl);
          },
        ));
      }
    } else {
      CosLogUtil.log("history video type is empty");
    }
  }
}
