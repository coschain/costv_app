
import 'dart:convert';

import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/widget/custom_app_bar.dart';
import 'package:costv_android/widget/history_video_item.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import "package:costv_android/widget/page_remind_widget.dart";
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:cosdart/types.dart';

Color itemColor = Common.getColorFromHexString("3F3F3F3F", 0.05);
final pageLogPrefix = "UserLikeVideoPage";

class UserLikedVideoPage extends StatefulWidget {
  final String uid;
  UserLikedVideoPage({@required this.uid});
  @override
  State<StatefulWidget> createState() {
    return _UserLikedVideoPageState();
  }
}

class _UserLikedVideoPageState extends State<UserLikedVideoPage> {

  static const String tag = '_UserLikedVideoPageState';
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey = new GlobalKey<NetRequestFailTipsViewState>();
  int _pageSize = 20, _page = 1;
  bool _hasNextPage = false, _isFetching = false, _isShowLoading = true,
      _isDeleting = false, _isSuccessLoad = true;
  List<GetVideoListNewDataListBean> _videoList = [];
  ExchangeRateInfoData _rateInfo;
  dynamic_properties _chainDgpo;
  @override
  void initState() {
    _reloadData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: InternationalLocalizations.likedVideoTitle,),
      body: _getPageBody(),

    );

  }

  Widget _getPageBody() {
    if (!_isSuccessLoad) {
      return LoadingView(
        isShow: _isShowLoading,
        child: PageRemindWidget(
          remindType: RemindType.NetRequestFail,
          clickCallBack: () {
            _isShowLoading = true;
            _reloadData();
            setState(() {

            });
          },
        ),
      );
    }
    return LoadingView(
      isShow: _isShowLoading,
      child: NetRequestFailTipsView(
        key: _failTipsKey,
        baseWidget: Container(
          color: Common.getColorFromHexString("3F3F3F3F", 0.05),
          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: RefreshAndLoadMoreListView(
            itemCount: _videoList?.length ?? 0,
            itemBuilder: (BuildContext context, int position) {
              return _getHistoryVideoItem(position);
            },
            isHaveMoreData: _hasNextPage,
            onRefresh: _reloadData,
            onLoadMore: () {
              _loadNextPageData();
            },
            isRefreshEnable: true,
            isLoadMoreEnable: true,
            bottomMessage: InternationalLocalizations.noMoreOperateVideo,
          ),
        ),
      ),

    );
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
      reqList = [_loadLikedVideoList(false),
        CosSdkUtil.instance.getChainState(),VideoUtil.requestExchangeRate(tag)];
    } else {
      reqList = [_loadLikedVideoList(false),
        CosSdkUtil.instance.getChainState(), VideoUtil.requestExchangeRate(tag)];
    }
    Future.wait(
      reqList,
    ).then((valList) {
      if (valList != null && mounted) {
        int resLen = valList?.length ?? 0;
        List<GetVideoListNewDataListBean> videoList;
        ExchangeRateInfoData rateData = _rateInfo;
        dynamic_properties dgpo = _chainDgpo;
        if (resLen >= 1) {
          videoList = valList[0];
        }
        if (resLen >= 2) {
          GetChainStateResponse bean = valList[1];
          if (bean != null && bean.state != null && bean.state.dgpo != null) {
            dgpo= bean.state.dgpo;
            _chainDgpo = dgpo;
          }
        }

        if (isNeedLoadRate && resLen >= 3) {
          rateData = valList[2];
          if (rateData != null) {
            _rateInfo = rateData;
          }
        }

        if (videoList != null) {
          _videoList = videoList;
          _isSuccessLoad = true;
          _page = 1;
          setState(() {

          });
        } else if (_isShowLoading && _isSuccessLoad) {
          _isSuccessLoad = false;
        } else {
          _showDataLoadFailTips();
        }
      } else if (mounted && valList == null && !VideoUtil.checkVideoListIsNotEmpty(_videoList)) {
        _isSuccessLoad = false;
      }
    }).catchError((err) {
      CosLogUtil.log("$pageLogPrefix: fail to reload data, the error is $err");
      if (_isShowLoading && _isSuccessLoad && !VideoUtil.checkVideoListIsNotEmpty(_videoList)) {
        _isSuccessLoad = false;
      } else {
        _showDataLoadFailTips();
      }

    }).whenComplete(() {
      _isFetching = false;
      if (mounted && _isShowLoading) {
        _isShowLoading = false;
        setState(() {

        });
      }
    });
    return;

  }

  Future<void> _loadNextPageData() async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    await _loadLikedVideoList(true);
    _isFetching = false;
  }

  ///获取点赞历史数据
  Future<List<GetVideoListNewDataListBean>> _loadLikedVideoList(bool isNextPage) async {
    List<GetVideoListNewDataListBean> list;
    if (isNextPage && !_hasNextPage) {
      return list;
    }
    int page = isNextPage ? _page+1 : 0;
    await RequestManager.instance.getUserLikedVideoList(tag, widget.uid,
        _page.toString(), _pageSize.toString()).then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("$pageLogPrefix: fail to request uid:${widget.uid}'s "
            "liked video list");
        return;
      }
      GetVideoListNewBean bean = GetVideoListNewBean.fromJson(json.decode(response.data));
      bool isSuccess = (bean.status == SimpleResponse.statusStrSuccess);
      List<GetVideoListNewDataListBean> dataList = isSuccess ? (bean.data?.list ?? []) : [];
      list = dataList;
      if (isSuccess) {
        _hasNextPage = bean.data.hasNext == "1";
        if (isNextPage) {
          if (dataList.isNotEmpty) {
            _videoList.addAll(dataList);
            _page = page;
          }
          setState(() {

          });
        }

      } else {
        CosLogUtil.log("$pageLogPrefix: fail to request uid:${widget.uid}'s "
            "liked video list of page:$page, the error msg is ${bean.message}, "
            "error code is ${bean.status}");
      }
    }).catchError((err) {
      CosLogUtil.log("$pageLogPrefix: fail to load liked video list of "
          "uid:${widget.uid}, the error is $err");
    }).whenComplete(() {
    });
    return list;
  }


  HistoryVideoItem _getHistoryVideoItem(int idx) {
    int listCnt = _videoList?.length ?? 0;
    if (idx >= 0 && idx < listCnt) {
      return HistoryVideoItem(
        isEnableDelete: false,
        video: _videoList[idx],
        exchangeRate: _rateInfo,
        dgpoBean: _chainDgpo,
        source: HistoryItemPageSource.likedVideoListPage,
      );
    }
    return HistoryVideoItem();
  }

  void _showDataLoadFailTips() {
    if (_failTipsKey.currentState != null) {
      _failTipsKey.currentState.showWithAnimation();
    }
  }
}