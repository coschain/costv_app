import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/bean/account_get_info_bean.dart';
import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/exclusive_relation_bean.dart';
import 'package:costv_android/bean/get_ticket_info_bean.dart';
import 'package:costv_android/bean/list_by_message_bean.dart';
import 'package:costv_android/bean/simple_bean.dart';
import 'package:costv_android/bean/simple_proxy_bean.dart';
import 'package:costv_android/bean/video_comment_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/emoji/emoji_picker.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/watch_video_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/comment/bean/comment_list_item_parameter_bean.dart';
import 'package:costv_android/pages/comment/bean/comment_list_parameter_bean.dart';
import 'package:costv_android/pages/comment/comment_children_list_page.dart';
import 'package:costv_android/pages/comment/widget/comment_error_widget.dart';
import 'package:costv_android/pages/comment/widget/comment_list_item.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/dialog/energy_not_enough_dialog.dart';
import 'package:costv_android/pages/video/dialog/video_comment_delete_dialog.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/revenue_calculation_util.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:costv_android/utils/web_view_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/animation/video_add_money_widget.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/net_request_fail_view.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CommentListPage extends StatefulWidget {
  final CommentListParameterBean _bean;

  CommentListPage(this._bean, {Key key}) : super(key: key);

  @override
  _CommentListPageState createState() => _CommentListPageState();
}

enum CommentSendType {
  commentSendTypeNormal,
  commentSendTypeChildren,
}

class _CommentListPageState extends State<CommentListPage> {
  static const String tag = '_CommentPageState';
  final GlobalKey<ScaffoldState> _dialogSKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _pageKey = GlobalKey<ScaffoldState>();
  static const int pageSize = 20;
  static const int commentMaxLength = 300;

  bool _hasNextPage = false;
  int _curPage = 1;
  bool _isLoggedIn = true;
  bool _isSuccessLoad = true;
  bool _isShowLoading = false;
  bool _isFetching = false;
  bool _isFirstSuccessLoad = false;
  bool _isVideoDelete = false;
  bool _isNoData = true;
  GlobalKey<NetRequestFailTipsViewState> _failTipsKey =
      new GlobalKey<NetRequestFailTipsViewState>();
  ListByMessageDataBean _listByMessageDataBean;
  List<CommentListItemBean> _listComment = [];
  ExchangeRateInfoData _exchangeRateInfoData;
  ChainState _chainStateBean;
  AccountInfo _cosInfoBean;
  Map<String, dynamic> _mapRemoteResError;
  Map<String, dynamic> _mapCommentError;
  EnergyNotEnoughDialog _energyNotEnoughDialog;
  VideoCommentDeleteDialog _videoCommentDeleteDialog;
  bool _isAbleSendMsg = false;
  bool _isShowCommentLength = false;
  int _superfluousLength;
  TextEditingController _textController = TextEditingController();
  FocusNode _focusNode = FocusNode();
  String _commentId;
  String _commentName;
  CommentSendType _commentSendType = CommentSendType.commentSendTypeNormal;
  int _sendCommentIndex;
  String _uid;
  GetTicketInfoDataBean _getTicketInfoDataBean;
  bool _isInputFace = false;
  ExclusiveRelationItemBean _exclusiveRelationItemBean;
  Category _selectCategory;

