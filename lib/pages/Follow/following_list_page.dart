
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:costv_android/bean/follow_relation_list_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/widget/custom_app_bar.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/widget/custom_app_bar.dart';
import 'package:costv_android/pages/user/others_home_page.dart';

class FollowingListPage extends StatefulWidget {
   final String uid;
   FollowingListPage({this.uid}):assert(uid != null);
   @override
   State<StatefulWidget> createState() => _FollowingListPageState();
}

class _FollowingListPageState extends State<FollowingListPage> {

  static const String tag = '_FollowingListPageState';
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey = new GlobalKey<NetRequestFailTipsViewState>();
  int _pageSize = 20 , _curPage = 1;
  bool _isFetching = false, _hasNextPage = false, _isShowLoading = true, 
      _isSuccessLoad = true;
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
              setState(() {
                
              });
            },
          ), 
          isShow: _isShowLoading
      );
    }
    return  LoadingView(
      child: NetRequestFailTipsView(
        key: _failTipsKey,
        baseWidget: Container(
          color: Common.getColorFromHexString("F6F6F6", 1.0),
          child: RefreshAndLoadMoreListView(
            contentTopPadding: 10,
            pageSize: _pageSize,
            isHaveMoreData: _hasNextPage,
            itemCount: _dataList == null || _dataList.isEmpty ? 0 : _dataList.length,
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
    int listLen = _dataList?.length ?? 0;
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
    RequestManager.instance.getUserFollowingList(tag,widget.uid, nextPage, _pageSize)
    .then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("FollowingListPage: fail to fetch uid:${widget.uid}'s "
            "next page:$nextPage's data");
        return;
      }
      FollowRelationListBean bean = _parseResponse(response);
      if (bean.status == SimpleResponse.statusIntSuccess.toString()) {
        if (bean.data.list != null && bean.data.list.isNotEmpty) {
          setState(() {
            _dataList.addAll(bean.data.list);
            _curPage = nextPage;
          });
        }
        _hasNextPage = bean.data.hasnext == "1";
      } else {
        CosLogUtil.log("FollowingListPage: fail to load following list of "
            "uid:${widget.uid}'s next page:$nextPage's data, the error is ${bean.msg}");
      }
    }).catchError((error) {
      CosLogUtil.log("FollowingListPage: fail to request following list of"
          " uid:${widget.uid}'s next page:$nextPage data , the error is $error");
    }).whenComplete((){
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
    RequestManager.instance.getUserFollowingList(tag, widget.uid, 1, _pageSize)
      .then((response){
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
            _dataList = bean.data?.list ?? [];
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
        setState(() {

        });
      }
    });
  }

  FollowRelationListBean _parseResponse(Response response) {
    FollowRelationListBean bean = FollowRelationListBean.fromJson(json.decode(response.data));
    return bean;
  }

  void _showLoadDataFailTips() {
    if (_failTipsKey.currentState != null) {
      _failTipsKey.currentState.showWithAnimation();
    }
  }

  bool _checkHasFollowData() {
    if (_dataList != null && _dataList.isNotEmpty) {
      return true;
    }
    return false;
  }
}

class FollowListItem extends StatefulWidget {
  final FollowRelationData relationData;
  FollowListItem({this.relationData});
  @override
  State<StatefulWidget> createState() => _FollowListItemState();
}

class _FollowListItemState extends State<FollowListItem> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Ink(
        color: Common.getColorFromHexString("FFFFFFFF", 1.0),
        child:  InkWell(
          child:  Container(
            padding: EdgeInsets.all(10),
//        height: 56,

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //avatar
                ClipOval(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CachedNetworkImage(
                        imageUrl: widget.relationData?.avatar ?? "",
                        placeholder: (BuildContext context, String url) {
                          return Image.asset('assets/images/ic_default_avatar.png');
                        },
                        fit: BoxFit.cover,
                      ),
                    )
                ),
                //nickname
                Container(
                  margin: EdgeInsets.only(left: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 82,
                  ),
                  child: Text(
                    widget.relationData?.nickname ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,

                    ),
                  ),
                )

              ],
            ),
          ),
          onTap: (){
            _jumpToUserCenter(widget.relationData.uid);
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
//    Navigator.of(context).push(MaterialPageRoute(builder: (_){
//      return WebViewPage('${Constant.otherUserCenterWebViewUrl}$uid');
//    }));
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return OthersHomePage(OtherHomeParamsBean(
        uid: widget.relationData?.uid ?? "",
        nickName: widget.relationData?.nickname ?? '',
        avatar: widget.relationData?.avatar ?? '',
      ));
    }));
  }
}