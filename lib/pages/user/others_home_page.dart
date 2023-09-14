import 'package:common_utils/common_utils.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/bean/anchor_image_compress_bean.dart';
import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/user_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/utils/web_view_util.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/others_info_bean.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/bean/simple_bean.dart';
import 'dart:convert';
import 'package:costv_android/utils/toast_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import 'package:costv_android/widget/custom_app_bar.dart';
import 'package:costv_android/widget/history_video_item.dart';
import 'package:costv_android/widget/single_video_item.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/video_report_util.dart';

enum otherHomeRequestType {
  Default, //默认类型
  HotListType, //热门视频列表
}

enum otherHomeVideoType {
  Hottest, //最热
  HotList, //热门
  NewList, //最新视频列表
}

const othersHomeTag = "OthersHomePage";
double descBgWidth = 0;

class OtherHomeParamsBean {
  String uid;
  String? avatar;
  String? nickName;
  String? isCertification;
  ExchangeRateInfoData? rateInfoData;
  dynamic_properties? dgpoBean;

  OtherHomeParamsBean({required this.uid, this.nickName, this.avatar, this.isCertification, this.rateInfoData, this.dgpoBean})
      : assert(Common.checkIsNotEmptyStr(uid));
}

class OthersHomePage extends StatefulWidget {
  final OtherHomeParamsBean paramsBean;

  OthersHomePage(this.paramsBean) : assert(Common.checkIsNotEmptyStr(paramsBean.uid));

  @override
  State<StatefulWidget> createState() {
    return OthersHomePageState();
  }
}

class OthersHomePageState extends State<OthersHomePage> {
  List<GetVideoListNewDataListBean> _hotVideoList = []; //用户热门视频列表,第一个为最热视频
  List<GetVideoListNewDataListBean> _newVideoList = []; //用户最新视频列表
  OthersDetailInfo? _userInfo;
  OthersInfoData? _tmpInfo;
  ExchangeRateInfoData? _rateInfoData;
  dynamic_properties? _dgpoBean;
  GlobalObjectKey<FollowButtonState> _followBtnKey = GlobalObjectKey<FollowButtonState>("followBtn" + DateTime.now().toString());
  GlobalObjectKey<FansNumWidgetState> _fansNumTextKey = GlobalObjectKey<FansNumWidgetState>("fansBtn" + DateTime.now().toString());
  GlobalObjectKey<NickNameAndFansNumBgWidgetState> _nickNameBgKey =
      GlobalObjectKey<NickNameAndFansNumBgWidgetState>("nickNameBg" + DateTime.now().toString());
  bool _isFollowed = false,
      _isShowLoading = true,
      _isVideoLoad = false,
      _isSuccessLoad = true,
      _hasNextPage = false,
      _isFetching = false,
      _isScrolling = false;
  int _curNewListPage = 1, _pageSize = 10, _maxHotVideoCnt = 10, _minHotVideoCnt = 5;
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey = new GlobalKey<NetRequestFailTipsViewState>();
  Map<int, double> _hottestVisibleMap = {};
  Map<int, double> _hotVisibleMap = {};
  Map<int, double> _newVisibleMap = {};

  @override
  void initState() {
    _userInfo = OthersDetailInfo("", widget.paramsBean.nickName ?? '', widget.paramsBean.uid, widget.paramsBean.avatar ?? '', '',
        new AnchorImageCompressBean(widget.paramsBean.avatar ?? ''), '0', '0', '0', widget.paramsBean.isCertification ?? '0');
    if (widget.paramsBean.rateInfoData != null) {
      _rateInfoData = widget.paramsBean.rateInfoData;
    }
    if (widget.paramsBean.dgpoBean != null) {
      _dgpoBean = widget.paramsBean.dgpoBean;
    }
    _isFollowed = UserUtil.checkIsFollowByStateCode(_userInfo?.isFollow ?? "");
    _reportData();
    super.initState();
    _reloadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeUtil.setDifferentModeColor(
          lightColor: Common.getColorFromHexString("F6F6F6", 1.0), darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
      appBar: CustomAppBar(
        title: _userInfo?.nickname ?? '',
      ),
      body: _buildPageWidget(),
    );
  }

