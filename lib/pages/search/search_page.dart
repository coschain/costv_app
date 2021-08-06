import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/search_do_bean.dart';
import 'package:costv_android/bean/search_do_recommend_bean.dart';
import 'package:costv_android/bean/simple_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/search/debug_switch_page.dart';
import 'package:costv_android/pages/search/popupwindow/search_title_window.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/revenue_calculation_util.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:costv_android/utils/video_report_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/popupwindow/popup_window.dart';
import 'package:costv_android/widget/popupwindow/popup_window_route.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/video_time_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/pages/user/others_home_page.dart';

class SearchPage extends StatefulWidget {
  final String keyword;

  static const String DebugFlag = "debug";

  SearchPage(this.keyword, {Key key}) : super(key: key);

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  static const tag = 'SearchPageState';
  static const int selectTypeVideo = 1;
  static const int selectTypeCreator = 2;
  static const int pageSize = 10;
  static const int pageSizeRecommend = 5;
  static const int pageRecommend = 1;

  TextEditingController _textController = TextEditingController();
  int _selectType = selectTypeVideo;
  int _pageSearchVideo = 1;
  int _pageSearchUser = 1;
  List<SearchDoListItemBean> _listSearchVideo = [];
  List<SearchDoListItemBean> _listSearchUser = [];
  String _searchVideoTotal, _searchUserTotal;
  List<SearchDoRecommendListItemBean> _listRecommendVideo = [];
  List<SearchDoRecommendListItemBean> _listRecommendUser = [];
  bool _isNetIng = false;
  bool _isHaveMoreDataVideo = true;
  bool _isHaveMoreDataCreator = true;
  String _searchStr;
  bool _isInitFinish = false;
  ExchangeRateInfoData _exchangeRateInfoData;
  ChainState _chainStateBean;

  @override
  void initState() {
    super.initState();
    _searchStr = widget.keyword;
    _textController.text = widget.keyword;
    CosSdkUtil.instance.getChainState().then((bean) {
      _chainStateBean = bean.state;
      if (_isInitFinish) {
        _httpSearchDo(selectTypeVideo, false);
      }
    });
    _httpSearchInit();
  }

  @override
  void dispose() {
    RequestManager.instance.cancelAllNetworkRequest(tag);
    if (_textController != null) {
      _textController.dispose();
      _textController = null;
    }
    super.dispose();
  }

