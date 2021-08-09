import 'dart:async';
import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/get_uid_unread_total_bean.dart';
import 'package:costv_android/bean/push_message_fcm_bean.dart';
import 'package:costv_android/bean/push_message_fcm_vip_bean.dart';
import 'package:costv_android/bean/web_page_api_data_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/db/login_info_db_bean.dart';
import 'package:costv_android/db/login_info_db_provider.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/login_status_event.dart';
import 'package:costv_android/event/tab_switch_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/comment/bean/comment_list_parameter_bean.dart';
import 'package:costv_android/pages/comment/comment_children_list_page.dart';
import 'package:costv_android/pages/comment/comment_list_page.dart';
import 'package:costv_android/pages/home_page.dart';
import 'package:costv_android/pages/message_page.dart';
import 'package:costv_android/pages/my_subscription_page.dart';
import 'package:costv_android/pages/popular_page.dart';
import 'package:costv_android/pages/recently_watched_page.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import "package:costv_android/utils/global_util.dart";
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock/wakelock.dart';

class MainPage extends StatefulWidget {
  MainPage({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  static const tag = '_MainPageState';
  static const String channelPushMessage = "com.contentos.plugin/push_message";
  static const String pushMessageOpenPage = "open_page";
  static const String pushMessageOpenHome = "open_home";
  static const String channelLogin = "com.contentos.plugin/login";
  static const String loginSetLoginInfo = "set_login_info";
  static const String channelWebView = "com.contentos.plugin/web_view";
  static const String webViewOpenVideoDetails = "open_video_details";
  static const String webViewLoginInfo = "login_info";
  static const String webViewLogout = "logout";
  static const String webViewOpenVideoPlayPage = "open_video_play_page";
  static const int tabIndexNotification = 3;

  var _tabImages;
  int _tabIndex = 0;
  StreamSubscription _streamSubscription;
  static const _methodChannelPush = const MethodChannel(channelPushMessage);
  static const _methodChannelWebView = const MethodChannel(channelWebView);
  int _total = 0;

  @override
  void initState() {
    super.initState();
    // 保持屏幕唤醒
    Wakelock.enable();
    _initData();
    _methodChannelPush.setMethodCallHandler(_listenPushMessage);
    _methodChannelWebView.setMethodCallHandler(_listenWebView);
//    VideoSmallWindowsUtil.instance.getPlatformSdk
//        .setMethodCallHandler(_listenVideoSmallWindows);
    _listenBusEvent();
    _httpAddDevice();
    if (!ObjectUtil.isEmptyString(Constant.uid)) {
      _httpGetUidUnreadTotal();
    }
  }

  @override
  void dispose() {
    super.dispose();
    RequestManager.instance.cancelAllNetworkRequest(tag);
    if (_streamSubscription != null) {
      _streamSubscription.cancel();
      _streamSubscription = null;
    }
  }

  _initData() {
    _tabImages = [
      [
        Image.asset(AppThemeUtil.getUnselectedHomeIcn()),
        Image.asset(AppThemeUtil.getSelectedHomeIcn())
      ],
      [
        Image.asset(AppThemeUtil.getUnselectedHotIcn()),
        Image.asset(AppThemeUtil.getSelectedHotIcn())
      ],
      [
        Image.asset(AppThemeUtil.getUnselectedSubSubscriptionIcn()),
        Image.asset(AppThemeUtil.getSelectedSubSubscriptionIcn())
      ],
      [
        Image.asset(AppThemeUtil.getUnSelectedMessageCenterIcn()),
        Image.asset(AppThemeUtil.getSelectedMessageCenterIcn())
      ],
      [
        Image.asset(AppThemeUtil.getUnselectedHistoryIcn()),
        Image.asset(AppThemeUtil.getSelectedHistoryIcn())
      ]
    ];
  }

  Future<dynamic> _listenPushMessage(MethodCall methodCall) async {
    String pushInfo = methodCall.arguments;
    switch (methodCall.method) {
      case pushMessageOpenPage:
        if (!ObjectUtil.isEmptyString(pushInfo)) {
          String anchorId;
          String vid;
          if (json.decode(pushInfo)[PushMessageFcmVipBean.keyIsV] ==
              PushMessageFcmVipBean.isVYes) {
            PushMessageFcmVipBean bean =
                PushMessageFcmVipBean.fromJson(json.decode(pushInfo));
            anchorId = bean?.fromUid ?? '';
            vid = bean?.vid ?? '';
            _httpClearVipMessageUnread(bean);
            Future.delayed(Duration(seconds: 1), () {
              Navigator.of(context).push(SlideAnimationRoute(
                builder: (_) {
                  return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
                    vid: bean?.vid ?? '',
                    uid: bean?.fromUid ?? '',
                    enterSource: VideoDetailsEnterSource
                        .VideoDetailsEnterSourceNotification,
                  ));
                },
                settings: RouteSettings(name: videoDetailPageRouteName),
                isCheckAnimation: true,
              ));
            });
          } else {
            PushMessageFcmBean bean =
                PushMessageFcmBean.fromJson(json.decode(pushInfo));
            anchorId = bean?.anchorId ?? '';
            vid = bean?.vid ?? '';
            _httpClearMessageUnread(bean);
            Future.delayed(Duration(seconds: 1), () {
              CommentListParameterBean commentListParameterBean =
                  CommentListParameterBean();
              commentListParameterBean.videoId = bean?.vid ?? '';
              commentListParameterBean.vid = bean?.vid ?? '';
              commentListParameterBean.creatorUid = bean?.toUid ?? '';
              commentListParameterBean.cid = bean?.postId ?? '';
              commentListParameterBean.nickName = bean?.fromNickName ?? '';
              commentListParameterBean.pid = bean?.pid ?? '';
              commentListParameterBean.uid = bean?.fromUid ?? '';
              if (bean.type == PushMessageFcmBean.typeCommentLike) {
                if (ObjectUtil.isEmptyString(bean.pid)) {
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
              } else if (bean.type == PushMessageFcmBean.typeVideoComment) {
                Navigator.of(context).push(SlideAnimationRoute(
                  builder: (_) {
                    return CommentListPage(commentListParameterBean);
                  },
                ));
              } else if (bean.type == PushMessageFcmBean.typeReplyToComment) {
                Navigator.of(context).push(SlideAnimationRoute(
                  builder: (_) {
                    return CommentChildrenListPage(commentListParameterBean);
                  },
                ));
              } else {
                Navigator.of(context).push(SlideAnimationRoute(
                  builder: (_) {
                    return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
                      vid: bean?.vid ?? '',
                      uid: bean?.anchorId ?? '',
                      enterSource: VideoDetailsEnterSource
                          .VideoDetailsEnterSourceNotification,
                    ));
                  },
                  settings: RouteSettings(name: videoDetailPageRouteName),
                  isCheckAnimation: true,
                ));
              }
            });
          }
          reportClickPush(anchorId, vid);
        }
        break;
      case pushMessageOpenHome:
        if (!ObjectUtil.isEmptyString(pushInfo)) {
          PushMessageFcmBean bean =
              PushMessageFcmBean.fromJson(json.decode(pushInfo));
          reportClickPush(bean?.anchorId ?? '', bean?.vid ?? '');
        }
        setState(() {
          _tabIndex = 0;
        });
        break;
    }
  }

  void reportClickPush(String anchorId, String vid) {
    DataReportUtil.instance.reportData(
      eventName: "Click_Push",
      params: {
        "creator_uid": anchorId ?? '',
        "vid": vid ?? '',
        "uid": Constant.uid ?? '0',
      },
    );
  }

  Future<dynamic> _listenWebView(MethodCall methodCall) async {
    switch (methodCall.method) {
      case webViewOpenVideoDetails:
        String vid = methodCall.arguments;
        if (!ObjectUtil.isEmptyString(vid)) {
          Navigator.of(context).push(SlideAnimationRoute(
            builder: (_) {
              return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
                vid: vid,
                enterSource: VideoDetailsEnterSource
                    .VideoDetailsEnterSourceH5LikeRewardVideo,
              ));
            },
            settings: RouteSettings(name: videoDetailPageRouteName),
            isCheckAnimation: true,
          ));
        }
        break;
      case webViewLoginInfo:
        String data = methodCall.arguments;
        if (!ObjectUtil.isEmptyString(data)) {
          WebPageApiAccessTokenInfoBean bean =
              WebPageApiAccessTokenInfoBean.fromJson(json.decode(data));
          if (bean != null &&
              bean.uid != null &&
              !ObjectUtil.isEmptyString(bean.token) &&
              !ObjectUtil.isEmptyString(bean.chainAccountName) &&
              bean.expires != null) {
            Constant.uid = bean.uid;
            Constant.token = bean.token;
            Constant.accountName = bean.chainAccountName;
            LoginInfoDbBean loginInfoDbBean = LoginInfoDbBean(
                bean.uid, bean.token, bean.chainAccountName, bean.expires);
            CosLogUtil.log(
                '$tag webViewLoginInfo LoginInfoDbBean{ uid: ${bean.uid}, token: ${bean.token}, chainAccountName: ${bean.chainAccountName}, expires: ${bean.expires}');
            LoginInfoDbProvider loginInfoDbProvider = LoginInfoDbProvider();
            try {
              await loginInfoDbProvider.open();
              LoginInfoDbBean loginInfoDbOld =
                  await loginInfoDbProvider.getLoginInfoDbBean();
              if (loginInfoDbOld == null) {
                await loginInfoDbProvider.insert(loginInfoDbBean);
              } else {
                await loginInfoDbProvider.update(loginInfoDbBean);
              }
            } catch (e) {
              CosLogUtil.log("$tag: e = $e");
            } finally {
              await loginInfoDbProvider.close();
            }
            LoginStatusEvent loginStatusEvent =
                LoginStatusEvent(LoginStatusEvent.typeLoginSuccess);
            loginStatusEvent.uid = bean.uid;
            EventBusHelp.getInstance().fire(loginStatusEvent);
          }
        }
        break;
      case webViewLogout:
        Constant.uid = null;
        Constant.token = null;
        Constant.accountName = null;
        LoginInfoDbProvider loginInfoDbProvider = LoginInfoDbProvider();
        try {
          await loginInfoDbProvider.open();
          await loginInfoDbProvider.deleteAll();
        } catch (e) {
          CosLogUtil.log("$tag: e = $e");
        } finally {
          await loginInfoDbProvider.close();
        }
        EventBusHelp.getInstance()
            .fire(LoginStatusEvent(LoginStatusEvent.typeLogoutSuccess));
        break;
      case webViewOpenVideoPlayPage:
        String data = methodCall.arguments;
        if (!ObjectUtil.isEmptyString(data)) {
          WebPageApiVideoIdBean bean =
              WebPageApiVideoIdBean.fromJson(json.decode(data));
          Navigator.of(context).push(SlideAnimationRoute(
            builder: (_) {
              return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
                  vid: bean?.vid ?? '',
                  uid: bean?.fuid ?? '',
                  enterSource: VideoDetailsEnterSource
                      .VideoDetailsEnterSourceVideoDetail));
            },
            settings: RouteSettings(name: videoDetailPageRouteName),
            isCheckAnimation: true,
          ));
        }
        break;
    }
  }