  Widget _buildPageWidget() {
    if (_isSuccessLoad) {
      return LoadingView(
          isShow: _isShowLoading,
          child: NetRequestFailTipsView(
            key: _failTipsKey,
            baseWidget: RefreshAndLoadMoreListView(
              itemCount: _getTotalItemCount(),
              itemBuilder: (context, index) {
                return _buildListItem(index);
              },
              onRefresh: _reloadData,
              onLoadMore: _loadNewVideoNextPageData,
              isRefreshEnable: true,
              isHaveMoreData: _hasNextPage,
              isLoadMoreEnable: true,
              bottomMessage: _checkHasVideoData() ? InternationalLocalizations.searchNoMoreVideo : '',
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
          ));
    }
    return PageRemindWidget(
      clickCallBack: () {
        _isShowLoading = true;
        _reloadData();
        setState(() {});
      },
      remindType: RemindType.NetRequestFail,
    );
  }

  Widget _buildListItem(int index) {
    if (index == 0) {
      return _buildTopUserInfoCard();
    } else {
      if (index == 1) {
        if (_checkHasVideoData()) {
          //最热
          if (!_isScrolling) {
            _hottestVisibleMap[0] = 1;
          }
          return _buildHottestItem(0);
        } else {
          return _buildEmptyStatusWidget();
        }
      } else if (index < _getHotVideoLength() + 1 && _checkHasHotVideoData()) {
        int idx = index - 1;
        if (idx < _getHotVideoLength()) {
          if (!_isScrolling) {
            _hotVisibleMap[idx] = 1;
          }
          return _buildHotVideoItem(idx);
        }
      } else if (index < _getHotVideoLength() + 1 + _getNewVideoLength() && _checkHasNewVideoData()) {
        int idx = index - 1 - _getHotVideoLength();
        if (idx < _getNewVideoLength()) {
          if (!_isScrolling) {
            _newVisibleMap[idx] = 1;
          }
          return _buildNewVideoList(idx);
        }
      }
    }
    return Container();
  }

  /// 顶部用户信息
  Widget _buildTopUserInfoCard() {
    double screenWidth = MediaQuery.of(context).size.width;
    double bgPadding = 10, avatarWidth = 70;
    double descWidth = screenWidth - bgPadding * 2 - avatarWidth;
    descBgWidth = descWidth;
    double followWidth = FollowButtonState.calcWidth(_isFollowed, context);
    if (followWidth > descWidth * 0.5) {
      followWidth = descWidth * 0.5;
    }
    double namePartWidth = descWidth - followWidth;
    String avatar = _userInfo?.imageCompress?.avatarCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(avatar)) {
      avatar = _userInfo?.avatar ?? '';
    }
    List<Color> gradientColors = [
      Common.getColorFromHexString("D4E3FF", 1),
      Common.getColorFromHexString("FFF2E2", 1),
    ];
    if (AppThemeUtil.checkIsDarkMode()) {
      gradientColors = [
        Common.getColorFromHexString("8F9CB4", 1),
        Common.getColorFromHexString("AB9375", 1),
      ];
    }
    return Container(
      padding: EdgeInsets.fromLTRB(bgPadding, 15, bgPadding, 15),
      width: screenWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.color_ebebeb, width: AppDimens.item_line_height_0_5),
              borderRadius: BorderRadius.circular(avatarWidth / 2),
            ),
            child: Stack(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: AppColors.color_ffffff,
                  radius: avatarWidth / 2,
                  backgroundImage: AssetImage('assets/images/ic_default_avatar.png'),
                ),
                CircleAvatar(
                  backgroundColor: AppColors.color_transparent,
                  radius: avatarWidth / 2,
                  backgroundImage: CachedNetworkImageProvider(
                    avatar,
                  ),
                ),
              ],
            ),
          ),
          //昵称、粉丝
          _buildNameAndFansPartWidget(namePartWidth),
          //订阅按钮
          _buildFollowBtnWidget(),
        ],
      ),
    );
  }

  Widget _buildNameAndFansPartWidget(double bgWidth) {
    if (_nickNameBgKey.currentState != null) {
      _nickNameBgKey.currentState?.updateBgWidth(bgWidth);
    }
    return NickNameAndFansNumBgWidget(
      key: _nickNameBgKey,
      bgWidth: bgWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //昵称
          _buildNickNameWidget(),
          _buildFansNumWidget(),
        ],
      ),
    );
  }

  ///昵称
  Widget _buildNickNameWidget() {
    if (Common.checkIsNotEmptyStr(_userInfo?.nickname ?? "")) {
      bool isCertification;
      if (_userInfo != null) {
        isCertification = _userInfo?.isCertification == CommentListItemBean.isCertificationYes;
      } else {
        isCertification = widget.paramsBean.isCertification == CommentListItemBean.isCertificationYes;
      }
      return Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Flexible(
              child: Text(
            _userInfo?.nickname ?? "'",
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppThemeUtil.setDifferentModeColor(
                lightColor: Common.getColorFromHexString("333333", 1.0),
                darkColorStr: "EBEBEB",
              ),
              fontSize: 15,
            ),
          )),
          //认证标识
          Offstage(
            offstage: !isCertification,
            child: Container(
              margin: EdgeInsets.only(left: AppDimens.margin_7),
              child: Image.asset(
                "assets/images/ic_comment_certification.png",
              ),
            ),
          ),
        ],
      );
    }
    return Container();
  }

  ///粉丝数
  Widget _buildFansNumWidget() {
    if (_fansNumTextKey.currentState != null) {
      _fansNumTextKey.currentState?.updateFanNum(_userInfo?.followerCount ?? "");
    }
    return FansNumWidget(
      key: _fansNumTextKey,
      fansNum: _userInfo?.followerCount,
    );
//    return Container(
//      margin: EdgeInsets.only(top: 5),
//      child: Text(
//        '${InternationalLocalizations.getUserFansNum(_userInfo.followerCount ?? "0")}',
//        maxLines: 1,
//        overflow: TextOverflow.ellipsis,
//        textAlign: TextAlign.left,
//        style: TextStyle(
//          color: Common.getColorFromHexString("858585", 1.0),
//          fontSize: 12
//        ),
//      ),
//    );
  }

  ///关注按钮
  Widget _buildFollowBtnWidget() {
    return Container(
      child: FollowButton(
        key: _followBtnKey,
        uid: _userInfo?.uid ?? "",
        isFollow: _isFollowed,
        handleResultCallBack: (isFollow, isSuccess) {
          int originNum = NumUtil.getIntByValueStr(_userInfo?.followerCount ?? "", defValue: 0) ?? 0;
          bool needHandle = false;
          if (isFollow && isSuccess) {
            //粉丝数增加
            originNum += 1;
            needHandle = true;
            _isFollowed = true;
          } else if (!isFollow && isSuccess) {
            //取消关注，粉丝数减少
            needHandle = true;
            if (originNum > 0) {
              originNum -= 1;
            }
            _isFollowed = false;
          }
          if (needHandle) {
            _userInfo?.followerCount = originNum.toString();
            if (_fansNumTextKey.currentState != null) {
              _fansNumTextKey.currentState?.updateFanNum(_userInfo?.followerCount ?? "");
            }
            if (_nickNameBgKey.currentState != null) {
              double followWidth = FollowButtonState.calcWidth(_isFollowed, context);
              if (followWidth > descBgWidth * 0.5) {
                followWidth = descBgWidth * 0.5;
              }
              double namePartWidth = descBgWidth - followWidth;
              _nickNameBgKey.currentState?.updateBgWidth(namePartWidth);
            }
          }
        },
      ),
    );
  }

  ///最热视频item
  Widget _buildHottestItem(int idx) {
    if (_checkHasHotVideoData()) {
      return Container(
        padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("F6F6F6", 1.0), darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            //标题
            Container(
              margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                InternationalLocalizations.userHottestVideo,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppThemeUtil.setDifferentModeColor(
                        lightColor: Common.getColorFromHexString("333333", 1.0), darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr),
                    fontSize: 15),
              ),
            ),
            //Single video item
            SingleVideoItem(
              videoData: _hotVideoList[0],
              exchangeRate: _rateInfoData,
              dgpoBean: _dgpoBean,
              source: EnterSource.OtherCenter,
              index: idx,
              visibilityChangedCallback: (int index, double visibleFraction) {
                if (_hottestVisibleMap == null) {
                  _hottestVisibleMap = {};
                }
                _hottestVisibleMap[index] = visibleFraction;
              },
            ),
            //separate line
            Container(
              margin: EdgeInsets.only(top: 20),
              height: 0.5,
              color: AppThemeUtil.setDifferentModeColor(lightColor: Common.getColorFromHexString("EBEBEB", 1), darkColorStr: "3E3E3E"),
            )
          ],
        ),
      );
    }
    return Container();
  }

  Widget _buildEmptyStatusWidget() {
    if (!_isVideoLoad && !_checkHasVideoData()) {
      return Container();
    }
    return Container(
      margin: EdgeInsets.only(top: 50),
      child: Align(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: AppDimens.margin_40, bottom: AppDimens.margin_12_5),
              child: Image.asset('assets/images/ic_search_no_data.png'),
            ),
            Text(
              InternationalLocalizations.hasNotUploadVideos,
              style: AppStyles.text_style_a0a0a0_14,
            )
          ],
        ),
      ),
    );
  }

  ///热门视频列表
  Widget _buildHotVideoItem(int idx) {
    return Container(
      color: AppThemeUtil.setDifferentModeColor(
          lightColor: Common.getColorFromHexString("F6F6F6", 1.0), darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //标题
          Offstage(
            offstage: idx != 1,
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Text(
                InternationalLocalizations.userHotVideo,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppThemeUtil.setDifferentModeColor(
                        lightColor: Common.getColorFromHexString("333333", 1.0), darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr),
                    fontSize: 15),
              ),
            ),
          ),
          //video item
          HistoryVideoItem(
            video: _hotVideoList[idx],
            exchangeRate: _rateInfoData,
            dgpoBean: _dgpoBean,
            index: idx,
            source: HistoryItemPageSource.OtherHome,
            logPrefix: othersHomeTag,
            isEnableDelete: false,
            visibilityChangedCallback: (int index, double visibleFraction) {
              if (_hotVisibleMap == null) {
                _hotVisibleMap = {};
              }
              _hotVisibleMap[index] = visibleFraction;
            },
            radius: 0,
          ),
        ],
      ),
    );
  }

  ///最新视频列表
  Widget _buildNewVideoList(int idx) {
    return Container(
      color: AppThemeUtil.setDifferentModeColor(
          lightColor: Common.getColorFromHexString("F6F6F6", 1.0), darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //标题
          Offstage(
            offstage: idx != 0,
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 25, 0, 0),
              child: Text(
                InternationalLocalizations.userNewVideos,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppThemeUtil.setDifferentModeColor(
                      darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                      lightColor: Common.getColorFromHexString("333333", 1.0),
                    ),
                    fontSize: 15),
              ),
            ),
          ),
          //video item
          HistoryVideoItem(
            video: _newVideoList[idx],
            exchangeRate: _rateInfoData,
            dgpoBean: _dgpoBean,
            index: idx,
            source: HistoryItemPageSource.OtherHome,
            logPrefix: othersHomeTag,
            isEnableDelete: false,
            visibilityChangedCallback: (int index, double visibleFraction) {
              if (_newVisibleMap == null) {
                _newVisibleMap = {};
              }
              _newVisibleMap[index] = visibleFraction;
            },
            radius: 0,
          ),
        ],
      ),
    );
  }

  ///重新拉取第一页数据
  Future<void> _reloadData() async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    Future.wait([
      _fetchUserInfoAndVideoList(false, otherHomeRequestType.Default),
      VideoUtil.requestExchangeRate(othersHomeTag),
      CosSdkUtil.instance.getChainState(),
    ], cleanUp: (val) {
      if (val is OthersInfoData) {
        _tmpInfo = val;
      } else if (val is ExchangeRateInfoData) {
        _rateInfoData = val;
      } else if (val is GetChainStateResponse) {
        _dgpoBean = val.state.dgpo;
      }
    }).then((resList) {
      if (mounted) {
        if (resList.length >= 3) {
          GetChainStateResponse? bean = resList[2] as GetChainStateResponse?;
          if (bean != null) {
            _dgpoBean = bean.state.dgpo;
          }
        }
        if (resList.length >= 2) {
          ExchangeRateInfoData? rateData = resList[1] as ExchangeRateInfoData?;
          if (rateData != null) {
            _rateInfoData = rateData;
          }
        }
        if (resList.length >= 1) {
          OthersInfoData? info = resList[0] as OthersInfoData?;
          if (info == null) {
            if (!_checkHasData()) {
              _isSuccessLoad = false;
            } else {
              _showNetRequestFailTips();
            }
          } else {
            _processUserInfo(info);
            setState(() {
              Future.delayed(Duration(seconds: 1), () {
                if (!_isScrolling) {
                  _reportVideoExposure();
                }
              });
            });
          }
        }
      } else if (mounted) {
        if (_checkHasData()) {
          _showNetRequestFailTips();
        } else {
          _isSuccessLoad = false;
        }
      }
    }).catchError((err) {
      CosLogUtil.log("$othersHomeTag: fail to reload data, the error is $err");
      if (mounted) {
        if (_tmpInfo != null) {
          _processUserInfo(_tmpInfo!);
          Future.delayed(Duration(seconds: 2), () {
            if (!_isScrolling) {
              _reportVideoExposure();
            }
          });
        } else {
          if (_checkHasData()) {
            _showNetRequestFailTips();
          } else {
            _isSuccessLoad = false;
          }
        }
      }
    }).whenComplete(() {
      if (mounted) {
        _isFetching = false;
        _tmpInfo = null;
        if (_isShowLoading) {
          setState(() {
            _isShowLoading = false;
          });
        }
      }
    });
  }

  Future<void> _loadNewVideoNextPageData() async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    await _fetchUserInfoAndVideoList(true, otherHomeRequestType.HotListType);
    _isFetching = false;
  }

  ///拉取用户相关信息(包括热门视频列表)
  Future<OthersInfoData?> _fetchUserInfoAndVideoList(bool isNextPage, otherHomeRequestType rType) async {
    OthersInfoData? info;
    if (isNextPage && !_hasNextPage) {
      return null;
    }
    int page = isNextPage ? _curNewListPage + 1 : 1;
    await RequestManager.instance
        .getUserInfoAndVideoList(widget.paramsBean.uid, uid: Constant.uid, page: page, tag: othersHomeTag, pageSize: _pageSize, type: rType.index)
        .then((response) {
      if (response == null || !mounted) {
        if (mounted) {
          CosLogUtil.log("$othersHomeTag: fail to fetch user:${_userInfo?.uid ?? ''} info and video list, response is null");
        }
        info = null;
      } else {
        OthersInfoBean bean = OthersInfoBean.fromJson(json.decode(response.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          info = bean.data;
          if (bean.data.newList != null && bean.data.newList?.hasNext != null) {
            _hasNextPage = bean.data.newList!.hasNext == "1";
          } else {
            _hasNextPage = false;
          }
          if (rType == otherHomeRequestType.HotListType) {
            GetVideoListNewDataBean? dataBean = bean.data.newList;
            if (isNextPage) {
              if (dataBean != null && dataBean.list.isNotEmpty) {
                if (_newVideoList == null) {
                  _newVideoList = [];
                }
                _newVideoList.addAll(dataBean.list);
                setState(() {});
              }
            }
            _curNewListPage = page;
          }
        } else {
          CosLogUtil.log("$othersHomeTag: fail to fetch user:${_userInfo?.uid ?? ''} "
              "info and video list, the error is ${bean.msg}");
        }
      }
    }).catchError((err) {
      CosLogUtil.log("$othersHomeTag: load user:${_userInfo?.uid ?? ''}"
          " info and video list exception, the error is $err");
      info = null;
    }).whenComplete(() {});
    return info;
  }

  void _processUserInfo(OthersInfoData data) {
    _isVideoLoad = true;
    if (data.hotList != null) {
      int hotVideoCnt = data.hotList?.list.length ?? 0;
      if (hotVideoCnt > 0) {
        if (hotVideoCnt >= _maxHotVideoCnt) {
          //最多显示_maxHotVideoCnt个热门视频(最热+热门列表)
          _hotVideoList = data.hotList!.list.sublist(0, _minHotVideoCnt + 1);
        } else {
          _hotVideoList = data.hotList!.list;
        }
      } else {
        _hotVideoList = [];
      }
    }
    if (data.newList != null) {
      _newVideoList = data.newList?.list ?? [];
    }
    if (data.userInfo != null) {
      _userInfo = data.userInfo;
      _isFollowed = UserUtil.checkIsFollowByStateCode(_userInfo?.isFollow ?? "");
      if (_followBtnKey.currentState != null) {
        _followBtnKey.currentState?.updateFollowStatus(_isFollowed);
      }
    }
    _curNewListPage = 1;
  }

  int _getTotalItemCount() {
    int cnt = 2; //用户信息 (最热或是空数据提示状态)
    if (_checkHasHotVideoData()) {
      cnt += _getHotVideoLength();
    }
    if (_checkHasNewVideoData()) {
      cnt += _getNewVideoLength();
    }
    return cnt;
  }

  bool _checkHasVideoData() {
    if (_checkHasHotVideoData()) {
      return true;
    }
    if (_checkHasNewVideoData()) {
      return true;
    }
    return false;
  }

  bool _checkHasHotVideoData() {
    if (_hotVideoList.isNotEmpty) {
      return true;
    }
    return false;
  }

  int _getHotVideoLength() {
    if (_checkHasHotVideoData()) {
      return _hotVideoList.length;
    }
    return 0;
  }

  bool _checkHasNewVideoData() {
    if (_newVideoList.isNotEmpty) {
      return true;
    }
    return false;
  }

  int _getNewVideoLength() {
    if (_checkHasNewVideoData()) {
      return _newVideoList.length;
    }
    return 0;
  }

  bool _checkHasData() {
    if (_userInfo != null) {
      return true;
    }
    if (_hotVideoList.isNotEmpty) {
      return true;
    }
    return false;
  }

  void _showNetRequestFailTips() {
    if (_failTipsKey.currentState != null) {
      _failTipsKey.currentState?.showWithAnimation();
    }
  }

  void _reportData() {
    DataReportUtil.instance.reportData(eventName: "Page_creator", params: {
      "creator": _userInfo?.uid ?? "",
      "vistor": Constant.uid,
    });
  }

  List<int> _getVisibleItemIndex(otherHomeVideoType tp) {
    List<int> idxList = [];
    Map<int, double> _map = _hottestVisibleMap;
    if (tp == otherHomeVideoType.HotList) {
      _map = _hotVisibleMap;
    } else if (tp == otherHomeVideoType.NewList) {
      _map = _newVisibleMap;
    }
    //最热
    _map.forEach((int key, double val) {
      if (val > 0) {
        idxList.add(key);
      }
    });
    return idxList;
  }

  //视频曝光上报
  void _reportVideoExposure() {
    if (!_checkHasVideoData()) {
      return;
    }
    //最热
    List<int> visibleList = _getVisibleItemIndex(otherHomeVideoType.Hottest);
    if (visibleList.isNotEmpty && _checkHasHotVideoData()) {
      GetVideoListNewDataListBean bean = _hotVideoList[0];
      VideoReportUtil.reportVideoExposure(VideoExposureType.OtherCenterType, bean.id, bean.uid);
    }
    _reportHotAndNewVideoExposure(otherHomeVideoType.HotList);
    _reportHotAndNewVideoExposure(otherHomeVideoType.NewList);
  }

  void _reportHotAndNewVideoExposure(otherHomeVideoType tp) {
    List<int> visibleList = _getVisibleItemIndex(tp);
    //热门和最新
    List<GetVideoListNewDataListBean> videoList = [];
    if (tp == otherHomeVideoType.HotList) {
      videoList = _hotVideoList;
    } else if (tp == otherHomeVideoType.NewList) {
      videoList = _newVideoList;
    }
    for (int i = 0; i < visibleList.length; i++) {
      int idx = visibleList[i];
      if (idx >= 0 && idx < videoList.length) {
        GetVideoListNewDataListBean bean = videoList[idx];
        VideoReportUtil.reportVideoExposure(VideoExposureType.OtherCenterType, bean.id, bean.uid);
      }
    }
  }
}

