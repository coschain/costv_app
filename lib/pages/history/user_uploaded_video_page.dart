import 'dart:convert';

import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/my_video_list_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/widget/custom_app_bar.dart';
import 'package:costv_android/widget/uploaded_video_item.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import "package:costv_android/widget/page_remind_widget.dart";
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:flutter/material.dart';
import 'package:cosdart/types.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

Color itemColor = Common.getColorFromHexString("3F3F3F3F", 0.05);
final pageLogPrefix = "UploadedVideoPage";

typedef DeleteVideoCallback = void Function(String uid, String vid);

class UploadedVideos extends StatefulWidget {
  final String uid;

  UploadedVideos({required this.uid});

  @override
  State<StatefulWidget> createState() {
    return _UploadedVideostate();
  }
}

class _UploadedVideostate extends State<UploadedVideos> with TickerProviderStateMixin {
  static const String tag = '_UploadedVideostate';
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey = new GlobalKey<NetRequestFailTipsViewState>();
  int _pageSize = 20;
  bool _hasNextPage = false, _isFetching = false, _isShowLoading = true, _isDeleting = false, _isSuccessLoad = true, _isScrolling = false;
  String _lastKey = "0";
  List<MyVideoInfoBean> _videoList = [];
  ExchangeRateInfoData? _rateInfo;
  dynamic_properties? _chainDgpo;
  Map<int, double> _visibleFractionMap = {};
  late SlidableController _slidableController;

  @override
  void initState() {
    _reloadData();
    super.initState();
    _slidableController = SlidableController(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: InternationalLocalizations.myUploadedVideos,
      ),
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
            setState(() {});
          },
        ),
      );
    }
    return LoadingView(
      isShow: _isShowLoading,
      child: NetRequestFailTipsView(
        key: _failTipsKey,
        baseWidget: Container(
          color: AppThemeUtil.setDifferentModeColor(
              lightColor: Common.getColorFromHexString("3F3F3F3F", 0.05), darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: RefreshAndLoadMoreListView(
            itemCount: _videoList.length ?? 0,
            itemBuilder: (BuildContext context, int position) {
              if (!_isScrolling) {
                _visibleFractionMap[position] = 1;
              }
              return _getUploadedVideoItem(position);
            },
            isHaveMoreData: _hasNextPage,
            onRefresh: _reloadData,
            onLoadMore: () {
              _loadNextPageData();
            },
            isRefreshEnable: true,
            isLoadMoreEnable: true,
            bottomMessage: InternationalLocalizations.userNoMoreVideo,
            scrollStatusCallBack: (scrollNotification) {
              if (scrollNotification is ScrollStartCallBack || scrollNotification is ScrollUpdateNotification) {
                _isScrolling = true;
              } else if (scrollNotification is ScrollEndNotification) {
                _isScrolling = false;
                Future.delayed(Duration(milliseconds: 500), () {
                  if (!_isScrolling) {
                    _reportVideoExposure();
                  }
                });
              }
            },
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
      reqList = [_loadUploadedVideoList(false), CosSdkUtil.instance.getChainState(), VideoUtil.requestExchangeRate(tag)];
    } else {
      reqList = [_loadUploadedVideoList(false), CosSdkUtil.instance.getChainState(), VideoUtil.requestExchangeRate(tag)];
    }
    await Future.wait(
      reqList,
    ).then((valList) {
      if (mounted) {
        int resLen = valList.length ?? 0;
        List<MyVideoInfoBean>? videoList;
        ExchangeRateInfoData? rateData = _rateInfo;
        dynamic_properties? dgpo = _chainDgpo;
        if (resLen >= 1) {
          videoList = valList[0];
        }
        if (resLen >= 2) {
          GetChainStateResponse bean = valList[1];
          dgpo = bean.state.dgpo;
          _chainDgpo = dgpo;
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
          setState(() {
            Future.delayed(Duration(seconds: 1), () {
              if (!_isScrolling) {
                _reportVideoExposure();
              }
            });
          });
        } else if (_isShowLoading && _isSuccessLoad) {
          _isSuccessLoad = false;
        } else {
          _showLoadDataFailTips();
        }
      } else if (mounted && valList == null && (_videoList.isEmpty)) {
        _isSuccessLoad = false;
      }
    }).catchError((err) {
      CosLogUtil.log("$pageLogPrefix: fail to reload data, the error is $err");
      if (_isShowLoading && _isSuccessLoad && (_videoList.isEmpty)) {
        _isSuccessLoad = false;
      } else {
        _showLoadDataFailTips();
      }
    }).whenComplete(() {
      _isFetching = false;
      if (mounted && _isShowLoading) {
        _isShowLoading = false;
        setState(() {});
      }
    });
    return;
  }

  Future<void> _loadNextPageData() async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    await _loadUploadedVideoList(true);
    _isFetching = false;
  }

  ///获取观看历史数据
  Future<List<MyVideoInfoBean>?> _loadUploadedVideoList(bool isNextPage) async {
    List<MyVideoInfoBean>? list;
    if (isNextPage && !_hasNextPage) {
      return list;
    }
    String page = isNextPage ? _lastKey : "1";
    await RequestManager.instance.getMyVideos(tag, page: int.parse(page), pageSize: _pageSize).then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("$pageLogPrefix: fail to request uid:${widget.uid}'s "
            "uploaded video list");
        return;
      }
      MyVideoListBean bean = MyVideoListBean.fromJson(json.decode(response.data));
      bool isSuccess = (bean.status == SimpleResponse.statusStrSuccess);
      List<MyVideoInfoBean> dataList = isSuccess ? (bean.data.list ?? []) : [];
      list = dataList;
      if (isSuccess) {
        _hasNextPage = bean.data.has_next == "1";
        _lastKey = (int.parse(bean.data.page) + 1).toString();
        if (isNextPage) {
          if (dataList.isNotEmpty) {
            _videoList.addAll(dataList);
          }
          setState(() {});
        }
      } else {
        CosLogUtil.log("$pageLogPrefix: fail to request uid:${widget.uid}'s "
            "uploaded video list of page:$page, the error msg is ${bean.msg}, "
            "error code is ${bean.status}");
      }
    }).catchError((err) {
      CosLogUtil.log("$pageLogPrefix: fail to load uploaded video list of "
          "uid:${widget.uid}, the error is $err");
    }).whenComplete(() {});
    return list;
  }

  UploadedVideoItem _getUploadedVideoItem(int idx) {
    int listCnt = _videoList.length ?? 0;
    if (idx >= 0 && idx < listCnt) {
      return UploadedVideoItem(
        source: UploadedItemPageSource.myUploadedVideosPage,
        video: _videoList[idx],
        index: idx,
        exchangeRate: _rateInfo,
        dgpoBean: _chainDgpo,
        deleteCallBack: (String uid, String vid) {},
        visibilityChangedCallback: (int index, double visibleFraction) {
          if (_visibleFractionMap == null) {
            _visibleFractionMap = {};
          }
          _visibleFractionMap[index] = visibleFraction;
        },
        radius: 0,
        controller: _slidableController,
      );
    }
    return UploadedVideoItem();
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
  void _reportVideoExposure() {}
}
