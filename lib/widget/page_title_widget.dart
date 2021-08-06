import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/account_get_info_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/login_status_event.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/search/popupwindow/search_title_window.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/widget/popupwindow/popup_window.dart';
import 'package:costv_android/widget/popupwindow/popup_window_route.dart';
import 'package:flutter/material.dart';

class PageTitleWidget extends StatefulWidget {
  final String tag;

  PageTitleWidget(this.tag, {Key key}) : super(key: key);

  @override
  _PageTitleWidgetState createState() => _PageTitleWidgetState();
}

class _PageTitleWidgetState extends State<PageTitleWidget> {
  String _avatar;
  StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _listenEvent();
    if(!ObjectUtil.isEmptyString(Constant.uid)){
      _httpUserInfo(Constant.uid);
    }
  }

  void _listenEvent() {
    if (_subscription == null) {
      _subscription = EventBusHelp.getInstance().on().listen((event) {
        if (event != null && event is LoginStatusEvent) {
          if (event.type == LoginStatusEvent.typeLoginSuccess &&
              event.uid != null) {
            _httpUserInfo(event.uid ?? '');
          } else if (event.type == LoginStatusEvent.typeLogoutSuccess) {
            setState(() {
              _avatar = '';
            });
          }
        }
      });
    }
  }

  /// 读取用户信息
  void _httpUserInfo(String uid) {
    RequestManager.instance.accountGetInfo(widget.tag, uid).then((response) {
      if (response == null || !mounted) {
        return;
      }
      AccountGetInfoBean bean =
          AccountGetInfoBean.fromJson(json.decode(response.data));
      if (bean != null &&
          bean.status == SimpleResponse.statusStrSuccess &&
          bean.data != null &&
          !ObjectUtil.isEmptyString(bean.data.avatar)) {
        setState(() {
          _avatar = bean.data.avatar;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: AppDimens.margin_15,
        right: AppDimens.margin_10,
      ),
//      height: AppDimens.item_size_45,
      height: kToolbarHeight,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image.asset('assets/images/ic_title_logo.png'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Material(
                color: AppColors.color_transparent,
                child: Ink(
                  child: InkWell(
                    child: Container(
                      padding: EdgeInsets.all(AppDimens.margin_5),
                      child: Image.asset('assets/images/ic_title_search.png'),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        PopupWindowRoute(
                          child: PopupWindow(
                            SearchTitleWindow(
                                widget.tag, SearchTitleWindow.fromHome),
                            left: 0,
                            top: 0,
                            backgroundColor: AppColors.color_66000000,
                          ),
                        ),
                      );
                      _reportSearchClick();
                    },
                  ),
                ),
              ),
              Material(
                color: AppColors.color_transparent,
                child: Ink(
                  child: InkWell(
                    child: Container(
                      padding: EdgeInsets.only(
                          left: AppDimens.margin_15,
                          top: AppDimens.margin_5,
                          right: AppDimens.margin_5,
                          bottom: AppDimens.margin_5),
                      child: Image.asset('assets/images/ic_title_pop.png'),
                    ),
                    onTap: () {
                      _reportPopClick();
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) {
                        return WebViewPage(
                          Constant.popcornWebViewUrl,
                        );
                      }));
                    },
                  ),
                ),
              ),
              Material(
                color: AppColors.color_transparent,
                child: Ink(
                  child: InkWell(
                    child: Container(
                      margin: EdgeInsets.only(
                          left: AppDimens.margin_15,
                          top: AppDimens.margin_5,
                          right: AppDimens.margin_5,
                          bottom: AppDimens.margin_5),
                      child: Stack(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: AppColors.color_ffffff,
                            radius: AppDimens.item_size_12_5,
                            backgroundImage: AssetImage(
                                'assets/images/ic_title_default_avatar.png'),
                          ),
                          CircleAvatar(
                            backgroundColor: AppColors.color_transparent,
                            radius: AppDimens.item_size_12_5,
                            backgroundImage: CachedNetworkImageProvider(
                              _avatar ?? '',
                            ),
                          )
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) {
                        return WebViewPage(
                          ObjectUtil.isEmptyString(Constant.uid)
                              ? Constant.logInWebViewUrl
                              : Constant.userCenterWebWebViewUrl,
                        );
                      }));
                    },
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _reportPopClick() {
    DataReportUtil.instance.reportData(
        eventName: "Click_pop",
        params: {"Click_pop": "1"},
    );
  }

  void _reportSearchClick() {
    DataReportUtil.instance.reportData(
      eventName: "Click_search",
      params: {"Click_search": "1"},
    );
  }
}