///昵称粉丝数背景
class NickNameAndFansNumBgWidget extends StatefulWidget {
  final double? bgWidth;
  final Widget? child;

  NickNameAndFansNumBgWidget({Key? key, this.bgWidth, this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return NickNameAndFansNumBgWidgetState();
  }
}

class NickNameAndFansNumBgWidgetState extends State<NickNameAndFansNumBgWidget> {
  late double _bgWidth;

  @override
  void initState() {
    _bgWidth = widget.bgWidth ?? 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: _bgWidth,
        constraints: BoxConstraints(
          maxWidth: _bgWidth,
        ),
        padding: EdgeInsets.only(left: 15),
        child: widget.child);
  }

  void updateBgWidth(double width) {
    if (_bgWidth != width) {
      _bgWidth = width;
      setState(() {});
    }
  }
}

///粉丝数
class FansNumWidget extends StatefulWidget {
  final String? fansNum;

  FansNumWidget({Key? key, this.fansNum}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FansNumWidgetState();
  }
}

class FansNumWidgetState extends State<FansNumWidget> {
  late String _fansNum;

  @override
  void initState() {
    _fansNum = widget.fansNum ?? "0";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      child: Text(
        '${InternationalLocalizations.getUserFansNum(_fansNum)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
        style: TextStyle(
            color: AppThemeUtil.setDifferentModeColor(
                lightColor: Common.getColorFromHexString("858585", 1.0), darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr),
            fontSize: 12),
      ),
    );
  }

  void updateFanNum(String newNum) {
    if (newNum != _fansNum) {
      _fansNum = newNum;
      setState(() {});
    }
  }
}

