import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/get_message_list_bean.dart';
import 'package:costv_android/bean/simple_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/login_status_event.dart';
import 'package:costv_android/event/tab_switch_event.dart';
import 'package:costv_android/event/video_small_show_status_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/comment/bean/comment_list_parameter_bean.dart';
import 'package:costv_android/pages/comment/comment_children_list_page.dart';
import 'package:costv_android/pages/comment/comment_list_page.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/web_view_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/message_center_item_widget.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/page_title_widget.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'webview/webview_page.dart';

class MessagePage extends StatefulWidget {
  MessagePage({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> with RouteAware {
  static const tag = '_MessagePageState';
  StreamSubscription _eventSubscription;
  bool _isLoggedIn = true;
  bool _isFirstSuccessLoad = false;
  bool _isSuccessLoad = true;
  bool _isShowLoading = false;
  bool _isNoData = true;
  bool _hasNextPage = false;
  bool _isFetching = false;
  GlobalObjectKey<RefreshAndLoadMoreListViewState> _messageCenterKey =
      GlobalObjectKey<RefreshAndLoadMoreListViewState>("messageCenter");
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey =
      new GlobalKey<NetRequestFailTipsViewState>();
  int _pageSize = 20, _curPage = 1;
  List<GetMessageListItemBean> _messageList = [];
  String _lastKey = "0";

  @override
  void initState() {
    _isLoggedIn = Common.judgeHasLogIn();
    if (_isLoggedIn) {
      _reloadData();
    }
    _listenEvent();
    super.initState();
  }

  @override
  void didUpdateWidget(MessagePage oldWidget) {
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
  void dispose() {
    _cancelListenEvent();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: AppThemeUtil.setDifferentModeColor(
        lightColor: AppColors.color_f6f6f6,
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
        remindType: RemindType.MessagePageLogIn,
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
      } else if (_isFirstSuccessLoad && _isNoData) {
        //没有消息数据
        return LoadingView(
          isShow: _isShowLoading,
          child: PageRemindWidget(
            remindType: RemindType.MessageNoData,
          ),
        );
      }
      return Container(
          color: AppThemeUtil.setDifferentModeColor(
              lightColor: Common.getColorFromHexString("F6F6F6", 1.0),
              darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
          child: LoadingView(
            isShow: _isShowLoading,
            child: Column(
              children: <Widget>[
                _getSearchWidget(),
                Container(
                  color: AppThemeUtil.setDifferentModeColor(
                      lightColor: Common.getColorFromHexString("F6F6F6", 1.0),
                      darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
                ),
                Expanded(
                  child: NetRequestFailTipsView(
                    key: _failTipsKey,
                    baseWidget: RefreshAndLoadMoreListView(
                      key: _messageCenterKey,
                      hasTopPadding: false,
                      pageSize: _pageSize,
                      isHaveMoreData: _hasNextPage,
                      itemCount: _getTotalMessageCount(),
                      itemBuilder: (context, index) {
                        return _getMessageItemByIndex(index);
                      },
                      onLoadMore: () {
                        _loadNextPageData();
                      },
                      onRefresh: _reloadData,
                      isShowItemLine: false,
                      bottomMessage: InternationalLocalizations.noMoreData,
                      isRefreshEnable: true,
                      isLoadMoreEnable: true,
                    ),
                  ),
                )
              ],
            ),
          ));
    }
  }

  Widget _getSearchWidget() {
    return Container(
      color: AppThemeUtil.setDifferentModeColor(
          lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0),
          darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
      child: PageTitleWidget(tag),
    );
  }

  MessageCenterItemWidget _getMessageItemByIndex(int index) {
    int listCnt = _messageList?.length ?? 0;
    if (index < listCnt) {
      GetMessageListItemBean data = _messageList[index];
      return MessageCenterItemWidget(
        messageData: data,
        clickMessageCallBack: () {
          _playVideo(data);
          if (data.isRead == "1") {
            _reportReadMessageToServer(data, 1);
          }
          if (mounted) {
            data.isRead = "2";
            setState(() {});
          }
        },
      );
    }
    return MessageCenterItemWidget();
  }

  Future<void> _loadNextPageData() async {
    if (_isFetching) {
      CosLogUtil.log("$tag: is fething data when load next page");
      return;
    }
    _isFetching = true;
    await httpGetMessageList(true, false);
    _isFetching = false;
  }

  /// 下拉刷新重新拉取数据
  Future<void> _reloadData() async {
    if (_isFetching) {
      CosLogUtil.log("$tag: is fething data when reload");
      return;
    }
    _isFetching = true;
    await httpGetMessageList(false, false);
    _isFetching = false;
  }

  /// 点击tab更新页面数据
  Future<void> _updateView() async {
    if (_isFetching) {
      CosLogUtil.log("$tag: is fething data when reload");
      return;
    }
    _isFetching = true;
    await httpGetMessageList(false, true);
    _isFetching = false;
  }

  int _getTotalMessageCount() {
    int listCnt = _messageList?.length ?? 0;
    return listCnt;
  }

  void _playVideo(GetMessageListItemBean bean) {
    if (!Common.checkIsNotEmptyStr(bean.vid)) {
      CosLogUtil.log("$tag: fail to jumtp to video detail page "
          "due to empty vid");
      return;
    }
    DataReportUtil.instance.reportData(eventName: "Click_notice", params: {});
    CommentListParameterBean commentListParameterBean =
        CommentListParameterBean();
    commentListParameterBean.isReply = false;
    commentListParameterBean.videoId = bean?.videoInfo?.id ?? '';
    commentListParameterBean.vid = bean?.vid ?? '';
    commentListParameterBean.creatorUid = bean?.videoInfo?.uid ?? '';
    commentListParameterBean.cid = bean?.cidInfo?.cid ?? '';
    commentListParameterBean.nickName = bean?.fromUidInfo?.nickname ?? '';
    commentListParameterBean.pid = bean?.cidInfo?.pid ?? '';
    commentListParameterBean.videoSource = bean?.videoInfo?.videoSource ?? '';
    commentListParameterBean.videoTitle = bean?.videoInfo?.title ?? '';
    commentListParameterBean.videoImage =
        bean?.videoInfo?.videoImageCompress?.videoCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(commentListParameterBean.videoImage)) {
      commentListParameterBean.videoImage =
          bean?.videoInfo?.videoCoverBig ?? '';
    }
    commentListParameterBean.uid = bean?.fromUid ?? '';
    if (bean.type == GetMessageListItemBean.typeCommentLike) {
      if (ObjectUtil.isEmptyString(bean.cidInfo?.pid)) {
        Navigator.of(context).push(SlideAnimationRoute(
          builder: (_) {
            return CommentListPage(commentListParameterBean);
          },
        ));
      } else {
        Navigator.of(context).push(SlideAnimationRoute(
          builder: (_) {
            return CommentChildrenListPage(commentListParameterBean);
          },
        ));
      }
    } else if (bean.type == GetMessageListItemBean.typeVideoComment) {
      Navigator.of(context).push(SlideAnimationRoute(
        builder: (_) {
          return CommentListPage(commentListParameterBean);
        },
      ));
    } else if (bean.type == GetMessageListItemBean.typeReplyToComment) {
      Navigator.of(context).push(SlideAnimationRoute(
        builder: (_) {
          return CommentChildrenListPage(commentListParameterBean);
        },
      ));
    } else {
      Navigator.of(context).push(SlideAnimationRoute(
        builder: (_) {
          return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
            vid: bean?.videoInfo?.id ?? '',
            uid: bean?.videoInfo?.uid ?? '',
            videoSource: bean?.videoInfo?.videoSource ?? '',
            enterSource:
            VideoDetailsEnterSource.VideoDetailsEnterSourceNotification,
          ));
        },
        settings: RouteSettings(name: videoDetailPageRouteName),
        isCheckAnimation: true,
      ));
    }
  }

  /// 获取消息列表
  Future<void> httpGetMessageList(bool isNextPage, bool isClear) async {
    if (isNextPage && !_hasNextPage) {
      return;
    }
    int page = isNextPage ? _curPage + 1 : 1;
    String lastKey = "0";
    if (isNextPage) {
      lastKey = _lastKey;
      if (!Common.checkIsNotEmptyStr(lastKey)) {
        lastKey = "0";
      }
    }
    String isClearParameter;
    if (isClear) {
      isClearParameter = MessageListRequest.isClearYes;
    } else {
      isClearParameter = MessageListRequest.isClearNo;
    }
    await RequestManager.instance
        .getMessageList(tag, Constant.uid ?? '',
            page: page.toString(),
            pageSize: _pageSize.toString(),
            isClear: isClearParameter,
            lastKey: lastKey)
        .then((response) {
      if (response == null || !mounted) {
        if (mounted && !isNextPage) {
          _hanleRequestFail(isNextPage);
        }
        return;
      }
      GetMessageListBean bean =
          GetMessageListBean.fromJson(json.decode(response.data));
      bool isSuccess = (bean.status == SimpleResponse.statusStrSuccess);
      if (isSuccess) {
        _hasNextPage = (bean.data.hasNext == "1");
        _lastKey = bean.data.lastKey ?? "0";
        _curPage = page;
        _isSuccessLoad = true;
        _isFirstSuccessLoad = true;
        if (_messageList == null) {
          _messageList = [];
        }
        if (!isNextPage) {
          _messageList = bean.data.list;
        } else {
          _messageList.addAll(bean.data.list);
        }
        _isNoData = _messageList.isEmpty;
        _isShowLoading = false;
        setState(() {});
      } else {
        _hanleRequestFail(isNextPage);
      }
    }).catchError((err) {
      CosLogUtil.log("$tag: fail to load messgae list of "
          "uid:${Constant.uid ?? ""}, the error is $err");
      _hanleRequestFail(isNextPage);
    }).whenComplete(() {
      if (mounted) {
        _isFetching = false;
        if (_isShowLoading) {
          setState(() {
            _isShowLoading = false;
          });
        }
      }
      if (_judgeIsNeedLoadNextPageData()) {
        httpGetMessageList(true, false);
      }
    });
  }

  bool _judgeIsNeedLoadNextPageData() {
    if ((_messageList == null || _messageList.length < _pageSize) &&
        _hasNextPage) {
      return true;
    }
    return false;
  }

  Future<bool> _reportReadMessageToServer(
      GetMessageListItemBean data, int times) async {
    bool res = false;
    if (times > 2) {
      return false;
    }
    await RequestManager.instance
        .clearMessageUnread(tag, data?.id ?? "0", Constant.uid ?? "",
            fromUid: data?.fromUid ?? "",
            type: data?.type ?? "",
            postId: data?.postId ?? "")
        .then((response) {
      if (response != null) {
        SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          res = true;
        }
      }
    });
    if (!res && times < 2) {
      _reportReadMessageToServer(data, times++);
    }
    return res;
  }

  void _hanleRequestFail(bool isNextPage) {
    if (!_isFirstSuccessLoad) {
      _isSuccessLoad = false;
    } else {
      if (!isNextPage && _isSuccessLoad) {
        _showLoadDataFailTips();
      }
    }
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

  void _listenEvent() {
    if (_eventSubscription == null) {
      _eventSubscription = EventBusHelp.getInstance().on().listen((event) {
        if (event != null) {
          //登出成功
          if (event is LoginStatusEvent) {
            if (event.type == LoginStatusEvent.typeLoginSuccess) {
              if (Common.checkIsNotEmptyStr(event.uid)) {
                _isLoggedIn = true;
                _isShowLoading = true;
                _reloadData();
                setState(() {});
              } else {
                CosLogUtil.log("$tag: success log in but get empty uid");
              }
            } else if (event.type == LoginStatusEvent.typeLogoutSuccess) {
              _resetPageData();
              setState(() {});
            }
          } else if (event is TabSwitchEvent) {
            if (event.to == BottomTabType.TabMessageCenter.index) {
              print("111111");
//              if (event.from == event.to) {
              //点击tab刷新数据或是从别的页面回到消息中心刷新
              if (_isLoggedIn && !_isFetching) {
                _isShowLoading = true;
                if (_messageCenterKey != null &&
                    _messageCenterKey.currentState != null) {
                  _messageCenterKey.currentState.scrollTo(1);
                }
                _updateView();
              }

//              }
            }
          }
        }
      });
    }
  }

  void _cancelListenEvent() {
    if (_eventSubscription != null) {
      _eventSubscription.cancel();
    }
  }

  void _resetPageData() {
    _isLoggedIn = false;
    _isFirstSuccessLoad = false;
    _isShowLoading = true;
    _isSuccessLoad = true;
    _isNoData = true;
    _isFetching = false;
    _hasNextPage = false;
    if (_messageList != null && _messageList.isNotEmpty) {
      _messageList.clear();
    }
    _lastKey = "0";
    _curPage = 1;
  }
}
