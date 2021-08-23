import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:common_utils/common_utils.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/bean/account_get_info_bean.dart';
import 'package:costv_android/bean/comment_children_list_bean.dart';
import 'package:costv_android/bean/comment_children_list_item_bean.dart';
import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/bean/exclusive_relation_bean.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/bean/simple_proxy_bean.dart';
import 'package:costv_android/bean/video_comment_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/emoji/emoji_picker.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/video_comment_children_list_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/comment/bean/comment_children_list_item_parameter_bean.dart';
import 'package:costv_android/pages/comment/bean/open_comment_children_parameter_bean.dart';
import 'package:costv_android/pages/comment/widget/comment_list_children_item.dart';
import 'package:costv_android/pages/video/dialog/video_comment_delete_dialog.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_sdk_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:costv_android/utils/web_view_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/loading_view.dart';
import 'package:costv_android/widget/refresh_and_loadmore_listview.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

typedef OnCloseListener();
typedef OnInputFaceChangeListener(bool isInputFace);

class VideoCommentChildrenListWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState> _dialogSKey;
  final GlobalKey<ScaffoldState> _pageKey;
  final OpenCommentChildrenParameterBean _bean;
  final OnCloseListener _onCloseListener;
  final OnInputFaceChangeListener _onInputFaceChangeListener;
  final ExclusiveRelationItemBean _exclusiveRelationItemBean;

  VideoCommentChildrenListWidget(
      this._dialogSKey,
      this._pageKey,
      this._bean,
      this._onCloseListener,
      this._onInputFaceChangeListener,
      this._exclusiveRelationItemBean) {
    assert(_dialogSKey != null ||
        _pageKey != null ||
        _bean != null ||
        _onCloseListener != null ||
        _onInputFaceChangeListener != null);
  }

  @override
  _VideoCommentChildrenListWidgetState createState() =>
      _VideoCommentChildrenListWidgetState();
}