///关注按钮
typedef FollowHandleResultCallBack = void Function(bool isFollow, bool isSuccess);

class FollowButton extends StatefulWidget {
  final String uid;
  final bool isFollow;
  final FollowHandleResultCallBack? handleResultCallBack;

  FollowButton({Key? key, required this.uid, this.isFollow = false, this.handleResultCallBack})
      : assert(Common.checkIsNotEmptyStr(uid)),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FollowButtonState();
  }
}

class FollowButtonState extends State<FollowButton> {
  bool _isFollowed = false, _isShowLoading = false, _isHanding = false;

  @override
  void initState() {
    _isFollowed = widget.isFollow;
    super.initState();
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        //按钮
        GestureDetector(
          child: Text(
            _isFollowed ? InternationalLocalizations.videoSubscriptionFinish : InternationalLocalizations.videoSubscription,
            style: TextStyle(
                color: _isFollowed
                    ? AppThemeUtil.setDifferentModeColor(lightColor: Common.getColorFromHexString("A0A0A0", 1.0), darkColorStr: "EBEBEB")
                    : Common.getColorFromHexString("357CFF", 1.0),
                fontSize: 12),
            maxLines: 1,
          ),
          onTap: () {
            _onFollowClick();
          },
        ),
        //loading
        _isShowLoading
            ? Positioned(
                right: calcWidth(_isFollowed, context),
//                  top: 1,
                child: IgnorePointer(
                  ignoring: true,
                  child: SizedBox(
                    height: 15,
                    width: 15,
                    child: Container(
                        color: AppColors.color_transparent,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Common.getColorFromHexString("357CFF", 1.0)),
                        )),
                  ),
                ))
            : Container()
      ],
    );
  }

  void _onFollowClick() {
    if (Common.judgeHasLogIn()) {
      //已经登录,直接follow或是unFollow
      if (_isFollowed) {
        _handleUnFollow();
      } else {
        _handleFollow();
      }
    } else {
      //先进行登录
      WebViewUtil.instance.openWebViewResult(Constant.logInWebViewUrl, context).then((isSuccess) {
        if (isSuccess) {
          //登录成功,重新拉取接口判断是否已经关注过该用户
          _isShowLoading = true;
          _handleLogInSuccess();
        }
      });
    }
  }

  Future<void> _handleLogInSuccess() async {
    bool isFollow = await _checkFollowStatus();
    if (mounted) {
      _isFollowed = isFollow;

      if (_isFollowed) {
        _isShowLoading = false;
        //关注了就不处理了
        setState(() {});
//        _handleUnFollow();
      } else {
        //没有关注的话就进行关注
        _isShowLoading = true;
        _handleFollow();
      }
    }
  }

  ///关注
  void _handleFollow() {
    if (_isHanding) {
      return;
    }
    _isHanding = true;
    setState(() {
      _isShowLoading = true;
    });
    RequestManager.instance.accountFollow(othersHomeTag, Constant.uid, widget.uid).then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data == SimpleResponse.responseSuccess) {
          _isFollowed = true;
          widget.handleResultCallBack?.call(true, true);
        }
      } else {
        if (bean.status == "50007") {
          ToastUtil.showToast(InternationalLocalizations.followSelfErrorTips);
        } else {
          ToastUtil.showToast(bean.msg ?? "");
        }
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      _isHanding = false;
      _isShowLoading = false;
      setState(() {});
    });
  }

  /// 取消关注
  void _handleUnFollow() {
    if (_isHanding) {
      return;
    }
    setState(() {
      _isHanding = true;
      _isShowLoading = true;
    });
    RequestManager.instance.accountUnFollow(othersHomeTag, Constant.uid, widget.uid).then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        if (bean.data == SimpleResponse.responseSuccess) {
          _isFollowed = false;
          widget.handleResultCallBack?.call(false, true);
        }
      } else {
        ToastUtil.showToast(bean.msg ?? "");
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      _isHanding = false;
      _isShowLoading = false;
      setState(() {});
    });
  }

  Future<bool> _checkFollowStatus() async {
    bool isFollow = false;
    await RequestManager.instance.accountIsFollow(othersHomeTag, Constant.uid, widget.uid).then((response) {
      if (response != null) {
        SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          if (bean.data == FollowStateResponse.followStateFollowing || bean.data == FollowStateResponse.followStateFriend) {
            isFollow = true;
          } else {
            isFollow = false;
          }
        }
      }
    }).catchError((err) {
      CosLogUtil.log("$othersHomeTag: check follow status exception, the error is $err");
    }).whenComplete(() {});
    return isFollow;
  }

  static TextStyle getFontStyle() {
    return TextStyle(color: Common.getColorFromHexString("357CFF", 1.0), fontSize: 12);
  }

  void updateFollowStatus(bool isFollowed) {
    if (isFollowed != _isFollowed) {
      _isFollowed = isFollowed;
      setState(() {});
    }
  }

  static double calcWidth(bool isFollowed, BuildContext context) {
    TextStyle style = FollowButtonState.getFontStyle();
    //使用MediaQuery.of(context).textScaleFactor,避免不同机型计算的宽度不够
    TextPainter painter = TextPainter(
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr,
    );
    String text = isFollowed ? InternationalLocalizations.videoSubscriptionFinish : InternationalLocalizations.videoSubscription;
    painter.text = TextSpan(text: text, style: style);
    painter.layout();
    double width = painter.width.roundToDouble() + 4;
    return width;
  }
}
