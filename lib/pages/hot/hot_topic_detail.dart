import 'dart:convert';

import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/widget/custom_app_bar.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/single_video_item.dart';
import 'package:flutter/material.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/utils/video_report_util.dart';

class HotTopicDetailPage extends StatefulWidget {
  final HotTopicModel topicModel;
  final ExchangeRateInfoData rateInfo;
  HotTopicDetailPage({@required this.topicModel, this.rateInfo});
  @override
  State<StatefulWidget> createState() => _HotTopicDetailPageState(rateInfo: this.rateInfo);
}

class _HotTopicDetailPageState extends State<HotTopicDetailPage> with RouteAware {

  static const String tag = '_HotTopicDetailPageState';
  final logPrefix = "HotTopicDetailPage";
  int _pageSize = 10 , _curPage = 1;
  bool _isFetching = false, _hasNextPage = false, _isShowLoading = true, _isScrolling = false;
  List<GetVideoListNewDataListBean> _videoList = [];
  String _operateVid = '';
  List<String> tmpOpVid = [];
  Map<String,String> _historyVideoMap = new Map();
  ExchangeRateInfoData rateInfo;
  dynamic_properties chainDgpo;
  _HotTopicDetailPageState({this.rateInfo});
  Map<int,double> _visibleFractionMap = {};