class _VideoCommentChildrenListWidgetState
    extends State<VideoCommentChildrenListWidget> {
  static const String tag = '_VideoCommentChildrenListWidgetState';
  static const int pageSize = 10;
  static const int commentMaxLength = 300;
  AccountInfo _cosInfoBean;
  bool _isNetIng = false;
  int _page = 1;
  bool _isHaveMoreData = true;
  List<dynamic> _listData = [];
  int _commentTotal = 0;
  bool _isAbleSendMsg = false;
  TextEditingController _textController;
  FocusNode _focusNode = FocusNode();
  String _commentName;
  String _commentId;
  String _uid;
  VideoCommentDeleteDialog _videoCommentDeleteDialog;
  bool _isShowCommentLength = false;
  int _superfluousLength;
  bool _isInputFace = false;
  Category _selectCategory;
  StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _cosInfoBean = widget._bean.cosInfoBean;
    _httpVideoCommentChildrenList(false);
    _commentName = widget?._bean?.commentListItemBean?.user?.nickname ?? '';
    _commentId = widget?._bean?.commentListItemBean?.cid ?? '';
    _uid = widget?._bean?.commentListItemBean?.uid;
    _listenEvent();
  }

  @override
  void dispose() {
    super.dispose();
    _cancelListenEvent();
    if (_focusNode != null) {
      _focusNode.dispose();
      _focusNode = null;
    }
  }

  ///监听消息
  void _listenEvent() {
    if (_streamSubscription == null) {
      _streamSubscription = EventBusHelp.getInstance().on().listen((event) {
        if (event != null && event is VideoCommentChildrenListEvent) {
          if (event.type == VideoCommentChildrenListEvent.typeCloseInputFace &&
              _isInputFace) {
            setState(() {
              _isInputFace = false;
            });
          }
        }
      });
    }
  }

  ///取消监听消息事件
  void _cancelListenEvent() {
    if (_streamSubscription != null) {
      _streamSubscription.cancel();
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
            _listData.add(widget._bean.commentListItemBean);
          }
          _listData.addAll(bean.data.list);
          if (bean.data.hasNext == GetVideoListNewDataBean.hasNextYes) {
            _isHaveMoreData = true;
            _page++;
          } else {
            _isHaveMoreData = false;
          }
          if (!ObjectUtil.isEmptyString(bean.data.total.trim())) {
            _commentTotal = int.parse(bean.data.total.trim());
          } else {
            _commentTotal = 0;
          }
        } else {
          if (!isLoadMore) {
            _listData.add(widget._bean.commentListItemBean);
          }
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
          if (_listData[index] is CommentListItemBean) {
            CommentListItemBean commentListItemBean = _listData[index];
            commentListItemBean?.isLike = '1';
            if (!TextUtil.isEmpty(commentListItemBean?.likeCount)) {
              commentListItemBean?.likeCount =
                  (int.parse(commentListItemBean?.likeCount) + 1).toString();
            }
            String addVal = Common.calcCommentAddedIncome(
                _cosInfoBean,
                widget._bean.exchangeRateInfoData,
                widget._bean.chainStateBean,
                commentListItemBean.votepower);
            if (Common.checkIsNotEmptyStr(addVal)) {
              var key = Common.getAddMoneyViewKeyFromSymbol(
                  "$cid + ${index.toString}");
              if (key != null && key.currentState != null) {
                key.currentState.startShowWithAni(addVal);
              }
            }
            _addVoterPowerToComment(commentListItemBean);
          } else if (_listData[index] is CommentChildrenListItemBean) {
            CommentChildrenListItemBean commentChildrenListItemBean =
                _listData[index];
            commentChildrenListItemBean?.isLike = '1';
            if (!TextUtil.isEmpty(commentChildrenListItemBean?.likeCount)) {
              commentChildrenListItemBean?.likeCount =
                  (int.parse(commentChildrenListItemBean?.likeCount) + 1)
                      .toString();
            }
            String addVal = Common.calcCommentAddedIncome(
                _cosInfoBean,
                widget._bean.exchangeRateInfoData,
                widget._bean.chainStateBean,
                commentChildrenListItemBean.votePower);
            if (Common.checkIsNotEmptyStr(addVal)) {
              var key = Common.getAddMoneyViewKeyFromSymbol(
                  "$cid + ${index.toString}");
              if (key != null && key.currentState != null) {
                key.currentState.startShowWithAni(addVal);
              }
            }
            _addVoterPowerToCommentChildren(commentChildrenListItemBean);
          }
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
      if (Platform.isAndroid) {
        WebViewUtil.instance
            .openWebViewResult(Constant.logInWebViewUrl)
            .then((isSuccess) {
          if (isSuccess != null && isSuccess) {
            _checkAbleCommentLike(isLike, cid, index);
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
          }
        });
      }
    }
  }

  void _checkAbleVideoComment() {
    if (!ObjectUtil.isEmptyString(Constant.accountName)) {
      if (_isAbleSendMsg) {
        String content = Constant.commentSendHtml(
            _uid, _commentName, _textController.text.trim());
        if (_isInputFace) {
          _isInputFace = false;
          if (widget._onInputFaceChangeListener != null) {
            widget._onInputFaceChangeListener(_isInputFace);
          }
          _selectCategory = null;
        } else {
          FocusScope.of(context).requestFocus(FocusNode());
        }
        _httpVideoComment(Constant.accountName, _commentId, content);
      }
    } else {
      if (Platform.isAndroid) {
        WebViewUtil.instance
            .openWebViewResult(Constant.logInWebViewUrl)
            .then((isSuccess) {
          if (isSuccess != null && isSuccess) {
            _checkAbleVideoComment();
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
            _checkAbleVideoComment();
          }
        });
      }
    }
  }

  CommentChildrenListItemBean _buildCommentChildrenBean(
      String commentId, String content) {
    String pid = widget?._bean?.pid ?? '';
    String vid = widget?._bean?.vid ?? '';
    String uid = widget?._bean?.uid ?? '';
    String creatorUid = widget?._bean?.creatorUid ?? '';
    String timestamp =
        (Decimal.parse(DateTime.now().millisecondsSinceEpoch.toString()) /
                Decimal.parse('1000'))
            .toString();
    String nickName = Constant?.accountGetInfoDataBean?.nickname ?? '';
    String avatar = Constant?.accountGetInfoDataBean?.avatar ?? '';
    String isCreator = CommentListItemBean.isCreatorNo;
    if (Constant.uid == creatorUid) {
      isCreator = CommentListItemBean.isCreatorYes;
    }
    String isCertification = widget?._bean?.isCertification ?? '';
    CommentChildrenListItemBean commentChildrenDataListBean =
        new CommentChildrenListItemBean(
      '',
      vid,
      pid,
      content,
      uid,
      '',
      '',
      '',
      timestamp,
      timestamp,
      '',
      '',
      '',
      '0',
      '0',
      new CommentChildrenUserBean(nickName, avatar, '', isCertification,
          Constant?.accountGetInfoDataBean?.imageCompress),
      commentId,
      '',
      '',
      '0',
      '0',
      '0',
      isCreator,
      "0",
    );
    commentChildrenDataListBean.isShowInsertColor = true;
    commentChildrenDataListBean.isShowDeleteComment = false;
    return commentChildrenDataListBean;
  }

  void refreshCommentTop(String replyId, String content) {
    CommentChildrenListItemBean commentChildrenListItemBean =
        _buildCommentChildrenBean(replyId, content);
    _listData.insert(1, commentChildrenListItemBean);
    _commentTotal++;
    widget._bean.changeCommentTotal = _commentTotal;
    Future.delayed(Duration(milliseconds: 1500), () {
      setState(() {
        commentChildrenListItemBean.isShowInsertColor = false;
      });
    });
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
        _isNetIng = false;
      });
    });
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
      VideoCommentBean bean =
          VideoCommentBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleProxyResponse.statusStrSuccess &&
          bean.data != null) {
        if (bean.data.ret == SimpleProxyResponse.responseSuccess) {
          if (Constant.accountGetInfoDataBean == null) {
            _httpUserInfo(bean.data?.replyid ?? '', content);
          } else {
            refreshCommentTop(bean.data?.replyid ?? '', content);
            setState(() {
              _isNetIng = false;
            });
          }
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

  void clearCommentInput() {
    _textController.text = '';
    _isAbleSendMsg = false;
    //评论成功上报
    DataReportUtil.instance.reportData(
        eventName: "Comments",
        params: {"Comments": "1", "is_comment_videopage": "1"});
  }

  @override
  Widget build(BuildContext context) {
    double inputHeight;
    double marginBottom;
    if (!_isShowCommentLength) {
      inputHeight = AppDimens.item_size_32;
      marginBottom = AppDimens.item_size_45;
    } else {
      marginBottom = AppDimens.item_size_100;
    }
    String imgInput;
    if (_isInputFace) {
      imgInput = AppThemeUtil.getCommentInputText();
    } else {
      imgInput = AppThemeUtil.getCommentInputEmoji();
    }
    return Expanded(
        child: WillPopScope(
      child: LoadingView(
        child: Container(
          color: AppThemeUtil.setDifferentModeColor(
            lightColor: AppColors.color_ffffff,
            darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(bottom: marginBottom),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(
                          left: AppDimens.margin_15,
                          top: AppDimens.margin_5,
                          bottom: AppDimens.margin_5),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            InternationalLocalizations.videoCommentReply,
                            style: TextStyle(
                              color: AppThemeUtil.setDifferentModeColor(
                                lightColor: AppColors.color_333333,
                                darkColorStr: DarkModelTextColorUtil
                                    .firstLevelBrightnessColorStr,
                              ),
                              fontSize: AppDimens.text_size_14,
                            ),
                          ),
                          Material(
                            color: AppColors.color_transparent,
                            child: Ink(
                              child: InkWell(
                                child: Container(
                                  padding: EdgeInsets.all(AppDimens.margin_10),
                                  child: Image.asset(_getCloseIcnPath()),
                                ),
                                onTap: () {
                                  if (widget._onCloseListener != null) {
                                    widget._onCloseListener();
                                  }
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                        height: AppDimens.item_line_height_0_5,
                        color: AppThemeUtil.setDifferentModeColor(
                            lightColor: AppColors.color_e4e4e4,
                            darkColorStr: "3E3E3E")),
                    Expanded(
                      child: RefreshAndLoadMoreListView(
                        itemBuilder: (context, index) {
                          CommentChildrenListItemParameterBean bean =
                              CommentChildrenListItemParameterBean();
                          bean.showType = CommentChildrenListItemParameterBean
                              .showTypeVideoComment;
                          bean.commentChildrenListItemBean = _listData[index];
                          bean.exchangeRateInfoData =
                              widget._bean?.exchangeRateInfoData;
                          bean.chainStateBean = widget._bean?.chainStateBean;
                          bean.creatorUid = widget._bean?.creatorUid ?? '';
                          bean.index = index;
                          bean.vestStatus = widget._bean?.vestStatus ?? '';
                          return CommentListChildrenItem(bean,
                              (clickCommentChildrenItemBean) {
                            if (widget._bean.vestStatus !=
                                VideoInfoResponse.vestStatusFinish) {
                              _checkAbleCommentLike(
                                  clickCommentChildrenItemBean.isLike ?? '',
                                  clickCommentChildrenItemBean.cid ?? '',
                                  clickCommentChildrenItemBean.index);
                            } else {
                              ToastUtil.showToast(InternationalLocalizations
                                  .videoLinkFinishHint);
                            }
                          }, (clickCommentChildrenItemBean) {
                            setState(() {
                              _commentName =
                                  clickCommentChildrenItemBean.commentName;
                              _uid = clickCommentChildrenItemBean.uid;
                            });
                            _focusNode.unfocus();
                            FocusScope.of(context).requestFocus(_focusNode);
                          }, (clickCommentChildrenItemBean) {
                            if (_videoCommentDeleteDialog == null) {
                              _videoCommentDeleteDialog =
                                  VideoCommentDeleteDialog(
                                      tag, widget._pageKey, widget._dialogSKey);
                            }
                            _videoCommentDeleteDialog.initData(
                                clickCommentChildrenItemBean.id ?? '',
                                clickCommentChildrenItemBean.vid ?? '',
                                widget._bean?.creatorUid ?? '', () {
                              if (index != null &&
                                  _listData != null &&
                                  index < _listData.length) {
                                setState(() {
                                  _listData.removeAt(index);
                                  _commentTotal--;
                                  widget._bean.changeCommentTotal =
                                      _commentTotal;
                                });
                              }
                            },
                                handleDeleteCallBack:
                                    (isProcessing, isSuccess) {});
                            _videoCommentDeleteDialog
                                .showVideoCommentDeleteDialog();
                          });
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
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(
                        vertical: AppDimens.margin_6_5,
                        horizontal: AppDimens.margin_15),
                    color: AppThemeUtil.setDifferentModeColor(
                      lightColor: AppColors.color_ffffff,
                      darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
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
                                  darkColorStr: DarkModelTextColorUtil
                                      .firstLevelBrightnessColorStr,
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
                                    darkColorStr: DarkModelTextColorUtil
                                        .firstLevelBrightnessColorStr,
                                  ),
                                  fontSize: AppDimens.text_size_12,
                                ),
                                hintText:
                                    '${InternationalLocalizations.videoCommentReply} @$_commentName：',
                                contentPadding: EdgeInsets.only(
                                    left: AppDimens.margin_10,
                                    top: AppDimens.margin_12),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.color_transparent),
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radius_size_15),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: AppColors.color_3674ff),
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radius_size_15),
                                ),
                              ),
                              autofocus: widget._bean?.isReply ?? false,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (Common.isAbleClick()) {
                              setState(() {
                                _isInputFace = !_isInputFace;
                                if (widget._onInputFaceChangeListener != null) {
                                  widget
                                      ._onInputFaceChangeListener(_isInputFace);
                                }
                                _selectCategory = null;
                                if (!_isInputFace) {
                                  FocusScope.of(context)
                                      .requestFocus(_focusNode);
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
                                  margin: EdgeInsets.only(
                                      right: AppDimens.margin_5),
                                  child: Text(
                                    '$_superfluousLength',
                                    style: AppStyles.text_style_c20a0a_12,
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
                                    InternationalLocalizations
                                        .videoCommentSendMessage,
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
                          epamoji:
                              Image.asset('assets/images/ic_face_voepa.png')),
                      level: widget._exclusiveRelationItemBean?.level ??
                          ExclusiveRelationItemBean.levelLock,
                      selectedCategory: _selectCategory,
                      onEmojiSelected: (emoji, category) {
                        CosLogUtil.log('$tag $category $emoji');
                        _textController.text =
                            _textController.text + emoji.emoji;
                        commentChange(_textController.text);
                      },
                      onSelectCategoryChange: (selectedCategory) {
                        _selectCategory = selectedCategory;
                      },
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        isShow: _isNetIng,
      ),
      onWillPop: () async {
        if (widget._onCloseListener != null) {
          widget._onCloseListener();
        }
        return false;
      },
    ));
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

  Decimal _getUserMaxPower() {
    return Common.getUserMaxPower(_cosInfoBean);
  }

  String _getCloseIcnPath() {
    if (AppThemeUtil.checkIsDarkMode()) {
      return "assets/images/dark_icn_search_close.png";
    }
    return "assets/images/ic_close_black.png";
  }

  void _addVoterPowerToComment(CommentListItemBean bean) {
    if (bean != null) {
      Decimal val = Decimal.parse(bean.votepower);
      val += _getUserMaxPower();
      bean.votepower = val.toStringAsFixed(0);
    }
  }

  void _addVoterPowerToCommentChildren(CommentChildrenListItemBean bean) {
    if (bean != null) {
      Decimal val = Decimal.parse(bean.votePower);
      val += _getUserMaxPower();
      bean.votePower = val.toStringAsFixed(0);
    }
  }
}