  @override
  void initState() {
    super.initState();
    _mapRemoteResError =
        InternationalLocalizations.mapNetValue['remoteResError'];
    _mapCommentError = InternationalLocalizations.mapNetValue['commentError'];
    _isLoggedIn = Common.judgeHasLogIn();
    if (_isLoggedIn) {
      _loadInitInfo();
    }
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      _cosAccountInfoInit();
    }
  }

  @override
  void dispose() {
    RequestManager.instance.cancelAllNetworkRequest(tag);
    if (_focusNode != null) {
      _focusNode.dispose();
      _focusNode = null;
    }
    if (_textController != null) {
      _textController.dispose();
      _textController = null;
    }
    super.dispose();
  }

  void _loadInitInfo() {
    setState(() {
      _isFetching = true;
      _isShowLoading = true;
    });
    Future.wait([
      RequestManager.instance.getListByMessage(
          tag,
          widget._bean?.vid ?? '',
          widget._bean?.creatorUid ?? '',
          widget._bean?.cid ?? '',
          Constant.uid ?? '',
          _curPage,
          pageSize),
      RequestManager.instance.getExchangeRateInfo(tag),
      CosSdkUtil.instance.getChainState(),
      RequestManager.instance.exclusiveRelation(
          tag, Constant.uid ?? '')
    ]).then((listResponse) {
      if (listResponse == null || !mounted) {
        _handleRequestFail(false);
        return;
      }
      bool isHaveComment = false,
          isHaveExchangeRateInfo = false,
          isHaveChainState = false;
      //评论列表数据
      if (listResponse.length >= 1) {
        isHaveComment =
            _processGetListByMessage(listResponse[0], false, _curPage);
      }
      //汇率数据
      if (listResponse.length >= 2) {
        isHaveExchangeRateInfo = _processExchangeRateInfo(listResponse[1]);
      }
      //公链信息
      if (listResponse.length >= 3) {
        isHaveChainState = _processChainState(listResponse[2]);
      }
      //查看是否解锁创作者表情
      if (listResponse.length >= 4) {
        _processExclusiveRelation(listResponse[3]);
      }
      if (isHaveComment && isHaveExchangeRateInfo && isHaveChainState) {
        _isSuccessLoad = true;
        _isFirstSuccessLoad = true;
      }
    }).catchError((err) {
      CosLogUtil.log("$tag: $err");
      _handleRequestFail(false);
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFetching = false;
        _isShowLoading = false;
      });
    });
  }

  void _cosAccountInfoInit() {
    CosSdkUtil.instance.getAccountChainInfo(Constant.accountName).then((bean) {
      if (bean != null) {
        _cosInfoBean = bean.info;
      }
    });
  }

  /// 处理评论列表返回数据
  bool _processGetListByMessage(Response response, bool isLoadMore, int page) {
    ListByMessageBean bean =
        ListByMessageBean.fromJson(json.decode(response.data));
    if (bean.status == SimpleResponse.statusStrSuccess) {
      if (bean.data != null) {
        if (bean.data.cidStatus == ListByMessageDataBean.cidStatusDelete) {
          _isNoData = true;
        } else {
          _listByMessageDataBean = bean.data;
          if (!isLoadMore) {
            _listComment.clear();
            if (bean.data.top != null) {
              if (!_isFirstSuccessLoad) {
                bean.data.top.isShowTopColor = true;
              }
              _listComment.add(bean.data.top);
            }
          }
          if (!ObjectUtil.isEmptyList(bean.data.list)) {
            _listComment.addAll(bean.data.list);
          }
          _isNoData = (_listComment?.length ?? 0) < 1;
          _isShowLoading = false;
          _hasNextPage = (bean.data.hasNext == "1");
          _curPage = page;
          _isSuccessLoad = true;
          _isFirstSuccessLoad = true;
        }
        setState(() {});
        return true;
      } else {
        _handleRequestFail(isLoadMore);
        return false;
      }
    } else {
      ToastUtil.showToast(_mapCommentError[bean.status] ?? '');
      if (bean.status == SimpleResponse.statusVideoDelete) {
        _isVideoDelete = true;
        _isFirstSuccessLoad = true;
        return false;
      } else {
        _handleRequestFail(isLoadMore);
        return false;
      }
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

  /// 处理公链返回数据
  bool _processChainState(GetChainStateResponse response) {
    if (response != null) {
      _chainStateBean = response?.state;
      return true;
    } else {
      return false;
    }
  }

  /// 处理当前用户与创作者之间的关系
  _processExclusiveRelation(Response response) {
    if (response == null) {
      return false;
    }
    ExclusiveRelationBean bean =
        ExclusiveRelationBean.fromJson(json.decode(response.data));
    if (bean != null &&
        bean.status == SimpleResponse.statusStrSuccess &&
        bean.data != null &&
        !ObjectUtil.isEmptyList(bean.data.list) &&
        bean.data.list[0] != null) {
      _exclusiveRelationItemBean = bean.data.list[0];
    }
  }

  /// 获取一级评论列表
  Future<void> _httpGetListByMessage(bool isLoadMore) async {
    if (isLoadMore && !_hasNextPage) {
      return;
    }
    int page = isLoadMore ? _curPage + 1 : 1;
    await RequestManager.instance
        .getListByMessage(
            tag,
            widget._bean?.vid ?? '',
            widget._bean?.creatorUid ?? '',
            widget._bean?.cid ?? '',
            Constant.uid ?? '',
            _curPage,
            pageSize)
        .then((response) {
      if (response == null || !mounted) {
        if (mounted && !isLoadMore) {
          _handleRequestFail(isLoadMore);
        }
        return;
      }
      _processGetListByMessage(response, isLoadMore, page);
    }).catchError((err) {
      CosLogUtil.log("$tag: $err");
      _handleRequestFail(isLoadMore);
    }).whenComplete(() {
      if (mounted) {
        _isFetching = false;
        if (_isShowLoading) {
          setState(() {
            _isShowLoading = false;
          });
        }
      }
    });
  }

  /// 下拉刷新重新拉取数据
  Future<void> _reloadData() async {
    if (_isFetching) {
      CosLogUtil.log("$tag: is fething data when reload");
      return;
    }
    _isFetching = true;
    await _httpGetListByMessage(false);
    _isFetching = false;
  }

  ///上啦加载更多数据
  Future<void> _loadNextPageData() async {
    if (_isFetching) {
      CosLogUtil.log("$tag: is fething data when load next page");
      return;
    }
    _isFetching = true;
    await _httpGetListByMessage(true);
    _isFetching = false;
  }

  void _handleRequestFail(bool isLoadMore) {
    if (!_isFirstSuccessLoad) {
      _isSuccessLoad = false;
    } else {
      if (!isLoadMore && _isSuccessLoad) {
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

  bool _checkIsEnergyEnough() {
    double energy = RevenueCalculationUtil.calCurrentEnergy(
        _cosInfoBean?.votePower?.toString(),
        _cosInfoBean?.vest?.value?.toString());
    double lowest = RevenueCalculationUtil.calLowestEnergyConsume(
        _cosInfoBean?.vest?.value?.toString());

    CosLogUtil.log('$tag energy: $energy, lowest: $lowest');
    return energy >= lowest;
  }

  Decimal _getUserMaxPower() {
    return Common.getUserMaxPower(_cosInfoBean);
  }

  void _addVoterPowerToComment(CommentListItemBean bean) {
    if (bean != null) {
      Decimal val = Decimal.parse(bean.votepower);
      val += _getUserMaxPower();
      bean.votepower = val.toStringAsFixed(0);
    }
  }

  /// 添加评论点赞
  void _httpCommentLike(String cid, int index, String accountName) async {
    setState(() {
      _isShowLoading = true;
      _isFetching = true;
    });
    if (_cosInfoBean == null) {
      //先公链获取视频account信息,否则点赞成功之后没法计算评论的增值
      AccountResponse bean = await CosSdkUtil.instance
          .getAccountChainInfo(Constant.accountName ?? '');
      if (bean != null) {
        _cosInfoBean = bean.info;
      } else {
        ToastUtil.showToast(InternationalLocalizations.httpError);
        return;
      }
    }
    RequestManager.instance
        .commentLike(tag, cid ?? '', accountName)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleProxyBean bean =
          SimpleProxyBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleProxyResponse.statusStrSuccess &&
          bean.data != null) {
        GlobalObjectKey<VideoAddMoneyWidgetState> commentKey;
        String addVal = "";
        if (bean.data.ret == SimpleProxyResponse.responseSuccess) {
          CommentListItemBean commentListItemBean = _listComment[index];
          commentListItemBean?.isLike = '1';
          if (!TextUtil.isEmpty(commentListItemBean?.likeCount)) {
            commentListItemBean?.likeCount =
                (int.parse(commentListItemBean?.likeCount) + 1).toString();
          }
          commentKey =
              Common.getAddMoneyViewKeyFromSymbol(commentListItemBean.cid);
          addVal = Common.calcCommentAddedIncome(
              _cosInfoBean,
              _exchangeRateInfoData,
              _chainStateBean,
              commentListItemBean.votepower);
          _addVoterPowerToComment(commentListItemBean);
          if (Common.checkIsNotEmptyStr(addVal) &&
              commentKey != null &&
              commentKey.currentState != null) {
            commentKey.currentState.startShowWithAni(
                "+ " + '${Common.getCurrencySymbolByLanguage()} $addVal');
          }
        } else {
          if (_mapRemoteResError != null && bean.data.ret != null) {
            ToastUtil.showToast(_mapRemoteResError[bean.data.ret] ?? '');
          } else {
            ToastUtil.showToast(bean?.data?.error ?? '');
          }
        }
      } else {
        ToastUtil.showToast(bean?.data?.error ?? '');
      }
    }).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _isShowLoading = false;
        _isFetching = false;
      });
    });
  }

  void _showEnergyNotEnoughDialog() {
    if (_energyNotEnoughDialog == null) {
      _energyNotEnoughDialog =
          EnergyNotEnoughDialog(tag, _pageKey, _dialogSKey);
    }

    double energy = RevenueCalculationUtil.calCurrentEnergy(
        _cosInfoBean.votePower?.toString(),
        _cosInfoBean.vest.value?.toString());
    double maxEnergy = RevenueCalculationUtil.vestToEnergy(
        _cosInfoBean.vest?.value?.toString());
    int resumeMinutes =
        RevenueCalculationUtil.calResumeLowestEnergyMinutes(energy, maxEnergy);

    _energyNotEnoughDialog.initData(resumeMinutes.toString());
    _energyNotEnoughDialog.show();
  }

  ///添加观看历史
  void _httpAddWatchHistory() {
    RequestManager.instance
        .addHistory(tag, Constant.uid ?? '', widget._bean?.vid ?? '')
        .then((response) {
      if (response != null) {
        SimpleBean bean = SimpleBean.fromJson(json.decode(response?.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          EventBusHelp.getInstance()
              .fire(WatchVideoEvent(widget._bean?.vid ?? ''));
        }
      }
    });
  }

  void _checkAbleCommentLike(String isLike, String cid, int index) {
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      if (isLike == CommentListItemBean.isLikeNo) {
        if (_checkIsEnergyEnough()) {
          _httpCommentLike(cid, index, Constant.accountName);
        } else {
          _showEnergyNotEnoughDialog();
        }
      }
    } else {
      if (Platform.isAndroid) {
        WebViewUtil.instance
            .openWebViewResult(Constant.logInWebViewUrl)
            .then((isSuccess) {
          if (isSuccess != null && isSuccess) {
            _checkAbleCommentLike(isLike, cid, index);
            _httpAddWatchHistory();
          }
        });
      } else {
        Navigator.of(context).push(SlideAnimationRoute(
          builder: (_) {
            return WebViewPage(
              Constant.logInWebViewUrl,
            );
          },
        )).then((isSuccess) {
          if (isSuccess != null && isSuccess) {
            _checkAbleCommentLike(isLike, cid, index);
            _httpAddWatchHistory();
          }
        });
      }
    }
  }

  Widget _getCommentListItem(int index) {
    CommentListItemParameterBean bean = CommentListItemParameterBean();
    bean.showType = CommentListItemParameterBean.showTypeCommentList;
    bean.commentListItemBean = _listComment[index];
    bean.total = _listByMessageDataBean?.total ?? '';
    bean.index = index;
    bean.commentLength = _listComment?.length ?? 0;
    bean.exchangeRateInfoData = _exchangeRateInfoData;
    bean.chainStateBean = _chainStateBean;
    bean.uid = widget._bean?.creatorUid ?? '';
    return CommentListItem(
      bean: bean,
      clickCommentLike: (commentListItemBean, index) {
        if (commentListItemBean?.vestStatus !=
            VideoInfoResponse.vestStatusFinish) {
          _checkAbleCommentLike(commentListItemBean?.isLike ?? '',
              commentListItemBean?.cid ?? '', index);
        } else {
          ToastUtil.showToast(InternationalLocalizations.videoLinkFinishHint);
        }
      },
      clickCommentReply: (commentListItemBean, index) {
        CommentListParameterBean bean = CommentListParameterBean();
        bean.showType = CommentListParameterBean.showTypeVideoComment;
        bean.isReply = true;
        bean.videoId = widget._bean.videoId;
        bean.vid = widget._bean.vid;
        bean.creatorUid = widget._bean.creatorUid;
        bean.cid = commentListItemBean.cid;
        bean.nickName = widget._bean.nickName;
        bean.pid = bean?.cid;
        bean.videoSource = widget._bean.videoSource;
        bean.parentBean = commentListItemBean;
        bean.videoTitle = widget._bean.videoTitle;
        bean.videoImage = widget._bean.videoImage;
        bean.uid = commentListItemBean.uid;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) {
            return CommentChildrenListPage(bean);
          },
        ));
      },
      clickChildrenWindows: (commentListItemBean, index, isOpenKeyboard) {
        CommentListParameterBean bean = CommentListParameterBean();
        bean.showType = CommentListParameterBean.showTypeVideoComment;
        bean.isReply = false;
        bean.videoId = widget._bean.videoId;
        bean.vid = widget._bean.vid;
        bean.creatorUid = widget._bean.creatorUid;
        bean.cid = commentListItemBean.cid;
        bean.nickName = widget._bean.nickName;
        bean.pid = bean?.cid;
        bean.videoSource = widget._bean.videoSource;
        bean.parentBean = commentListItemBean;
        bean.videoTitle = widget._bean.videoTitle;
        bean.videoImage = widget._bean.videoImage;
        bean.uid = commentListItemBean.uid;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) {
            return CommentChildrenListPage(bean);
          },
        ));
      },
      clickCommentDelete: (commentListItemBean) {
        if (_videoCommentDeleteDialog == null) {
          _videoCommentDeleteDialog =
              VideoCommentDeleteDialog(tag, _pageKey, _dialogSKey);
        }
        _videoCommentDeleteDialog.initData(commentListItemBean?.id ?? '',
            commentListItemBean?.vid ?? '', widget._bean?.creatorUid ?? '', () {
          if (index != null &&
              _listComment != null &&
              index < _listComment.length) {
            _listComment.removeAt(index);
            if (!TextUtil.isEmpty(_listByMessageDataBean?.total)) {
              int total = int.parse(_listByMessageDataBean?.total);
              total--;
              _listByMessageDataBean?.total = total.toString();
            }
            setState(() {
              _isFetching = false;
              _isShowLoading = false;
            });
          }
        }, handleDeleteCallBack: (isProcessing, isSuccess) {});
        _videoCommentDeleteDialog.showVideoCommentDeleteDialog();
      },
      clickCommentChildren: (commentListItemBean) {
        setState(() {
          _commentSendType = CommentSendType.commentSendTypeChildren;
          _commentId = commentListItemBean.cid;
          _commentName = commentListItemBean.commentName;
          _sendCommentIndex = commentListItemBean.index;
          _uid = commentListItemBean.uid;
        });
      },
      darkModeBgColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
    );
  }

  void clearCommentInput() {
    _textController.text = '';
    _commentSendType = CommentSendType.commentSendTypeNormal;
    _isAbleSendMsg = false;
    //评论成功上报
    DataReportUtil.instance.reportData(
        eventName: "Comments",
        params: {"Comments": "1", "is_comment_videopage": "0"});
  }

  CommentListItemBean _buildCommentBean(String commentId, String content) {
    String vid = widget._bean?.videoId ?? '';
    String uid = widget._bean?.creatorUid ?? '';
    int timestamp =
        (Decimal.parse(DateTime.now().millisecondsSinceEpoch.toString()) /
                Decimal.parse('1000'))
            .toInt();
    String nickName = Constant?.accountGetInfoDataBean?.nickname ?? '';
    String avatar = Constant?.accountGetInfoDataBean?.avatar ?? '';
    String isCreator = CommentListItemBean.isCreatorNo;
    String isCertification = "0";
    if (Constant.uid == uid) {
      isCreator = CommentListItemBean.isCreatorYes;
      isCertification = "0";
    }
    CommentListItemBean commentListItemBean = CommentListItemBean(
      '',
      vid,
      '',
      content,
      uid,
      '',
      '',
      '0',
      commentId,
      '',
      '',
      '0',
      '0',
      '1',
      timestamp.toString(),
      timestamp.toString(),
      '',
      '',
      new CommentListUserBean(nickName, avatar, '',
          Constant?.accountGetInfoDataBean?.imageCompress, isCertification),
      '',
      null,
      '0',
      '0',
      _getTicketInfoDataBean?.isTicket ?? '0',
      _getTicketInfoDataBean?.isTop ?? '0',
      isCreator,
      "0",
    );
    commentListItemBean.isShowInsertColor = true;
    commentListItemBean.isShowDeleteComment = false;
    return commentListItemBean;
  }

  CommentListChildrenBean _buildCommentChildrenBean(
      String pid, String commentId, String content) {
    String vid = widget._bean?.videoId ?? '';
    String uid = widget._bean?.creatorUid ?? '';
    int timestamp =
        (Decimal.parse(DateTime.now().millisecondsSinceEpoch.toString()) /
                Decimal.parse('1000'))
            .toInt();
    String nickName = Constant?.accountGetInfoDataBean?.nickname ?? '';
    String avatar = Constant?.accountGetInfoDataBean?.avatar ?? '';
    String isCreator = CommentListItemBean.isCreatorNo;
    String isCertification = "0";
    if (Constant.uid == uid) {
      isCreator = CommentListItemBean.isCreatorYes;
      isCertification = "0";
    }
    CommentListChildrenBean commentListChildrenBean =
        new CommentListChildrenBean(
            '',
            vid,
            pid,
            content,
            uid,
            '0',
            commentId,
            '',
            '0',
            '0',
            '1',
            timestamp.toString(),
            timestamp.toString(),
            '',
            '',
            new CommentListChildrenUserBean(nickName, avatar,
                Constant?.accountGetInfoDataBean?.imageCompress),
            _getTicketInfoDataBean?.isTicket ?? '0',
            '0',
            isCreator,
            isCertification,
            "0");
    commentListChildrenBean.isShowInsertColor = true;
    return commentListChildrenBean;
  }

  void refreshCommentTop(String replyId, String content) {
    if (_commentSendType == CommentSendType.commentSendTypeNormal) {
      CommentListItemBean commentListItemBean =
          _buildCommentBean(replyId, content);
      _listComment.insert(1, commentListItemBean);
      Future.delayed(Duration(milliseconds: 1500), () {
        setState(() {
          commentListItemBean.isShowInsertColor = false;
        });
      });
    } else {
      if (_listComment.length > _sendCommentIndex &&
          _listComment[_sendCommentIndex] is CommentListItemBean) {
        CommentListItemBean commentListItemBean =
            _listComment[_sendCommentIndex];
        CommentListChildrenBean commentListChildrenBean =
            _buildCommentChildrenBean(
                commentListItemBean?.cid ?? '', replyId, content);
        if (!ObjectUtil.isEmptyList(commentListItemBean?.children)) {
          commentListItemBean.children.insert(0, commentListChildrenBean);
        } else {
          commentListItemBean.children = [commentListChildrenBean];
        }
        Future.delayed(Duration(milliseconds: 1500), () {
          setState(() {
            commentListChildrenBean.isShowInsertColor = false;
          });
        });
      }
    }
    clearCommentInput();
  }

  /// 读取用户信息
  void _httpUserInfo(String replyId, String content) {
    RequestManager.instance.accountGetInfo(tag, Constant.uid).then((response) {
      if (response == null || !mounted) {
        clearCommentInput();
        return;
      }
      AccountGetInfoBean bean =
          AccountGetInfoBean.fromJson(json.decode(response.data));
      if (bean != null &&
          bean.status == SimpleResponse.statusStrSuccess &&
          bean.data != null) {
        Constant.accountGetInfoDataBean = bean.data;
        refreshCommentTop(replyId, content);
      } else {
        clearCommentInput();
      }
    }).whenComplete(() {
      setState(() {
        _isFetching = false;
        _isShowLoading = false;
      });
    });
  }

  ///获取用户打赏视频详情
  void _httpGetTicketInfo(
      String vid, String uid, String replyId, String content) {
    RequestManager.instance.getTicketInfo(tag, vid, uid).then((response) {
      if (response != null && !ObjectUtil.isEmptyString(response.data)) {
        GetTicketInfoBean bean =
            GetTicketInfoBean.fromJson(json.decode(response.data));
        if (bean.status == SimpleResponse.statusStrSuccess) {
          _getTicketInfoDataBean = bean.data;
          if (Constant.accountGetInfoDataBean == null) {
            _httpUserInfo(replyId, content);
          } else {
            refreshCommentTop(replyId, content);
            setState(() {
              _isFetching = false;
              _isShowLoading = false;
            });
          }
        }
      }
    });
  }

  /// 添加留言
  void _httpVideoComment(
      String accountName, String id, String content, String vid, String uid) {
    setState(() {
      _isFetching = true;
      _isShowLoading = true;
    });
    RequestManager.instance
        .videoComment(tag, id, accountName, content)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      VideoCommentBean bean =
          VideoCommentBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleProxyResponse.statusStrSuccess &&
          bean.data != null) {
        if (bean.data.ret == SimpleProxyResponse.responseSuccess) {
          _httpGetTicketInfo(vid, uid, bean.data?.replyid ?? '', content);
        } else {
          if (_mapRemoteResError != null && bean.data.ret != null) {
            ToastUtil.showToast(_mapRemoteResError[bean.data.ret] ?? '');
          } else {
            ToastUtil.showToast(bean?.data?.error ?? '');
          }
          setState(() {
            _isFetching = false;
            _isShowLoading = false;
          });
        }
      } else {
        ToastUtil.showToast(bean?.data?.error ?? '');
        setState(() {
          _isFetching = false;
          _isShowLoading = false;
        });
      }
    });
  }

  void _checkAbleVideoComment(String id, String vid, String uid) {
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      if (_isAbleSendMsg) {
        String content;
        if (_commentSendType == CommentSendType.commentSendTypeNormal) {
          content = _textController.text.trim();
        } else {
          content = Constant.commentSendHtml(
              _uid, _commentName, _textController.text.trim());
        }
        if (_isInputFace) {
          setState(() {
            _isInputFace = false;
            _selectCategory = null;
          });
        }
        FocusScope.of(context).requestFocus(FocusNode());
        _httpVideoComment(Constant.accountName, id, content, vid, uid);
      }
    } else {
      if (Platform.isAndroid) {
        WebViewUtil.instance
            .openWebViewResult(Constant.logInWebViewUrl)
            .then((isSuccess) {
          if (isSuccess != null && isSuccess) {
            _checkAbleVideoComment(id, vid, uid);
            _httpAddWatchHistory();
          }
        });
      } else {
        Navigator.of(context).push(SlideAnimationRoute(
          builder: (_) {
            return WebViewPage(
              Constant.logInWebViewUrl,
            );
          },
        )).then((isSuccess) {
          if (isSuccess != null && isSuccess) {
            _checkAbleVideoComment(id, vid, uid);
            _httpAddWatchHistory();
          }
        });
      }
    }
  }

  ///创建评论回复的输入框相关widget
  Widget _buildCommentInputWidget() {
    double inputHeight;
    if (!_isShowCommentLength) {
      inputHeight = AppDimens.item_size_32;
    }
    String imgInput;
    if (_isInputFace) {
      imgInput = AppThemeUtil.getCommentInputText();
    } else {
      imgInput = AppThemeUtil.getCommentInputEmoji();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(
              vertical: AppDimens.margin_6_5, horizontal: AppDimens.margin_15),
          decoration: BoxDecoration(
            color: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_ffffff,
              darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.30),
                offset: Offset(0, 0),
                blurRadius: 4,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                  child: Container(
                height: inputHeight,
                constraints: BoxConstraints(
                  maxHeight: AppDimens.item_size_87,
                ),
                child: TextField(
                  onChanged: (str) {
                    commentChange(str);
                  },
                  controller: _textController,
                  focusNode: _focusNode,
                  readOnly: _isInputFace,
                  style: TextStyle(
                    color: AppThemeUtil.setDifferentModeColor(
                      lightColor: AppColors.color_333333,
                      darkColorStr:
                          DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                    ),
                    fontSize: AppDimens.text_size_12,
                  ),
                  maxLines: null,
                  decoration: InputDecoration(
                    fillColor: AppThemeUtil.setDifferentModeColor(
                      lightColor: AppColors.color_ebebeb,
                      darkColorStr: "333333",
                    ),
                    filled: true,
                    hintStyle: TextStyle(
                      color: AppThemeUtil.setDifferentModeColor(
                        lightColor: AppColors.color_a0a0a0,
                        darkColorStr:
                            DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                      ),
                      fontSize: AppDimens.text_size_12,
                    ),
                    hintText: _commentSendType ==
                            CommentSendType.commentSendTypeNormal
                        ? InternationalLocalizations.videoCommentInputHint
                        : '${InternationalLocalizations.videoCommentReply} @$_commentName：',
                    contentPadding: EdgeInsets.only(
                        left: AppDimens.margin_10,
                        top: AppDimens.margin_6_5,
                        bottom: AppDimens.margin_6_5),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.color_transparent),
                      borderRadius:
                          BorderRadius.circular(AppDimens.radius_size_15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.color_3674ff),
                      borderRadius:
                          BorderRadius.circular(AppDimens.radius_size_15),
                    ),
                  ),
                ),
              )),
              InkWell(
                onTap: () {
                  if (Common.isAbleClick()) {
                    setState(() {
                      _isInputFace = !_isInputFace;
                      _selectCategory = null;
                      if (!_isInputFace) {
                        FocusScope.of(context).requestFocus(_focusNode);
                      }
                    });
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(left: AppDimens.margin_10),
                  padding: EdgeInsets.all(AppDimens.margin_5),
                  child: Image.asset(imgInput),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: AppDimens.margin_5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Offstage(
                      offstage: !_isShowCommentLength,
                      child: Container(
                        margin: EdgeInsets.only(right: AppDimens.margin_5),
                        child: Text(
                          '$_superfluousLength',
                          style: AppStyles.text_style_c20a0a_12,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (Common.isAbleClick()) {
                          String id;
                          if (_commentSendType ==
                              CommentSendType.commentSendTypeNormal) {
                            id = widget._bean?.videoId ?? '';
                          } else {
                            id = _commentId ?? '';
                          }
                          _checkAbleVideoComment(id,
                              widget._bean?.videoId ?? '', Constant?.uid ?? '');
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(AppDimens.margin_5),
                        child: AutoSizeText(
                          InternationalLocalizations.videoCommentSendMessage,
                          style: _isAbleSendMsg
                              ? AppStyles.text_style_3674ff_14
                              : AppStyles.text_style_a0a0a0_14,
                          minFontSize: 8,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        Offstage(
          offstage: !_isInputFace,
          child: EmojiPicker(
            rows: 5,
            columns: 10,
            bgColor: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_f3f3f3,
              darkColor: AppColors.color_3e3e3e,
            ),
            buttonMode: ButtonMode.MATERIAL,
            categoryIcons: CategoryIcons(
                epamoji: Image.asset('assets/images/ic_face_voepa.png')),
            level: _exclusiveRelationItemBean?.level ??
                ExclusiveRelationItemBean.levelLock,
            selectedCategory: _selectCategory,
            onEmojiSelected: (emoji, category) {
              CosLogUtil.log('$tag $category $emoji');
              _textController.text = _textController.text + emoji.emoji;
              commentChange(_textController.text);
            },
            onSelectCategoryChange: (selectedCategory) {
              _selectCategory = selectedCategory;
            },
          ),
        )
      ],
    );
  }

  void commentChange(String str) {
    if (str != null && str.trim().isNotEmpty) {
      if (str.trim().length > commentMaxLength) {
        setState(() {
          _superfluousLength = commentMaxLength - str.trim().length;
          if (_isAbleSendMsg) {
            _isAbleSendMsg = false;
          }
          if (!_isShowCommentLength) {
            _isShowCommentLength = true;
          }
        });
      } else {
        setState(() {
          if (!_isAbleSendMsg) {
            _isAbleSendMsg = true;
          }
          if (_isShowCommentLength) {
            _isShowCommentLength = false;
          }
        });
      }
    } else {
      if (_isAbleSendMsg) {
        setState(() {
          _isAbleSendMsg = false;
        });
      }
      if (_isShowCommentLength) {
        setState(() {
          _isShowCommentLength = false;
        });
      }
    }
  }

  Widget _buildVideoCover(double coverWidth, double coverHeight) {
    String videoImage = _listByMessageDataBean
            ?.videoInfo?.videoImageCompress?.videoCompressUrl ??
        '';
    if (ObjectUtil.isEmptyString(videoImage)) {
      videoImage = _listByMessageDataBean?.videoInfo?.videoCoverBig ?? '';
    }
    if (ObjectUtil.isEmptyString(videoImage)) {
      videoImage = widget._bean?.videoImage ?? '';
    }
    return Container(
      width: coverWidth,
      height: coverHeight,
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
        placeholder: (BuildContext context, String url) {
          return Container();
        },
        imageUrl: videoImage,
        errorWidget: (context, url, error) => Container(),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      height: AppDimens.item_size_45,
      color: AppThemeUtil.setDifferentModeColor(
        lightColor: AppColors.color_ffffff,
        darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          InkWell(
            child: Container(
              padding: EdgeInsets.all(AppDimens.margin_10),
              child: Image.asset(AppThemeUtil.getBackIcn()),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Text(title,
              style: TextStyle(
                color: AppThemeUtil.setDifferentModeColor(
                  lightColor: AppColors.color_333333,
                  darkColorStr:
                      DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                ),
                fontSize: AppDimens.text_size_15,
              ))
        ],
      ),
    );
  }

  Widget _buildTopVideo() {
    double screenWidth = MediaQuery.of(context).size.width;
    double ratio = screenWidth / 375;
    double coverRatio = 9.0 / 16.0;
    double coverWidth = 65.0 * ratio;
    double coverHeight = coverWidth * coverRatio;
    String title = _listByMessageDataBean?.videoInfo?.title ?? '';
    if (ObjectUtil.isEmptyString(title)) {
      title = widget._bean?.videoTitle ?? '';
    }
    return Column(
      children: <Widget>[
        Container(
          color: AppThemeUtil.setDifferentModeColor(
            lightColor: AppColors.color_f6f6f6,
            darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
          ),
          height: AppDimens.item_size_10,
        ),
        InkWell(
          onTap: () {
            Navigator.of(context).push(SlideAnimationRoute(
              builder: (_) {
                return VideoDetailsPage(
                    VideoDetailPageParamsBean.createInstance(
                  vid: widget._bean?.vid ?? '',
                  uid: widget._bean?.creatorUid ?? '',
                  videoSource: widget._bean?.videoSource ?? '',
                  enterSource: VideoDetailsEnterSource
                      .VideoDetailsEnterSourceNotification,
                ));
              },
              settings: RouteSettings(name: videoDetailPageRouteName),
              isCheckAnimation: true,
            ));
          },
          child: Container(
            height: AppDimens.item_size_67,
            padding: EdgeInsets.only(
                left: AppDimens.margin_15, right: AppDimens.margin_15),
            color: AppThemeUtil.setDifferentModeColor(
                lightColor: AppColors.color_ffffff,
                darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: AppThemeUtil.setDifferentModeColor(
                      lightColor: AppColors.color_333333,
                      darkColorStr:
                          DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                    ),
                    fontSize: AppDimens.text_size_12,
                  ),
                ),
                _buildVideoCover(coverWidth, coverHeight)
              ],
            ),
          ),
        ),
        Container(
          color: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_ebebeb, darkColorStr: "3E3E3E"),
          height: AppDimens.item_line_height_0_5,
        ),
      ],
    );
  }

  Widget _getPageBody() {
    if (!_isLoggedIn) {
      //未登录提醒用户登录
      return PageRemindWidget(
        clickCallBack: _startLogIn,
        remindType: RemindType.CommentListPageLogIn,
      );
    } else {
      if (!_isSuccessLoad) {
        //第一次数据拉取失败
        return LoadingView(
          isShow: _isShowLoading,
          child: PageRemindWidget(
            clickCallBack: () {
              _reloadData();
            },
            remindType: RemindType.NetRequestFail,
          ),
        );
      } else if (_isFirstSuccessLoad && (_isNoData || _isVideoDelete)) {
        //没有消息数据
        if (_isVideoDelete) {
          return LoadingView(
            isShow: _isShowLoading,
            child: Column(
              children: <Widget>[
                _buildTitle(InternationalLocalizations.back),
                Expanded(
                    child: CommentErrorWidget(
                        commentErrorType: CommentErrorType.VideoDelete))
              ],
            ),
          );
        } else {
          return LoadingView(
            isShow: _isShowLoading,
            child: Column(
              children: <Widget>[
                _buildTitle(InternationalLocalizations.commentTitle),
                _buildTopVideo(),
                Expanded(
                    child: CommentErrorWidget(
                        commentErrorType: CommentErrorType.CommentDelete))
              ],
            ),
          );
        }
      }
      Widget body;
      if (!_isFirstSuccessLoad && _isShowLoading) {
        body = Container();
      } else {
        body = Container(
          color: AppThemeUtil.setDifferentModeColor(
            darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
          ),
          child: Column(
            children: <Widget>[
              _buildTitle(InternationalLocalizations.commentTitle),
              _buildTopVideo(),
              Expanded(
                child: NetRequestFailTipsView(
                  key: _failTipsKey,
                  baseWidget: RefreshAndLoadMoreListView(
                    hasTopPadding: false,
                    pageSize: pageSize,
                    isHaveMoreData: _hasNextPage,
                    itemCount: _listComment.length,
                    itemBuilder: (context, index) {
                      return _getCommentListItem(index);
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
              ),
              _buildCommentInputWidget()
            ],
          ),
        );
      }
      return LoadingView(
        isShow: _isShowLoading,
        child: body,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeUtil.setDifferentModeColor(
        lightColor: AppColors.color_f6f6f6,
        darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
      ),
      key: _pageKey,
      body: WillPopScope(
        onWillPop: () async {
          if (Common.isAbleClick() && _isInputFace) {
            setState(() {
              _isInputFace = false;
              _selectCategory = null;
            });
            return false;
          }
          return true;
        },
        child: Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          color: AppThemeUtil.setDifferentModeColor(
            lightColor: AppColors.color_f6f6f6,
            darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
          ),
          child: _getPageBody(),
        ),
      ),
    );
  }
}