//  Future<dynamic> _listenVideoSmallWindows(MethodCall methodCall) async {
//    switch (methodCall.method) {
//      case VideoSmallWindowsUtil.videoSmallWindowsOpenVideoDetails:
//        String videoData = methodCall.arguments;
//        if (!ObjectUtil.isEmptyString(videoData)) {
//          GetVideoInfoDataBean bean =
//              GetVideoInfoDataBean.fromJson(json.decode(videoData));
//          if (bean != null) {
//            Navigator.of(context).push(SlideAnimationRoute(
//                widget:
//                    VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
//                  vid: bean?.id ?? '',
//                  uid: bean?.uid ?? '',
//                  videoSource: bean?.videosource ?? '',
//                  enterSource: VideoDetailsEnterSource
//                      .VideoDetailsEnterSourceVideoSmallWindows,
//                )),
//                settings: RouteSettings(name: videoDetailPageRouteName)));
//          }
//        }
//        break;
//    }
//  }

  void _listenBusEvent() {
    EventBusHelp.getInstance().on<LoginStatusEvent>().listen((event) {
      if (event != null && event is LoginStatusEvent) {
        if (event.type == LoginStatusEvent.typeLoginSuccess) {
          _httpAddDevice();
        }
      }
    });
  }

  /// app设备上报接口
  void _httpAddDevice() {
    RequestManager.instance.addDevice(tag, Constant.uid ?? '').then((response) {
      if (response == null || !mounted) {
        return;
      }
    });
  }

  /// 获取用户未读总数
  void _httpGetUidUnreadTotal() {
    RequestManager.instance
        .getUidUnreadTotal(tag, Constant.uid ?? '')
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      GetUidUnreadTotalBean bean =
          GetUidUnreadTotalBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess &&
          bean.getUidUnreadTotalDataBean != null &&
          !ObjectUtil.isEmptyString(bean.getUidUnreadTotalDataBean.total)) {
        _total = int.parse(bean.getUidUnreadTotalDataBean.total);
        if (_total > 0) {
          setState(() {});
        }
      }
    });
  }

  /// 清除普通用户消息未读
  void _httpClearMessageUnread(PushMessageFcmBean bean) {
    if (bean != null &&
        (!ObjectUtil.isEmptyString(Constant.uid) ||
            !ObjectUtil.isEmptyString(bean.toUid))) {
      Future<Response> response;
      String uid = Constant.uid ?? '';
      if (ObjectUtil.isEmptyString(uid)) {
        uid = bean.toUid;
      }
      String postId = '';
      if (bean.type == PushMessageFcmBean.typeVideoRelease) {
        postId = bean.vid ?? '';
      } else if (bean.type == PushMessageFcmBean.typeVideoLike) {
        postId = bean.vid ?? '';
      } else if (bean.type == PushMessageFcmBean.typeCommentLike) {
        if (bean.id != null) {
          postId = bean.id.toString();
        }
      } else if (bean.type == PushMessageFcmBean.typeVideoComment) {
        postId = bean.vid ?? '';
      } else if (bean.type == PushMessageFcmBean.typeReplyToComment) {
        if (bean.id != null) {
          postId = bean.id.toString();
        }
      } else if (bean.type == PushMessageFcmBean.typeVideoGift) {
        postId = bean.vid ?? '';
      }
      if (bean.id != null && bean.id > 0) {
        response = RequestManager.instance
            .clearMessageUnread(tag, bean.id.toString(), uid);
      } else {
        response = RequestManager.instance.clearMessageUnread(tag, '0', uid,
            fromUid: bean.fromUid ?? '',
            vid: bean.vid ?? '',
            type: bean.type.toString(),
            postId: postId);
      }
      response.then((response) {
        if (response == null || !mounted) {
          return;
        }
      });
    }
  }

  /// 清除大V用户消息未读
  void _httpClearVipMessageUnread(PushMessageFcmVipBean bean) {
    if (bean != null &&
        (!ObjectUtil.isEmptyString(Constant.uid) ||
            !ObjectUtil.isEmptyString(bean.toUid))) {
      Future<Response> response;
      String uid = Constant.uid ?? '';
      if (ObjectUtil.isEmptyString(uid)) {
        uid = bean.toUid;
      }
      if (bean.id != null && bean.id > 0) {
        response = RequestManager.instance
            .clearMessageUnread(tag, bean.id.toString(), uid);
      } else {
        response = RequestManager.instance.clearMessageUnread(tag, '0', uid,
            fromUid: bean.fromUid ?? '',
            vid: bean.vid ?? '',
            type: bean.type.toString(),
            postId: bean.postId.toString());
      }
      response.then((response) {
        if (response == null || !mounted) {
          return;
        }
      });
    }
  }

  TextStyle _getTabTextStyle(int curIndex) {
    Color color;
    if (curIndex == _tabIndex) {
      color = AppThemeUtil.setDifferentModeColor(
        lightColor: AppColors.color_3674ff,
        darkColor: AppColors.color_ffffff,
      );
    } else {
      color = AppThemeUtil.setDifferentModeColor(
        lightColor: AppColors.color_333333,
        darkColorStr: "A0A0A0",
      );
    }
    return TextStyle(
      fontSize: AppDimens.text_size_9,
      color: color,
    );
  }

  Widget _getTabIcon(int curIndex) {
    if (curIndex == _tabIndex) {
      return _tabImages[curIndex][1];
    }
    return _tabImages[curIndex][0];
  }

  Widget _buildBottomTableItem(
      int index, double messageMargin, bool isHaveNumber) {
    String showMsg;
    if (index == 0) {
      showMsg = InternationalLocalizations.homeTitle;
    } else if (index == 1) {
      showMsg = InternationalLocalizations.homePopularTitle;
    } else if (index == 2) {
      showMsg = InternationalLocalizations.homeMySubscriptionTitle;
    } else if (index == 3) {
      showMsg = InternationalLocalizations.homeMessage;
    } else if (index == 4) {
      showMsg = InternationalLocalizations.homeSeeHistoryTitle;
    }
    String showWTotal = '0';
    if (isHaveNumber && _total > 0) {
      if (_total > 999) {
        showWTotal = '999+';
      } else {
        showWTotal = _total.toString();
      }
    }
    double itemWidth = (MediaQuery.of(context).size.width) / 5;
    return InkWell(
      onTap: () {
        _clickTable(index);
      },
      child: Container(
        margin: EdgeInsets.only(top: AppDimens.margin_2),
        width: itemWidth,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _getTabIcon(index),
                Container(
                  margin: EdgeInsets.only(top: messageMargin),
                  child: Text(showMsg, style: _getTabTextStyle(index)),
                )
              ],
            ),
            Offstage(
              offstage: (!isHaveNumber || _total <= 0),
              child: Container(
                width: AppDimens.item_size_15,
                height: AppDimens.item_size_15,
                margin: EdgeInsets.only(left: AppDimens.margin_23),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.color_fd3232,
                  border: Border.all(
                      color: AppColors.color_ffffff,
                      width: AppDimens.item_line_height_1),
                ),
                child: Text(
                  showWTotal,
                  style: AppStyles.text_style_ffffff_9,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMenu() {
    return Container(
      color: _getTabBarBgColor(),
      height: AppDimens.item_size_49,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildBottomTableItem(0, AppDimens.margin_4, false),
          _buildBottomTableItem(1, AppDimens.margin_4, false),
          _buildBottomTableItem(2, AppDimens.margin_5, false),
          _buildBottomTableItem(3, AppDimens.margin_5, true),
          _buildBottomTableItem(4, AppDimens.margin_4, false),
        ],
      ),
    );
  }

  _clickTable(index) {
    EventBusHelp.getInstance().fire(TabSwitchEvent(curTabIndex, index));
    curTabIndex = index;
    if (index == tabIndexNotification) {
      _total = 0;
      DataReportUtil.instance
          .reportData(eventName: "Click_Tab_notice", params: {});
    } else {
      if (!ObjectUtil.isEmptyString(Constant.uid)) {
        _httpGetUidUnreadTotal();
      }
    }
    setState(() {
      _tabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    mainContext = context;
    _initData();
    return Scaffold(
      body: IndexedStack(
        children: <Widget>[
          HomePage(),
          PopularPage(),
          MySubscriptionPage(),
          MessagePage(),
          RecentlyWatchedPage(),
        ],
        index: _tabIndex,
      ),
      bottomNavigationBar: _buildBottomMenu(),
    );
  }

  Color _getTabBarBgColor() {
    return AppThemeUtil.setDifferentModeColor(
        lightColorStr: "FFFFFFF",
        darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr);
  }
}