  void _httpSearchInit() {
    setState(() {
      _isNetIng = true;
    });
    Future.wait([
      RequestManager.instance.searchDo(
          tag, _searchStr, SearchRequest.searchTypeVideo,
          page: _pageSearchVideo,
          pageSize: pageSize,
          uid: Constant.uid ?? '',
          from: SearchRequest.fromSearch),
      RequestManager.instance.searchDo(
          tag, _searchStr, SearchRequest.searchTypeUser,
          page: _pageSearchUser,
          pageSize: pageSize,
          uid: Constant.uid ?? '',
          from: SearchRequest.fromSearch),
      RequestManager.instance.getExchangeRateInfo(tag),
    ]).then((listResponse) {
      if (listResponse == null || !mounted) {
        return;
      }
      bool isHaveBasicData = true;
      if (listResponse.length > 0 && listResponse[0] != null) {
        _searchVideoTotal = '0';
        isHaveBasicData =
            _processSearchDo(listResponse[0], false, selectTypeVideo);
      }
      if (listResponse.length > 1 && listResponse[1] != null) {
        _searchUserTotal = '0';
        isHaveBasicData =
            _processSearchDo(listResponse[1], false, selectTypeCreator);
      }
      if (listResponse.length > 2 && listResponse[2] != null) {
        isHaveBasicData = _processExchangeRateInfo(listResponse[2]);
      }
      if (isHaveBasicData) {
        _isInitFinish = true;
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNetIng = false;
      });
    });
  }

  /// 用户搜索
  void _httpSearchDo(int selectType, bool isLoadMore) {
    if (!_isNetIng && !isLoadMore) {
      setState(() {
        _isNetIng = true;
      });
    }
    if (!isLoadMore) {
      if (selectType == selectTypeVideo) {
        if (!isLoadMore&&!ObjectUtil.isEmptyList(_listSearchVideo)) {
          _listSearchVideo.clear();
        }
        _searchVideoTotal = '0';
        _searchUserTotal = '0';
        _isHaveMoreDataVideo = true;
        _pageSearchVideo = 1;
      } else {
        if (!isLoadMore&&!ObjectUtil.isEmptyList(_listSearchUser)) {
          _listSearchUser.clear();
        }
        _searchUserTotal = '0';
        _searchVideoTotal = '0';
        _isHaveMoreDataCreator = true;
        _pageSearchUser = 1;
      }
    }
    int page =
        selectType == selectTypeVideo ? _pageSearchVideo : _pageSearchUser;
    if (isLoadMore) {
      page += 1;
    }
    RequestManager.instance
        .searchDo(
            tag,
            _searchStr,
            selectType == selectTypeVideo
                ? SearchRequest.searchTypeVideo
                : SearchRequest.searchTypeUser,
            page: page,
            pageSize: pageSize,
            uid: Constant.uid ?? '',
            from: SearchRequest.fromSearch)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      _processSearchDo(response, isLoadMore, selectType);
    });
  }

  /// 处理用户搜索返回数据
  bool _processSearchDo(Response response, bool isLoadMore, int selectType) {
    SearchDoBean bean = SearchDoBean.fromJson(json.decode(response.data));
    if (bean != null &&
        bean.status == SimpleResponse.statusStrSuccess &&
        bean.data != null) {
      if (!ObjectUtil.isEmptyList(bean.data.list)) {
        setState(() {
          if (selectType == selectTypeVideo) {
            if (!isLoadMore) {
              _listSearchVideo.clear();
            } else {
              _pageSearchVideo++;
            }
            _listSearchVideo.addAll(bean.data.list);
//            if (bean.data.list.length < pageSize) {
//              _isHaveMoreDataVideo = false;
//            } else {
//              _isHaveMoreDataVideo = true;
//            }
            _isHaveMoreDataVideo = bean.data.hasNext == "1";
//            _searchVideoTotal = bean.data?.total ?? 0;
          } else {
            if (!isLoadMore) {
              _listSearchUser.clear();
            } else {
              _pageSearchUser++;
            }
            _listSearchUser.addAll(bean.data.list);
//            if (bean.data.list.length < pageSize) {
//              _isHaveMoreDataCreator = false;
//            } else {
//              _isHaveMoreDataCreator = true;
//            }
            _isHaveMoreDataCreator = bean.data.hasNext == "1";
//            _searchUserTotal = bean.data?.total ?? 0;
          }
          if (bean.data.showType != null && !isLoadMore) {
            //不是第一页的时候，服务端返回的总数是0，所以支取第一页的总数
            if (bean.data.showType == selectTypeVideo.toString()) {
              _searchVideoTotal =  bean.data?.total ?? "0";
              _searchUserTotal = bean.data?.totalOtherType ?? "0";
            } else if (bean.data.showType == selectTypeCreator.toString()) {
              _searchUserTotal =  bean.data?.total ?? "0";
              _searchVideoTotal = bean.data?.totalOtherType ?? "0";
            }
          }
          setState(() {
            _isNetIng = false;
          });
        });
      } else {
        if (selectType == selectTypeVideo) {
          _isHaveMoreDataVideo = false;
        } else {
          _isHaveMoreDataVideo = false;
        }
        _httpSearchDoRecommend(selectType);
      }
      return true;
    } else {
      setState(() {
        _isNetIng = false;
      });
      ToastUtil.showToast(bean?.msg ?? '');
      return false;
    }
  }

  /// 处理查询汇率返回数据
  bool _processExchangeRateInfo(Response response) {
    ExchangeRateInfoBean info =
        ExchangeRateInfoBean.fromJson(json.decode(response.data));
    if (info.status == SimpleResponse.statusStrSuccess) {
      _exchangeRateInfoData = info.data;
      return true;
    } else {
      return false;
    }
  }

  /// 用户搜索空结果推荐
  void _httpSearchDoRecommend(int selectType) {
    if (!_isNetIng) {
      setState(() {
        _isNetIng = true;
      });
    }
    RequestManager.instance
        .searchDoRecommend(
            tag,
            selectType == selectTypeVideo
                ? SearchRequest.searchTypeVideo
                : SearchRequest.searchTypeUser,
            page: pageRecommend,
            pageSize: pageSizeRecommend,
            uid: Constant.uid ?? '')
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SearchDoRecommendBean bean =
          SearchDoRecommendBean.fromJson(json.decode(response.data));
      if (bean != null &&
          bean.status == SimpleResponse.statusStrSuccess &&
          bean.data != null) {
        if (!ObjectUtil.isEmptyList(bean.data.list)) {
          setState(() {
            if (selectType == selectTypeVideo) {
              _listRecommendVideo.clear();
              _listRecommendVideo.addAll(bean.data.list);
            } else {
              _listRecommendUser.clear();
              _listRecommendUser.addAll(bean.data.list);
            }
          });
          setState(() {
            _isNetIng = false;
          });
        } else {
          setState(() {
            _isNetIng = false;
          });
        }
      } else {
        setState(() {
          _isNetIng = false;
        });
        ToastUtil.showToast(bean?.msg ?? '');
      }
    });
  }

  /// 添加关注
  void _httpAccountFollow(String uid, int index) {
    setState(() {
      _isNetIng = true;
    });
    RequestManager.instance
        .accountFollow(tag, Constant.uid, uid)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data == SimpleResponse.responseSuccess) {
          if (!ObjectUtil.isEmptyList(_listSearchUser)) {
            _listSearchUser[index].relation =
                SearchResponse.relationAttentionFinish;
          } else {
            _listRecommendUser[index].relation =
                SearchResponse.relationAttentionFinish;
          }
        }
      } else {
        ToastUtil.showToast(bean.msg);
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNetIng = false;
      });
    });
  }

  /// 取消关注
  void _httpAccountUnFollow(String uid, int index) {
    setState(() {
      _isNetIng = true;
    });
    RequestManager.instance
        .accountUnFollow(tag, Constant.uid, uid)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data == SimpleResponse.responseSuccess) {
          if (!ObjectUtil.isEmptyList(_listSearchUser)) {
            _listSearchUser[index].relation = SearchResponse.relationAttention;
          } else {
            _listRecommendUser[index].relation =
                SearchResponse.relationAttention;
          }
        }
      } else {
        ToastUtil.showToast(bean.msg);
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isNetIng = false;
      });
    });
  }

  Widget _buildSearchVideoItem(int index) {
    String imageUrl;
    String duration;
    String title;
    String anchorNickname;
    String watchNum;
    String showTime;
    String id;
    String totalRevenue;
    if (!ObjectUtil.isEmptyList(_listSearchVideo)) {
      SearchDoListItemBean searchDoListItemBean = _listSearchVideo[index];
      imageUrl = searchDoListItemBean?.videoCoverBig ?? '';
      duration = searchDoListItemBean?.duration;
      title = searchDoListItemBean?.title ?? '';
      anchorNickname = searchDoListItemBean?.anchorNickname ?? '';
      watchNum = searchDoListItemBean?.watchNum ?? '0';
      if (!ObjectUtil.isEmptyString(searchDoListItemBean?.createdAt)) {
        showTime =
            Common.calcDiffTimeByStartTime(searchDoListItemBean?.createdAt);
      } else {
        showTime = '';
      }
      id = searchDoListItemBean?.id ?? '';
      if (searchDoListItemBean != null && _exchangeRateInfoData != null) {
        if (searchDoListItemBean?.vestStatus ==
            VideoInfoResponse.vestStatusFinish) {
          /// 奖励完成
          double totalRevenueVest =
              RevenueCalculationUtil.getStatusFinishTotalRevenueVest(
                  searchDoListItemBean?.vest ?? '',
                  searchDoListItemBean?.vestGift ?? '');
          totalRevenue = RevenueCalculationUtil.vestToRevenue(
                  totalRevenueVest, _exchangeRateInfoData)
              .toStringAsFixed(2);
        } else {
          /// 奖励未完成
          double settlementBonusVest =
              RevenueCalculationUtil.getVideoRevenueVest(
                  searchDoListItemBean?.votepower, _chainStateBean?.dgpo);
          double giftRevenueVest = RevenueCalculationUtil.getGiftRevenueVest(
              searchDoListItemBean?.vestGift);
          totalRevenue = RevenueCalculationUtil.vestToRevenue(
                  NumUtil.add(settlementBonusVest, giftRevenueVest),
                  _exchangeRateInfoData)
              .toStringAsFixed(2);
        }
      }
    } else {
      SearchDoRecommendListItemBean searchDoRecommendListItemBean =
          _listRecommendVideo[index];
      imageUrl = searchDoRecommendListItemBean?.videoCoverBig ?? '';
      duration = searchDoRecommendListItemBean?.duration;
      title = searchDoRecommendListItemBean?.title ?? '';
      anchorNickname = searchDoRecommendListItemBean?.anchorNickname ?? '';
      watchNum = searchDoRecommendListItemBean?.watchNum ?? '0';
      if (!ObjectUtil.isEmptyString(searchDoRecommendListItemBean?.createdAt)) {
        showTime = Common.calcDiffTimeByStartTime(
            searchDoRecommendListItemBean?.createdAt ?? '');
      } else {
        showTime = '';
      }
      id = searchDoRecommendListItemBean?.id ?? '';
      if (searchDoRecommendListItemBean != null &&
          _exchangeRateInfoData != null) {
        if (searchDoRecommendListItemBean?.vestStatus ==
            VideoInfoResponse.vestStatusFinish) {
          /// 奖励完成
          double totalRevenueVest =
              RevenueCalculationUtil.getStatusFinishTotalRevenueVest(
                  searchDoRecommendListItemBean?.vest ?? '',
                  searchDoRecommendListItemBean?.vestGift ?? '');
          totalRevenue = RevenueCalculationUtil.vestToRevenue(
                  totalRevenueVest, _exchangeRateInfoData)
              .toStringAsFixed(2);
        } else {
          /// 奖励未完成
          double settlementBonusVest =
              RevenueCalculationUtil.getVideoRevenueVest(
                  searchDoRecommendListItemBean?.votepower,
                  _chainStateBean?.dgpo);
          double giftRevenueVest = RevenueCalculationUtil.getGiftRevenueVest(
              searchDoRecommendListItemBean?.vestGift);
          totalRevenue = RevenueCalculationUtil.vestToRevenue(
                  NumUtil.add(settlementBonusVest, giftRevenueVest),
                  _exchangeRateInfoData)
              .toStringAsFixed(2);
        }
      }
    }
    Widget _getVideoDurationWidget() {
      if (Common.checkVideoDurationValid(duration)) {
        return VideoTimeWidget(Common.formatVideoDuration(duration));
      }
      return Container();
    }

    return InkWell(
      child: Container(
        margin: EdgeInsets.only(
            left: AppDimens.margin_10,
            top: AppDimens.margin_5,
            right: AppDimens.margin_10,
            bottom: AppDimens.margin_5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radius_size_4),
                  child: Container(
                    width: AppDimens.item_size_145,
                    height: AppDimens.item_size_82,
//                    color: AppColors.color_d6d6d6,
                    decoration: BoxDecoration(
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
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: AppColors.color_d6d6d6,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.color_d6d6d6,
                      ),
                      imageUrl: imageUrl,
                    ),
                  ),
                ),
                _getVideoDurationWidget(),
              ],
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: AppDimens.margin_7_5),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppStyles.text_style_333333_14,
                      maxLines: 2,
                    ),
                    Container(
                      child: Text(
                        anchorNickname,
                        style: AppStyles.text_style_858585_11,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      '${Common.getCurrencySymbolByLanguage()} ${totalRevenue ?? ''}',
                      style: AppStyles.text_style_333333_bold_14,
                    ),
                    Text(
                      '$watchNum${InternationalLocalizations.searchPlayCount}·$showTime',
                      style: AppStyles.text_style_a0a0a0_12,
                      maxLines: 1,
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      onTap: () {
        if (Common.isAbleClick()) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) {
            return VideoDetailsPage(
                VideoDetailPageParamsBean.createInstance(vid: id));
          }));
