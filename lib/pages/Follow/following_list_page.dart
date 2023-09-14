import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/follow_relation_list_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/user/others_home_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/widget/custom_app_bar.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class FollowingListPage extends StatefulWidget {
  final String uid;

  FollowingListPage({required this.uid});

  @override
  State<StatefulWidget> createState() => _FollowingListPageState();
}

class _FollowingListPageState extends State<FollowingListPage> {
  static const String tag = '_FollowingListPageState';
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey = new GlobalKey<NetRequestFailTipsViewState>();
  int _pageSize = 20, _curPage = 1;
  bool _isFetching = false, _hasNextPage = false, _isShowLoading = true, _isSuccessLoad = true;
  List<FollowRelationData> _dataList = [];

  @override
  void initState() {
    _reloadData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: InternationalLocalizations.followingListPageTitle),
      body: _getFollowingPageBody(),
    );
  }

  Widget _getFollowingPageBody() {
    if (!_isSuccessLoad) {
      return LoadingView(
          child: PageRemindWidget(
            remindType: RemindType.NetRequestFail,
            clickCallBack: () {
              _isShowLoading = true;
              _reloadData();
              setState(() {});
            },
          ),
          isShow: _isShowLoading);
    }
    return LoadingView(
      child: NetRequestFailTipsView(
        key: _failTipsKey,
        baseWidget: Container(
          color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("F6F6F6", 1.0),
            darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
          ),
          child: RefreshAndLoadMoreListView(
            contentTopPadding: 10,
            pageSize: _pageSize,
            isHaveMoreData: _hasNextPage,
            itemCount: _dataList.isEmpty ? 0 : _dataList.length,
            itemBuilder: (context, index) {
              return _getSingleItem(index);
            },
            onLoadMore: _loadNextPageData,
            onRefresh: _reloadData,
            isShowItemLine: false,
            bottomMessage: InternationalLocalizations.noMoreFollowing,
            isLoadMoreEnable: _hasNextPage,
          ),
        ),
      ),
      isShow: _isShowLoading,
    );
  }

  Widget _getSingleItem(int index) {
    int listLen = _dataList.length ?? 0;
    if (index >= 0 && index < listLen) {
      return FollowListItem(
        relationData: _dataList[index],
      );
    }
    return FollowListItem();
  }

  /*
    获取下一页数据
   */
  Future<void> _loadNextPageData() async {
    if (_isFetching || !_hasNextPage) {
      return;
    }
    _isFetching = true;
    int nextPage = _curPage + 1;
    RequestManager.instance.getUserFollowingList(tag, widget.uid, nextPage, _pageSize).then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("FollowingListPage: fail to fetch uid:${widget.uid}'s "
            "next page:$nextPage's data");
        return;
      }
      FollowRelationListBean bean = _parseResponse(response);
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data.list.isNotEmpty) {
          setState(() {
            _dataList.addAll(bean.data.list);
            _curPage = nextPage;
          });
        }
        _hasNextPage = bean.data.hasnext == "1";
      } else {
        CosLogUtil.log("FollowingListPage: fail to load following list of "
            "uid:${widget.uid}'s next page:$nextPage's data, the error is ${bean.msg}, code is ${bean.status}");
      }
    }).catchError((error) {
      CosLogUtil.log("FollowingListPage: fail to request following list of"
          " uid:${widget.uid}'s next page:$nextPage data , the error is $error");
    }).whenComplete(() {
      _isFetching = false;
    });
  }

  /*
   重新拉取首页数据
   */
  Future<void> _reloadData() async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    RequestManager.instance.getUserFollowingList(tag, widget.uid, 1, _pageSize).then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("FollowingListPage: fail to fetch following list of"
            " uid:${widget.uid}'s first page data");
        if (mounted) {
          if (!_checkHasFollowData()) {
            _isSuccessLoad = false;
          } else {
            _showLoadDataFailTips();
          }
        }
        return;
      }
      FollowRelationListBean bean = _parseResponse(response);
      if (bean.status == SimpleResponse.statusStrSuccess) {
        _dataList = bean.data.list ?? [];
        _curPage = 1;
        _hasNextPage = bean.data.hasnext == "1";
        _isSuccessLoad = true;
      } else {
        CosLogUtil.log("FollowingListPage: fail to load following list "
            "of uid:${widget.uid}, the error is ${bean.status}");
        if (_isShowLoading && _isSuccessLoad) {
          _isSuccessLoad = false;
        } else {
          _showLoadDataFailTips();
        }
      }
    }).catchError((error) {
      CosLogUtil.log("FollowingListPage: fail to request following list of "
          "uid:${widget.uid}'s first page data, the error is $error");
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

  FollowRelationListBean _parseResponse(Response response) {
    FollowRelationListBean bean = FollowRelationListBean.fromJson(json.decode(response.data));
    return bean;
  }

  void _showLoadDataFailTips() {
    if (_failTipsKey.currentState != null) {
      _failTipsKey.currentState?.showWithAnimation();
    }
  }

  bool _checkHasFollowData() {
    if (_dataList.isNotEmpty) {
      return true;
    }
    return false;
  }
}

class FollowListItem extends StatefulWidget {
  final FollowRelationData? relationData;

  FollowListItem({this.relationData});

  @override
  State<StatefulWidget> createState() => _FollowListItemState();
}

class _FollowListItemState extends State<FollowListItem> {
  @override
  Widget build(BuildContext context) {
    String avatar = widget.relationData?.anchorImageCompress?.avatarCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(avatar)) {
      avatar = widget.relationData?.avatar ?? '';
    }
    return Material(
      color: Colors.transparent,
      child: Ink(
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("FFFFFFFF", 1.0), darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
        child: InkWell(
          child: Container(
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.color_ebebeb, width: AppDimens.item_line_height_0_5),
                    borderRadius: BorderRadius.circular(AppDimens.item_size_25),
                  ),
                  child: Stack(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: AppColors.color_ffffff,
                        radius: AppDimens.item_size_25,
                        backgroundImage: AssetImage('assets/images/ic_default_avatar.png'),
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.color_transparent,
                        radius: AppDimens.item_size_25,
                        backgroundImage: CachedNetworkImageProvider(
                          avatar,
                        ),
                      ),
                    ],
                  ),
                ),
                //avatar
                //nickname
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 12),
                    child: Text(
                      widget.relationData?.nickname ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                            lightColor: Colors.black, darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr),
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          onTap: () {
            _jumpToUserCenter(widget.relationData?.uid ?? "");
          },
        ),
      ),
    );
  }

  void _jumpToUserCenter(String uid) {
//    if (uid == null  || uid.length < 1) {
//      CosLogUtil.log("FollowingListPage: can't open webview due to uid is empty");
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
        ));
      },
    ));
  }
}
