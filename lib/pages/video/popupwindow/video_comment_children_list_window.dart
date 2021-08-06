import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/comment_children_list_bean.dart';
import 'package:costv_android/bean/comment_list_bean.dart';
import 'package:costv_android/bean/simple_proxy_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/video/bean/comment_children_list_parameter_bean.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/revenue_calculation_util.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/animation/video_add_money_widget.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:decimal/decimal.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:cosdart/types.dart';

class VideoCommentChildrenListWindow extends StatefulWidget {
  final CommentChildrenListParameterBean _bean;

  VideoCommentChildrenListWindow(this._bean, {Key key}) : super(key: key);

  @override
  _VideoCommentChildrenListWindowState createState() =>
      _VideoCommentChildrenListWindowState();
}

class _VideoCommentChildrenListWindowState
    extends State<VideoCommentChildrenListWindow> {
  static const String tag = '_VideoCommentChildrenListWindowState';
  static const int pageSize = 10;
  AccountInfo _cosInfoBean;
  bool _isNetIng = false;
  int _page = 1;
  bool _isHaveMoreData = true;
  List<dynamic> _listData = [];
  String _commentTotal;
  bool _isAbleSendMsg = false;
  TextEditingController _textController;
  String _fatherCommentName;
  String _commentName;
  String _commentId;
  String _uid;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _cosInfoBean = widget._bean.cosInfoBean;
    _httpVideoCommentChildrenList(false);
    if (widget?._bean?.commentListTopBean != null) {
      _fatherCommentName =
          widget?._bean?.commentListTopBean?.user?.nickname ?? '';
      _commentName = _fatherCommentName;
      _commentId = widget?._bean?.commentListTopBean?.cid ?? '';
    } else {
      _fatherCommentName =
          widget?._bean?.commentListDataListBean?.user?.nickname ?? '';
      _commentName = _fatherCommentName;
      _commentId = widget?._bean?.commentListDataListBean?.cid ?? '';
    }
  }

  /// 获取评论的回复列表（子评论）
  void _httpVideoCommentChildrenList(bool isLoadMore) {
    if (!isLoadMore) {
      setState(() {
        _isNetIng = true;
      });
      _listData.clear();
      _page = 1;
    }
    RequestManager.instance
        .videoCommentChildrenList(
            tag, widget._bean.vid, widget._bean.pid, _page, pageSize,
            uid: widget._bean.uid ?? '')
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      CommentChildrenListBean bean =
          CommentChildrenListBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess && bean.data != null) {
        if (bean.data.list != null && bean.data.list.isNotEmpty) {
          if (!isLoadMore) {
            if (widget._bean.commentListTopBean != null) {
              _listData.add(widget._bean.commentListTopBean);
            } else {
              _listData.add(widget._bean.commentListDataListBean);
            }
          }
          _listData.addAll(bean.data.list);
          _isHaveMoreData = true;
          _page++;
          _commentTotal = bean.data.total;
        } else {
          _isHaveMoreData = false;
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

  /// 添加评论点赞
  void _httpCommentLike(String cid, int index, String accountName) async {
    setState(() {
      _isNetIng = true;
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
        if (bean.data.ret == SimpleProxyResponse.responseSuccess) {
          CommentChildrenDataListBean childrenDataListBean = _listData[index];
          childrenDataListBean?.isLike = '1';
          if (!TextUtil.isEmpty(childrenDataListBean?.likeCount)) {
            childrenDataListBean?.likeCount =
                (int.parse(childrenDataListBean?.likeCount) + 1).toString();
          }
          String addVal = Common.calcCommentAddedIncome(
              _cosInfoBean,
              widget._bean.exchangeRateInfoData,
              widget._bean.chainStateBean,
              childrenDataListBean.votepower);
          if (Common.checkIsNotEmptyStr(addVal)) {
            var key = _getAddMoneyViewKeyFromSymbol(cid);
            if (key != null && key.currentState != null) {
              key.currentState.startShowWithAni(addVal);
            }
          }
          _addVoterPowerToComment(childrenDataListBean);
        } else {
          if (widget._bean.mapRemoteResError != null && bean.data.ret != null) {
            ToastUtil.showToast(
                widget._bean.mapRemoteResError[bean.data.ret] ?? '');
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
        _isNetIng = false;
      });
    });
  }

  void _checkAbleCommentLike(bool isLike, String cid, int index) {
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      if (!isLike) {
        _httpCommentLike(cid, index, Constant.accountName ?? '');
      }
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) {
        return WebViewPage(Constant.logInWebViewUrl);
      })).then((isSuccess) {
        if (isSuccess != null && isSuccess) {
          _checkAbleCommentLike(isLike, cid, index);
        }
      });
    }
  }

  void _checkAbleVideoComment() {
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      if (_isAbleSendMsg) {
        String content;
        if (_commentName == _fatherCommentName) {
          content = _textController.text.trim();
        } else {
          content = Constant.commentSendHtml(
              _uid, _commentName, _textController.text.trim());
        }
        FocusScope.of(context).requestFocus(FocusNode());
        _httpVideoComment(Constant.accountName, _commentId, content);
      }
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) {
        return WebViewPage(Constant.logInWebViewUrl);
      })).then((isSuccess) {
        if (isSuccess != null && isSuccess) {
          _checkAbleVideoComment();
        }
      });
    }
  }

  /// 添加留言
  void _httpVideoComment(String accountName, String id, String content) {
    setState(() {
      _isNetIng = true;
    });
    RequestManager.instance
        .videoComment(tag, id, accountName, content)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleProxyBean bean =
          SimpleProxyBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleProxyResponse.statusStrSuccess &&
          bean.data != null) {
        if (bean.data.ret == SimpleProxyResponse.responseSuccess) {
          _textController.text = '';
          _isAbleSendMsg = false;
          Future.delayed(Duration(seconds: 3), () {
            _httpVideoCommentChildrenList(false);
          });
        } else {
          if (widget._bean.mapRemoteResError != null && bean.data.ret != null) {
            ToastUtil.showToast(
                widget._bean.mapRemoteResError[bean.data.ret] ?? '');
          } else {
            ToastUtil.showToast(bean?.data?.error ?? '');
          }
          setState(() {
            _isNetIng = false;
          });
        }
      } else {
        setState(() {
          _isNetIng = false;
        });
        ToastUtil.showToast(bean?.data?.error ?? '');
      }
    });
  }

  Widget _buildCommentChildrenItem(int index) {
    String avatar;
    String nickname;
    String createdAt;
    String likeCount;
    bool isLike;
    String cid;
    String totalRevenue;
    String content;
    String uid;
    String commentName;
    if (_listData[index] is CommentListTopBean) {
      CommentListTopBean commentListTopBean = _listData[index];
      avatar = commentListTopBean?.user?.avatar ?? '';
      nickname = commentListTopBean?.user?.nickname ?? '';
      createdAt = commentListTopBean?.createdAt ?? '';
      likeCount = commentListTopBean?.likeCount ?? '0';
      isLike = commentListTopBean?.isLike == CommentListDataListBean.isLikeYes;
      cid = commentListTopBean?.cid ?? '';
      content = commentListTopBean?.content ?? '';
      uid = commentListTopBean?.uid;
      commentName = commentListTopBean?.user?.nickname ?? '';
      if (commentListTopBean != null) {
        if (commentListTopBean?.vestStatus ==
            VideoInfoResponse.vestStatusFinish) {
          /// 奖励完成
          double totalRevenueVest = NumUtil.divide(
            NumUtil.getDoubleByValueStr(commentListTopBean?.vest ?? ''),
            RevenueCalculationUtil.cosUnit,
          );
          double money = RevenueCalculationUtil.vestToRevenue(
              totalRevenueVest, widget._bean.exchangeRateInfoData);
          totalRevenue = Common.formatDecimalDigit(money, 2);
        } else {
          /// 奖励未完成
          double settlementBonusVest =
              RevenueCalculationUtil.getReplyVestByPower(
                  commentListTopBean?.votepower,
                  widget._bean.chainStateBean?.dgpo);
          double money = (RevenueCalculationUtil.vestToRevenue(
              settlementBonusVest, widget._bean.exchangeRateInfoData));
          totalRevenue = Common.formatDecimalDigit(money, 2);
        }
      }
    } else if (_listData[index] is CommentListDataListBean) {
      CommentListDataListBean commentListDataListBean = _listData[index];
      avatar = commentListDataListBean?.user?.avatar ?? '';
      nickname = commentListDataListBean?.user?.nickname ?? '';
      createdAt = commentListDataListBean?.createdAt ?? '';
      likeCount = commentListDataListBean?.likeCount ?? '0';
      isLike =
          commentListDataListBean?.isLike == CommentListDataListBean.isLikeYes;
      cid = commentListDataListBean?.cid ?? '';
      content = commentListDataListBean?.content ?? '';
      uid = commentListDataListBean?.uid;
      commentName = commentListDataListBean?.user?.nickname ?? '';
      if (commentListDataListBean != null) {
        if (commentListDataListBean?.vestStatus ==
            VideoInfoResponse.vestStatusFinish) {
          /// 奖励完成
          double totalRevenueVest = NumUtil.divide(
            NumUtil.getDoubleByValueStr(commentListDataListBean?.vest ?? ''),
            RevenueCalculationUtil.cosUnit,
          );
          double money = RevenueCalculationUtil.vestToRevenue(
              totalRevenueVest, widget._bean.exchangeRateInfoData);
          totalRevenue = Common.formatDecimalDigit(money, 2);
        } else {
          /// 奖励未完成
          double settlementBonusVest =
              RevenueCalculationUtil.getReplyVestByPower(
                  commentListDataListBean?.votepower,
                  widget._bean.chainStateBean?.dgpo);
          double money = (RevenueCalculationUtil.vestToRevenue(
              settlementBonusVest, widget._bean.exchangeRateInfoData));
          print("money is $money");
          totalRevenue = Common.formatDecimalDigit(money, 2);
        }
      }
    } else {
      CommentChildrenDataListBean childrenDataListBean = _listData[index];
      avatar = childrenDataListBean?.user?.avatar ?? '';
      nickname = childrenDataListBean?.user?.nickname ?? '';
      createdAt = childrenDataListBean?.createdAt ?? '';
      likeCount = childrenDataListBean?.likeCount ?? '0';
      isLike =
          childrenDataListBean?.isLike == CommentListDataListBean.isLikeYes;
      cid = childrenDataListBean?.cid ?? '';
      content = childrenDataListBean?.content ?? '';
      uid = childrenDataListBean?.uid;
      commentName = childrenDataListBean?.user?.nickname ?? '';
      if (childrenDataListBean != null && childrenDataListBean != null) {
        if (childrenDataListBean?.vestStatus ==
            VideoInfoResponse.vestStatusFinish) {
          /// 奖励完成
          double totalRevenueVest = NumUtil.divide(
            NumUtil.getDoubleByValueStr(childrenDataListBean?.vest ?? ''),
            RevenueCalculationUtil.cosUnit,
          );
          double money = RevenueCalculationUtil.vestToRevenue(
              totalRevenueVest, widget._bean.exchangeRateInfoData);
          totalRevenue = Common.formatDecimalDigit(money, 2);
        } else {
          /// 奖励未完成
          double settlementBonusVest =
              RevenueCalculationUtil.getReplyVestByPower(
                  childrenDataListBean?.votepower,
                  widget._bean.chainStateBean?.dgpo);
          double money = (RevenueCalculationUtil.vestToRevenue(
              settlementBonusVest, widget._bean.exchangeRateInfoData));
          print("money is $money");
          totalRevenue = Common.formatDecimalDigit(money, 2);
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Offstage(
          offstage: index == 0,
          child: Container(
            margin: EdgeInsets.only(top: AppDimens.margin_15),
            height: AppDimens.item_line_height_0_5,
            color: AppColors.color_e4e4e4,
          ),
        ),
        Offstage(
          offstage: index != 1,
          child: Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_15,
              top: AppDimens.margin_9_5,
              right: AppDimens.margin_15,
            ),
            child: Text(
              InternationalLocalizations.videoCommentReplyAll,
              style: AppStyles.text_style_333333_12,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(
              left: AppDimens.margin_15,
              top: AppDimens.margin_15,
              right: AppDimens.margin_15),
          child: Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: AppColors.color_ffffff,
                radius: AppDimens.item_size_15,
                backgroundImage:
                    AssetImage('assets/images/ic_default_avatar.png'),
              ),
              CircleAvatar(
                backgroundColor: AppColors.color_transparent,
                radius: AppDimens.item_size_15,
                backgroundImage: CachedNetworkImageProvider(
                  avatar,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: AppDimens.margin_37_5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            LimitedBox(
                              maxWidth: AppDimens.item_size_100,
                              child: Text(
                                nickname,
                                style: AppStyles.text_style_333333_12,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              margin:
                                  EdgeInsets.only(left: AppDimens.margin_10),
                              child: Text(
                                Common.calcDiffTimeByStartTime(createdAt),
                                style: AppStyles.text_style_a0a0a0_12,
                              ),
                            ),
                            Container(
                              margin:
                                  EdgeInsets.only(left: AppDimens.margin_10),
                              child: VideoAddMoneyWidget(
                                key: _getAddMoneyViewKeyFromSymbol(cid),
                                baseWidget: Text(
                                  '${Common.getCurrencySymbolByLanguage()} ${totalRevenue ?? ''}',
                                  style: AppStyles.text_style_333333_bold_12,
                                ),
                                textStyle: AppStyles.text_style_333333_bold_12,
                                translateY: -20,
                              ),
                            )
                          ],
                        ),
                        InkWell(
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Text(
                                likeCount,
                                style: AppStyles.text_style_a0a0a0_14,
                              ),
                              Container(
                                margin:
                                    EdgeInsets.only(left: AppDimens.margin_5),
                                child: isLike
                                    ? Image.asset(
                                        'assets/images/ic_comment_like_yes.png')
                                    : Image.asset(
                                        'assets/images/ic_comment_like_no.png'),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (widget._bean.vestStatus !=
                                VideoInfoResponse.vestStatusFinish) {
                              _checkAbleCommentLike(isLike, cid, index);
                            } else {
                              ToastUtil.showToast(InternationalLocalizations
                                  .videoLinkFinishHint);
                            }
                          },
                        )
                      ],
                    ),
                    InkWell(
                      child: Container(
                        margin: EdgeInsets.only(top: AppDimens.margin_5),
                        child: Html(
                          data: content,
                          defaultTextStyle: AppStyles.text_style_333333_14,
                          onLinkTap: (url) {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) {
                              return WebViewPage(
                                '${Constant.otherUserCenterWebViewUrl}$uid',
                              );
                            }));
                          },
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _commentName = commentName;
                          _uid = uid;
                        });
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.color_transparent,
      body: Container(
        margin: EdgeInsets.only(top: AppDimens.margin_211),
        color: AppColors.color_ffffff,
        child: LoadingView(
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(
                    left: AppDimens.margin_10,
                    top: AppDimens.margin_5,
                    bottom: AppDimens.margin_5),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${_commentTotal ?? '0'}${InternationalLocalizations.videoCommentReplyCount}',
                      style: AppStyles.text_style_333333_15,
                    ),
                    Material(
                      color: AppColors.color_transparent,
                      child: Ink(
                        child: InkWell(
                          child: Container(
                            padding: EdgeInsets.all(AppDimens.margin_10),
                            child: Image.asset(
                                'assets/images/ic_close_black.png'),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                height: AppDimens.item_line_height_0_5,
                color: AppColors.color_e4e4e4,
              ),
              Expanded(
                child: RefreshAndLoadMoreListView(
                  itemBuilder: (context, index) {
                    return _buildCommentChildrenItem(index);
                  },
                  itemCount: _listData == null || _listData.isEmpty
                      ? 0
                      : _listData.length,
                  onLoadMore: () {
                    _httpVideoCommentChildrenList(true);
                    return;
                  },
                  pageSize: pageSize,
                  isHaveMoreData: _isHaveMoreData,
                  isRefreshEnable: false,
                  isShowItemLine: false,
                  hasTopPadding: false,
                  bottomMessage:
                  InternationalLocalizations.videoNoMoreComment,
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                    left: AppDimens.margin_15,
                    top: AppDimens.margin_6_5,
                    right: AppDimens.margin_15,
                    bottom: AppDimens.margin_6_5),
                height: AppDimens.item_size_45,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: AppDimens.margin_5),
                        height: AppDimens.item_size_32,
                        child: TextField(
                          onChanged: (str) {
                            if (str != null && str.trim().isNotEmpty) {
                              if (!_isAbleSendMsg) {
                                setState(() {
                                  _isAbleSendMsg = true;
                                });
                              }
                            } else {
                              if (_isAbleSendMsg) {
                                setState(() {
                                  _isAbleSendMsg = false;
                                });
                              }
                            }
                          },
                          controller: _textController,
                          style: AppStyles.text_style_333333_12,
                          decoration: InputDecoration(
                            fillColor: AppColors.color_ebebeb,
                            filled: true,
                            hintStyle: AppStyles.text_style_a0a0a0_12,
                            hintText:
                            '${InternationalLocalizations.videoCommentReply} @$_commentName：',
                            contentPadding: EdgeInsets.only(
                                left: AppDimens.margin_10,
                                top: AppDimens.margin_12),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: AppColors.color_transparent),
                              borderRadius:
                              BorderRadius.circular(AppDimens.radius_size_21),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: AppColors.color_3674ff),
                              borderRadius:
                              BorderRadius.circular(AppDimens.radius_size_21),
                            ),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (Common.isAbleClick()) {
                          _checkAbleVideoComment();
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
          isShow: _isNetIng,
        ),
      ),
    );
  }

  Decimal _getUserMaxPower() {
    return Common.getUserMaxPower(_cosInfoBean);
  }

  void _addVoterPowerToComment(CommentChildrenDataListBean bean) {
    if (bean != null) {
      Decimal val = Decimal.parse(bean.votepower);
      val += _getUserMaxPower();
      bean.votepower = val.toStringAsFixed(0);
    }
  }

  String _getAddedWorth() {
    return Common.getAddedWorth(widget._bean.cosInfoBean,
        widget._bean.exchangeRateInfoData, widget._bean.chainStateBean, false);
  }

  GlobalObjectKey<VideoAddMoneyWidgetState> _getAddMoneyViewKeyFromSymbol(
      String symbol) {
    if (!Common.checkIsNotEmptyStr(symbol)) {
      return GlobalObjectKey<VideoAddMoneyWidgetState>("default");
    }
    return GlobalObjectKey<VideoAddMoneyWidgetState>(symbol);
  }
}