//          DataReportUtil.instance.reportData(
//            eventName: "Click_video",
//            params: {"Click_video": id},
//          );
            VideoReportUtil.reportClickVideo(ClickVideoSource.Search, id);
        }
      },
    );
  }

  Widget _buildSearchUserItem(int index) {
    String attentionMsg;
    String imagePath;
    String anchorAvatar;
    String anchorNickname;
    String followerCount;
    String videoCount;
    bool isAttentionFinish;
    String uid;
    if (!ObjectUtil.isEmptyList(_listSearchUser)) {
      SearchDoListItemBean searchDoListItemBean = _listSearchUser[index];
      if (searchDoListItemBean?.relation ==
          SearchResponse.relationAttentionFinish) {
        attentionMsg = InternationalLocalizations.searchAttentionFinish;
        imagePath = 'assets/images/ic_attention_finish.png';
        isAttentionFinish = true;
      } else if (searchDoListItemBean?.relation ==
          SearchResponse.relationAttentionAllFinish) {
        attentionMsg = InternationalLocalizations.searchAttentionAllFinish;
        imagePath = 'assets/images/ic_attention_all_finish.png';
        isAttentionFinish = true;
      } else {
        attentionMsg = InternationalLocalizations.searchAttention;
        imagePath = 'assets/images/ic_attention.png';
        isAttentionFinish = false;
      }
      anchorAvatar = searchDoListItemBean?.avatar ?? '';
      anchorNickname = searchDoListItemBean?.nickName ?? '';
      followerCount = searchDoListItemBean?.followerCount ?? '';
      videoCount = searchDoListItemBean?.videoCount ?? '';
      uid = searchDoListItemBean?.uid ?? '';
    } else {
      SearchDoRecommendListItemBean searchDoRecommendListItemBean =
          _listRecommendUser[index];
      if (searchDoRecommendListItemBean?.relation ==
          SearchResponse.relationAttentionFinish) {
        attentionMsg = InternationalLocalizations.searchAttentionFinish;
        imagePath = 'assets/images/ic_attention_finish.png';
        isAttentionFinish = true;
      } else if (searchDoRecommendListItemBean?.relation ==
          SearchResponse.relationAttentionAllFinish) {
        attentionMsg = InternationalLocalizations.searchAttentionAllFinish;
        imagePath = 'assets/images/ic_attention_all_finish.png';
        isAttentionFinish = true;
      } else {
        attentionMsg = InternationalLocalizations.searchAttention;
        imagePath = 'assets/images/ic_attention.png';
        isAttentionFinish = false;
      }
      anchorAvatar = searchDoRecommendListItemBean?.avatar ?? '';
      anchorNickname = searchDoRecommendListItemBean?.nickName ?? '';
      followerCount = searchDoRecommendListItemBean?.followerCount ?? '';
      videoCount = searchDoRecommendListItemBean?.videoCount ?? '';
      uid = searchDoRecommendListItemBean?.uid ?? '';
    }
    return InkWell(
      child: Container(
        margin: EdgeInsets.only(
            left: AppDimens.margin_10,
            right: AppDimens.margin_10,
            bottom: AppDimens.margin_5),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Stack(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: AppColors.color_ffffff,
                  radius: AppDimens.item_size_27_5,
                  backgroundImage:
                      AssetImage('assets/images/ic_default_avatar.png'),
                ),
                CircleAvatar(
                  backgroundColor: AppColors.color_transparent,
                  radius: AppDimens.item_size_27_5,
                  backgroundImage: CachedNetworkImageProvider(
                    anchorAvatar,
                  ),
                )
              ],
            ),
            Container(
              margin: EdgeInsets.only(left: AppDimens.margin_10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: AppDimens.item_size_160,
                    child: Text(
                      anchorNickname,
                      style: AppStyles.text_style_333333_bold_15,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: AppDimens.margin_5),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width -
                          AppDimens.margin_10 - AppDimens.item_size_100 -
                          AppDimens.margin_5 - AppDimens.margin_10*2 -
                          AppDimens.item_size_27_5 * 2,
                  ),
                    child: Text(
                      '${InternationalLocalizations.searchFan} $followerCount  ${InternationalLocalizations.searchVideo} $videoCount',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: AppStyles.text_style_a0a0a0_12,
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: AppDimens.item_size_100,
                  height: AppDimens.item_size_30,
                  alignment: Alignment.center,
                  child: Material(
                    borderRadius:
                        BorderRadius.circular(AppDimens.radius_size_15),
                    color: isAttentionFinish
                        ? AppColors.color_d6d6d6
                        : AppColors.color_3674ff,
                    child: MaterialButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Image.asset(imagePath),
                          Text(
                            attentionMsg,
                            style: AppStyles.text_style_ffffff_13,
                          )
                        ],
                      ),
                      onPressed: () {
                        if(Common.isAbleClick()){
                          if (!Common.judgeHasLogIn()) {
                            //进入登录界面
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) {
                              return WebViewPage(Constant.logInWebViewUrl);
                            }));
                          } else {
                            if (!ObjectUtil.isEmptyString(uid)) {
                              if (isAttentionFinish) {
                                _httpAccountUnFollow(uid, index);
                              } else {
                                _httpAccountFollow(uid, index);
                              }
                            }
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      onTap: () {
        if (Common.isAbleClick()) {
//          Navigator.of(context).push(MaterialPageRoute(builder: (_) {
//            return WebViewPage(
//              '${Constant.otherUserCenterWebViewUrl}$uid',
//            );
//          }));
          Navigator.of(context).push(MaterialPageRoute(builder: (_) {
            return OthersHomePage(OtherHomeParamsBean(
              uid: uid ?? "",
              nickName: anchorNickname ?? '',
              avatar: anchorAvatar ?? '',
              rateInfoData: _exchangeRateInfoData,
              dgpoBean: _chainStateBean?.dgpo,
            ));
          }));
        }
      },
    );
  }

  Widget _buildListView(bool isShowNoData) {
    if (isShowNoData) {
      return Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(
                      top: AppDimens.margin_40, bottom: AppDimens.margin_12_5),
                  child: Image.asset('assets/images/ic_search_no_data.png'),
                ),
                Text(
                  InternationalLocalizations.searchNoData,
                  style: AppStyles.text_style_a0a0a0_14,
                )
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_10,
              top: AppDimens.margin_45,
              right: AppDimens.margin_10,
            ),
            child: Text(
              _selectType == selectTypeVideo
                  ? InternationalLocalizations.searchHotVideo
                  : InternationalLocalizations.searchRecommendUser,
              style: AppStyles.text_style_333333_bold_16,
            ),
          ),
          Expanded(
            child: ListView.builder(
                itemBuilder: (context, index) {
                  return _selectType == selectTypeVideo
                      ? _buildSearchVideoItem(index)
                      : _buildSearchUserItem(index);
                },
                itemCount: _selectType == selectTypeVideo
                    ? _listRecommendVideo.length
                    : _listRecommendUser.length),
          ),
        ],
      ));
    } else {
      return Expanded(
        child: RefreshAndLoadMoreListView(
          itemBuilder: (context, index) {
            return _selectType == selectTypeVideo
                ? _buildSearchVideoItem(index)
                : _buildSearchUserItem(index);
          },
          itemCount: _selectType == selectTypeVideo
              ? _listSearchVideo.length
              : _listSearchUser.length,
          onLoadMore: () {
            return _httpSearchDo(_selectType, true);
          },
          pageSize: pageSize,
          isHaveMoreData: _selectType == selectTypeVideo
              ? _isHaveMoreDataVideo
              : _isHaveMoreDataCreator,
          isRefreshEnable: false,
          isShowItemLine: false,
          bottomMessage: _selectType == selectTypeVideo
              ? InternationalLocalizations.searchNoMoreVideo
              : InternationalLocalizations.searchNoMoreUser,
          hasTopPadding: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isShowNoData = true;
    if (_selectType == selectTypeVideo) {
      isShowNoData = ObjectUtil.isEmptyList(_listSearchVideo);
    } else {
      isShowNoData = ObjectUtil.isEmptyList(_listSearchUser);
    }
    Widget body;
    if (_isInitFinish) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: AppDimens.item_size_55,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  child: Container(
                    padding: EdgeInsets.all(AppDimens.margin_10),
                    child: Image.asset('assets/images/ic_back.png'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        left: AppDimens.margin_5, right: AppDimens.margin_15),
                    height: AppDimens.item_size_32,
                    decoration: BoxDecoration(
                      color: AppColors.color_ebebeb,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppDimens.radius_size_21),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            child: Container(
                              margin:
                                  EdgeInsets.only(left: AppDimens.margin_10),
                              child: Text(
                                _searchStr ?? '',
                                style: AppStyles.text_style_333333_14,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            onTap: () {
                              if (Common.isAbleClick()) {
                                Navigator.push(
                                  context,
                                  PopupWindowRoute(
                                    child: PopupWindow(
                                      SearchTitleWindow(
                                        tag,
                                        SearchTitleWindow.fromSearch,
                                        selectType: _selectType,
                                        searchStr: _searchStr,
                                        onSearch: (searchStr) {
                                          _searchStr = searchStr;
                                          _textController.text = searchStr;
//                                          _httpSearchDo(_selectType, false);
                                          if (!ObjectUtil.isEmptyList(_listSearchVideo)) {
                                            _listSearchVideo.clear();
                                          }
                                          if (!ObjectUtil.isEmptyList(_listSearchUser)) {
                                            _listSearchUser.clear();
                                          }
                                          _searchVideoTotal = '0';
                                          _searchUserTotal = '0';
                                          _isHaveMoreDataVideo = true;
                                          _pageSearchVideo = 1;
                                          _isHaveMoreDataCreator = true;
                                          _pageSearchUser = 1;
                                          _httpSearchInit();
                                        },
                                      ),
                                      left: 0,
                                      top: 0,
                                      backgroundColor: AppColors.color_66000000,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        Offstage(
                          offstage: ObjectUtil.isEmptyString(_searchStr),
                          child: InkWell(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin:
                                    EdgeInsets.only(right: AppDimens.margin_5),
                                padding: EdgeInsets.all(AppDimens.margin_5),
                                child: Image.asset(
                                    'assets/images/ic_input_close.png'),
                              ),
                            ),
                            onTap: () {
                              if (Common.isAbleClick()) {
                                setState(() {
                                  _searchStr = '';
                                  _textController.clear();
                                });
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: AppColors.color_e4e4e4,
            height: AppDimens.item_line_height_0_5,
          ),
          Row(
            children: <Widget>[
              InkWell(
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.margin_15),
                  child: Text(
                    '${InternationalLocalizations.searchVideo}(${_searchVideoTotal ?? 0})',
                    style: _selectType == selectTypeVideo
                        ? AppStyles.text_style_3674ff_16
                        : AppStyles.text_style_333333_14,
                  ),
                ),
                onTap: () {
                  if (Common.isAbleClick()) {
                    if (_selectType != selectTypeVideo) {
                      setState(() {
                        _selectType = selectTypeVideo;
                      });
                    }
                  }
                },
              ),
              InkWell(
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.margin_15),
                  child: Text(
                    '${InternationalLocalizations.searchCreator}(${_searchUserTotal ?? 0})',
                    style: _selectType == selectTypeCreator
                        ? AppStyles.text_style_3674ff_bold_16
                        : AppStyles.text_style_333333_14,
                  ),
                ),
                onTap: () {
                  if (Common.isAbleClick()) {
                    if (_selectType != selectTypeCreator) {
                      setState(() {
                        _selectType = selectTypeCreator;
                      });
                    }
                  }
                },
              ),
            ],
          ),
          _buildListView(isShowNoData),
        ],
      );
    } else {
      if (_isNetIng) {
        body = Container();
      } else {
        body = PageRemindWidget(
          clickCallBack: () {
            _httpSearchInit();
          },
          remindType: RemindType.NetRequestFail,
        );
      }
    }
    return LoadingView(
      child: Scaffold(
        body: Container(
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: AppColors.color_ffffff,
            child: _buildWithDebugSwitch(body)),
      ),
      isShow: _isNetIng,
    );
  }

  Widget _buildWithDebugSwitch(Widget body) {
    if (widget.keyword != SearchPage.DebugFlag) {
      return Stack(children: <Widget>[body]);
    } else {
      return Stack(children: <Widget>[
        body,
        Positioned(
            right: 1,
            bottom: 1,
            child: GestureDetector(
              onDoubleTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                  return DebugSwitchPage();
                }));
              },
              child: Container(
                color: Colors.transparent,
                width: AppDimens.item_size_50,
                height: AppDimens.item_size_50,
                //child: Text('TURN LIGHTS ON'),
              ),
            ))
      ]);
    }
  }
}