  @override
  void didUpdateWidget(HotTopicDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void didPush() {
    super.didPush();
  }

  @override
  void didPop() {
    super.didPop();
  }

  @override
  void didPushNext() {
    super.didPushNext();
  }

  @override
  void didPopNext() {
    super.didPopNext();
  }
  
  @override
  void initState() {
    _reloadData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return LoadingView(
      isShow: _isShowLoading,
      child:  Scaffold(
        appBar: CustomAppBar(title: widget.topicModel?.desc ?? ""),
        body: Container(
          color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("3F3F3F3F", 0.05),
            darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
          ),
//          padding: EdgeInsets.only(top: 10),
          child: RefreshAndLoadMoreListView(
            contentTopPadding: 10,
            itemCount: _videoList?.length ?? 0,
            itemBuilder: (BuildContext context, int position) {
              if (!_isScrolling) {
                _visibleFractionMap[position] = 1;
              }
              return _getSingleVideoItem(position);
            },
            bottomMessage: InternationalLocalizations.moMoreHotData,
            isHaveMoreData:  _hasNextPage,
            isLoadMoreEnable: true,
            isRefreshEnable: true,
            onRefresh: _reloadData,
            pageSize: _pageSize,
            onLoadMore: () {
              _loadNextPageData();
            },
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

  ///获取单个item
  SingleVideoItem _getSingleVideoItem(int idx) {
    int vCnt = _videoList?.length ?? 0;
    if (vCnt >= 0 && idx < vCnt) {
      return SingleVideoItem(
        videoData: _videoList[idx],
        exchangeRate: rateInfo,
        dgpoBean: chainDgpo,
        source: _getEnterSource(),
        index: idx,
        visibilityChangedCallback: (int index, double visibleFraction) {
          if (_visibleFractionMap == null) {
            _visibleFractionMap  = {};
          }
          _visibleFractionMap[index] = visibleFraction;
        },
      );
    }
    return SingleVideoItem();
  }

  /// 获取下一页数据
  Future<void> _loadNextPageData() async {
    if (_isFetching) {
      CosLogUtil.log("$logPrefix: is fething  when fetch next page data");
      return;
    }
    _isFetching = true;
    await _loadTagVideoList(true);
    _isFetching = false;
  }

  ///重新获取第一页数据
  Future<void> _reloadData() async {
    if (_isFetching) {
      CosLogUtil.log("$logPrefix: is fething data when reload");
      return;
    }
    _isFetching = true;

    bool isNeedLoadRate = (rateInfo == null) ? true : false;
    if (isNeedLoadRate) {
      Iterable<Future> reqList = [_loadTagVideoList(false),
        VideoUtil.requestExchangeRate(tag), CosSdkUtil.instance.getChainState()];
      Future.wait(reqList)
          .then((resList) {
        if (resList != null && mounted) {
          int resLen = resList.length;
          List<GetVideoListNewDataListBean> videoList;
          ExchangeRateInfoData rateData = rateInfo;
          dynamic_properties dgpo = chainDgpo;
          if (resLen >= 1) {
            videoList = resList[0];
            _videoList = videoList;
          }
          if (isNeedLoadRate && resLen >= 2) {
            rateData = resList[1];
            if (rateData != null) {
               rateInfo = rateData;
            }
          }

          if (resLen >= 3) {
            GetChainStateResponse bean = resList[2];
            if (bean != null && bean.state != null && bean.state.dgpo != null) {
              dgpo= bean.state.dgpo;
              chainDgpo = dgpo;
            }
          }

          if (videoList != null) {
            _curPage = 1;
            VideoUtil.clearHistoryVidMap(_historyVideoMap);
            VideoUtil.addNewVidToHistoryVidMapFromList(videoList, _historyVideoMap);
            _operateVid = VideoUtil.parseOperationVid(tmpOpVid);
            setState(() {
              _isShowLoading = false;
              _isFetching = false;
              Future.delayed(Duration(seconds: 1), () {
                if (!_isScrolling) {
                  _reportVideoExposure();
                }
              });
            });
          }
        }
      }).catchError((err) {
        CosLogUtil.log("$logPrefix: fail to reload data, the error is $err");
      }).whenComplete(() {
        _isFetching = false;
        if (mounted && _isShowLoading) {
          _isShowLoading = false;
          _isFetching = false;
          setState(() {

          });
        }
      });

    } else {
      List<GetVideoListNewDataListBean> vList = await _loadTagVideoList(false);
      if (vList != null) {
        _videoList = vList;
        _curPage = 1;
        VideoUtil.clearHistoryVidMap(_historyVideoMap);
        VideoUtil.addNewVidToHistoryVidMapFromList(vList, _historyVideoMap);
        _operateVid = VideoUtil.parseOperationVid(tmpOpVid);
      }
      setState(() {
        _isShowLoading = false;
        _isFetching = false;
      });
    }
  }

  ///获取tag视频列表
  Future<List<GetVideoListNewDataListBean>> _loadTagVideoList(bool isNextPage) async {
    List<GetVideoListNewDataListBean> list;
    if (isNextPage && !_hasNextPage) {
      return list;
    }
    int page = isNextPage ? _curPage + 1 : 1;
    String topicType = widget.topicModel?.topicType?.index.toString() ?? "";
    String lan = Common.getRequestLanCodeByLanguage(false);
    await RequestManager.instance.getTagVideoList(tag, lan, topicType,page.toString()
        , _pageSize.toString(), _operateVid)
    .then((response) {
      if (response == null || !mounted) {
        CosLogUtil.log("$logPrefix: fail to request hot topic:$topicType's video list");
        return;
      }
      GetVideoListNewBean bean = GetVideoListNewBean.fromJson(json.decode(response.data));
      bool isSuccess = (bean.status == SimpleResponse.statusStrSuccess);
      List<GetVideoListNewDataListBean> dataList = isSuccess ? (bean.data?.list ?? []) : [];
      list = dataList;
      if (isSuccess) {
        _hasNextPage = bean.data.hasNext == "1";
        if (isNextPage) {
          list = VideoUtil.filterRepeatVideo(dataList, _historyVideoMap);
          if (list.isNotEmpty) {
            _videoList.addAll(list);
            VideoUtil.addNewVidToHistoryVidMapFromList(list, _historyVideoMap);
          }
          _curPage = page;
          setState(() {

          });
        } else {
          tmpOpVid = bean.data?.operateVids ?? [];
        }

      } else {
        CosLogUtil.log("$logPrefix: fail to request hot topic $topicType's "
            "video list of page:$page, the error msg is ${bean.message}, "
            "error code is ${bean.status}");
      }

    }).catchError((err) {

    }).whenComplete(() {
    });
    return list;
  }

  List<int> _getVisibleItemIndex() {
    List<int> idxList = [];
    _visibleFractionMap.forEach((int key,double val) {
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
              VideoExposureType.HotTopicType,bean.id ?? '', bean.uid ?? ''
          );
        }
      }

    }
  }

  EnterSource _getEnterSource() {
    EnterSource source = EnterSource.HotTopicGame;
    if (widget.topicModel.topicType == HotTopicType.TopicFun) {
      source = EnterSource.HotTopicFun;
    } else if (widget.topicModel.topicType == HotTopicType.TopicCutePets) {
      source = EnterSource.HotTopicCutePet;
    } else if (widget.topicModel.topicType == HotTopicType.TopicMusic) {
      source = EnterSource.HotTopicMusic;
    }
    return source;
  }

}