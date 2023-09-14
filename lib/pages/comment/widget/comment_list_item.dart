import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/comment/bean/comment_children_parameter_bean.dart';
import 'package:costv_android/pages/comment/bean/comment_list_item_parameter_bean.dart';
import 'package:costv_android/pages/comment/widget/comment_rich_text_widget.dart';
import 'package:costv_android/pages/user/others_home_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/revenue_calculation_util.dart';
import 'package:costv_android/utils/user_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/bottom_progress_indicator.dart';
import 'package:costv_android/widget/no_more_data_widget.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widget/animation/video_add_money_widget.dart';

typedef ClickCommentLike(CommentListItemBean bean, int index);
typedef ClickCommentReply(CommentListItemBean bean, int index);
typedef ClickChildrenWindows(CommentListItemBean bean, int index, bool isOpenKeyboard);
typedef ClickCommentDelete(CommentListItemBean bean);
typedef ClickCommentChildren(CommentChildrenParameterBean bean);
typedef ClickLoadMoreComment();
typedef ClickCommentFold();

class CommentListItem extends StatefulWidget {
  final CommentListItemParameterBean bean;
  final ClickCommentLike? clickCommentLike;
  final ClickCommentReply? clickCommentReply;
  final ClickChildrenWindows? clickChildrenWindows;
  final ClickCommentDelete? clickCommentDelete;
  final ClickCommentChildren? clickCommentChildren;
  final ClickLoadMoreComment? clickLoadMoreComment;
  final ClickCommentFold? clickCommentFold;
  final String? darkModeBgColorStr;

  CommentListItem({
    required this.bean,
    this.clickCommentLike,
    this.clickCommentReply,
    this.clickChildrenWindows,
    this.clickCommentDelete,
    this.clickCommentChildren,
    this.clickLoadMoreComment,
    this.clickCommentFold,
    this.darkModeBgColorStr,
  });

  @override
  State<StatefulWidget> createState() {
    return _CommentListItemState();
  }
}

class _CommentListItemState extends State<CommentListItem> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildCommentChildrenItem(BuildContext context, CommentChildrenParameterBean bean) {
    String contentUid = UserUtil.getContentUid(bean.content);
    String contentNickName = UserUtil.getContentNickName(bean.content);
    String replay = UserUtil.getContentReply(bean.content);
    return InkWell(
      child: Container(
        width: MediaQuery
            .of(context)
            .size
            .width - AppDimens.margin_20,
        color: bean.isShowInsertColor
            ? AppColors.color_eff5ff
            : AppThemeUtil.setDifferentModeColor(
          lightColor: AppColors.color_transparent,
          darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
        ),
        padding: EdgeInsets.only(
          left: AppDimens.margin_10,
          top: AppDimens.margin_5,
          right: AppDimens.margin_10,
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              bean.commentName,
              style: AppStyles.text_style_333333_14,
            ),
            Offstage(
              offstage: !(bean.isCreator == CommentListItemBean.isCreatorYes),
              child: Container(
                margin: EdgeInsets.only(
                  left: AppDimens.margin_3,
                  right: AppDimens.margin_3,
                ),
                padding: EdgeInsets.only(
                  left: AppDimens.margin_3,
                  right: AppDimens.margin_3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.color_transparent,
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppDimens.radius_size_4),
                  ),
                  border: Border.all(color: AppColors.color_3674ff, width: AppDimens.item_line_height_1),
                ),
                child: Text(
                  InternationalLocalizations.videoCreator,
                  style: AppStyles.text_style_3674ff_8,
                ),
              ),
            ),
            Container(
              child: Linkify(
                  text: " :http://@$contentNickName",
                  onOpen: (link) async {
                    String urlStr = link.url;
                    int idx = urlStr.indexOf("http://");
                    if (idx >= 0) {
                      urlStr = urlStr.substring(idx);
                    }
                    if (!TextUtil.isEmpty(urlStr)) {
                      Navigator.of(context).push(SlideAnimationRoute(
                        builder: (_) {
                          return OthersHomePage(
                            OtherHomeParamsBean(
                              uid: contentUid,
                              avatar: bean.avatar,
                              nickName: contentNickName,
                              isCertification: bean.isCertification,
                              rateInfoData: widget.bean.exchangeRateInfoData,
                              dgpoBean: widget.bean.chainStateBean?.dgpo,
                            ),
                          );
                        },
                      ));
                    }
                  }),
            ),
            Text(
              replay,
              style: AppStyles.text_style_333333_14,
            ),
          ],
        ),
      ),
      onTap: () {
        if (widget.clickCommentChildren != null && Common.isAbleClick()) {
          widget.clickCommentChildren?.call(bean);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String totalRevenue = "";
    if (widget.bean.commentListItemBean.vestStatus == VideoInfoResponse.vestStatusFinish) {
      /// 奖励完成
      double totalRevenueVest = NumUtil.divide(
        NumUtil.getDoubleByValueStr(widget.bean.commentListItemBean.vest) as num,
        RevenueCalculationUtil.cosUnit,
      );
      double money = RevenueCalculationUtil.vestToRevenue(totalRevenueVest, widget.bean.exchangeRateInfoData);
      totalRevenue = Common.formatDecimalDigit(money, 2);
    } else {
      /// 奖励未完成
      double settlementBonusVest =
      RevenueCalculationUtil.getReplyVestByPower(widget.bean.commentListItemBean.votepower, widget.bean.chainStateBean?.dgpo);
      double money = (RevenueCalculationUtil.vestToRevenue(settlementBonusVest, widget.bean.exchangeRateInfoData));
      totalRevenue = Common.formatDecimalDigit(money, 2);
    }
    int commentTotal = 0;
    if (!TextUtil.isEmpty(widget.bean.total)) {
      commentTotal = int.parse(widget.bean.total);
    }
    int commentLength = widget.bean.commentLength;
    int childrenCount = 0;
    if (!TextUtil.isEmpty(widget.bean.commentListItemBean.childrenCount)) {
      childrenCount = int.parse(widget.bean.commentListItemBean.childrenCount);
    }
    int newSendChildrenCount = widget.bean.commentListItemBean.children?.length ?? 0;
    int childrenTotalLength = childrenCount + newSendChildrenCount;
    String seeMore = InternationalLocalizations.lookComment;
    if (childrenTotalLength > 1) {
      seeMore = '${InternationalLocalizations.viewReply(childrenTotalLength.toString())}';
    }
    String content = widget.bean.commentListItemBean.content;
    bool isShowInsertColor = widget.bean.commentListItemBean.isShowInsertColor;
    bool isShowDeleteComment = false;
    bool isShowTopColor = widget.bean.commentListItemBean.isShowTopColor ?? false;
    if (ObjectUtil.isNotEmpty(widget.bean.uid) &&
        ObjectUtil.isNotEmpty(Constant.uid) &&
        widget.bean.uid == Constant.uid &&
        (widget.bean.commentListItemBean.isShowDeleteComment)) {
      isShowDeleteComment = true;
    }
    String avatar = widget.bean.commentListItemBean.user.imageCompress?.avatarCompressUrl ?? "";
    if (ObjectUtil.isEmptyString(avatar)) {
      avatar = widget.bean.commentListItemBean.user.avatar;
    }
    String certificationStr = widget.bean.commentListItemBean.user.isCertification ?? "";
    bool isCertification = certificationStr == "1";
    String isHolidayCelebrationStr = widget.bean.commentListItemBean.isHolidayCelebration ?? "";
    bool isShowWomenDayIcn = isHolidayCelebrationStr == "1";
    int commentPage = widget.bean.commentPage;
    Color bgColor;
    if (isShowInsertColor) {
      bgColor = AppThemeUtil.setDifferentModeColor(
        lightColor: AppColors.color_eff5ff,
        darkColorStr: "333333 ",
      );
    } else {
      if (isShowTopColor) {
        bgColor = AppThemeUtil.setDifferentModeColor(
          lightColor: AppColors.color_eff5ff,
          darkColorStr: "3E3E3E",
        );
        Future.delayed(Duration(milliseconds: 1500), () {
          setState(() {
            widget.bean.commentListItemBean.isShowTopColor = false;
          });
        });
      } else {
        bgColor = AppThemeUtil.setDifferentModeColor(
          lightColor: AppColors.color_ffffff,
          darkColorStr: widget.darkModeBgColorStr ?? DarkModelBgColorUtil.pageBgColorStr,
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          color: bgColor,
          padding: EdgeInsets.only(left: AppDimens.margin_15, top: AppDimens.margin_15, right: AppDimens.margin_15, bottom: AppDimens.margin_9),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InkWell(
                child: Container(
                  width: AppDimens.item_size_15 * 2 + AppDimens.margin_7_5,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.color_ebebeb, width: AppDimens.item_line_height_0_5),
                          borderRadius: BorderRadius.circular(AppDimens.item_size_15),
                        ),
                        child: Stack(
                          children: <Widget>[
                            CircleAvatar(
                              backgroundColor: AppColors.color_ffffff,
                              radius: AppDimens.item_size_15,
                              backgroundImage: AssetImage('assets/images/ic_default_avatar.png'),
                            ),
                            CircleAvatar(
                              backgroundColor: AppColors.color_transparent,
                              radius: AppDimens.item_size_15,
                              backgroundImage: CachedNetworkImageProvider(
                                avatar,
                              ),
                            ),
                          ],
                        ),
                      ),
                      //巴西活动图标
                      Positioned(
                        bottom: 0,
                        left: 20,
                        child: Offstage(
                          offstage: !isShowWomenDayIcn,
                          child: Container(
                            width: 14,
                            height: 14,
                            child: Image.asset(
                              "assets/images/icn_womens_day.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(SlideAnimationRoute(
                    builder: (_) {
                      return OthersHomePage(
                        OtherHomeParamsBean(
                          uid: widget.bean.commentListItemBean.uid,
                          avatar: avatar,
                          nickName: widget.bean.commentListItemBean.user.nickname,
                          isCertification: widget.bean.commentListItemBean.user.isCertification,
                          rateInfoData: widget.bean.exchangeRateInfoData,
                          dgpoBean: widget.bean.chainStateBean?.dgpo,
                        ),
                      );
                    },
                  ));
                },
              ),
              Expanded(
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Offstage(
                                offstage: !(widget.bean.commentListItemBean.isTopOne == CommentListItemBean.isTopOneYes),
                                child: Container(
                                  margin: EdgeInsets.only(right: AppDimens.margin_3),
                                  child: Image.asset('assets/images/ic_comment_first.png'),
                                ),
                              ),
                              InkWell(
                                child: LimitedBox(
                                  maxWidth: AppDimens.item_size_60,
                                  child: Text(
                                    widget.bean.commentListItemBean.user.nickname,
                                    style: TextStyle(
                                      color: AppThemeUtil.setDifferentModeColor(
                                        lightColor: AppColors.color_333333,
                                        darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                                      ),
                                      fontSize: AppDimens.text_size_12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(SlideAnimationRoute(
                                    builder: (_) {
                                      return OthersHomePage(
                                        OtherHomeParamsBean(
                                          uid: widget.bean.commentListItemBean.uid,
                                          avatar: avatar,
                                          nickName: widget.bean.commentListItemBean.user.nickname,
                                          isCertification: widget.bean.commentListItemBean.user.isCertification,
                                          rateInfoData: widget.bean.exchangeRateInfoData,
                                          dgpoBean: widget.bean.chainStateBean?.dgpo,
                                        ),
                                      );
                                    },
                                  ));
                                },
                              ),
                              //认证标识
                              Offstage(
                                offstage: !isCertification,
                                child: Container(
                                  margin: EdgeInsets.only(left: 4, right: 3),
                                  child: Image.asset(
                                    "assets/images/ic_comment_certification.png",
                                  ),
                                ),
                              ),
                              //创作者标识
                              Offstage(
                                offstage: !(widget.bean.commentListItemBean.isCreator == CommentListItemBean.isCreatorYes),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: AppDimens.margin_5,
                                    right: AppDimens.margin_3,
                                  ),
                                  padding: EdgeInsets.only(
                                    left: AppDimens.margin_3,
                                    right: AppDimens.margin_3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.color_transparent,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(AppDimens.radius_size_4),
                                    ),
                                    border: Border.all(color: AppColors.color_3674ff, width: AppDimens.item_line_height_1),
                                  ),
                                  child: Text(
                                    InternationalLocalizations.videoCreator,
                                    style: AppStyles.text_style_3674ff_8,
                                  ),
                                ),
                              ),
                              //礼物票特权
                              Offstage(
                                offstage: !(widget.bean.commentListItemBean.isSendTicket == CommentListItemBean.isSendTicketYes),
                                child: Container(
                                  margin: EdgeInsets.only(left: AppDimens.margin_2),
                                  child: Image.asset('assets/images/ic_comment_heart.png'),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            child: Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  AutoSizeText(
                                    widget.bean.commentListItemBean.likeCount ?? "",
                                    style: AppStyles.text_style_a0a0a0_14,
                                    minFontSize: 8,
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: AppDimens.margin_3),
                                    child: widget.bean.commentListItemBean.isLike == CommentListItemBean.isLikeYes
                                        ? Image.asset('assets/images/ic_comment_like_yes.png')
                                        : Image.asset(AppThemeUtil.getCommentNotLikedIcn()),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.only(bottom: 10, left: 10),
                            ),
                            onTap: () {
                              if (widget.clickCommentLike != null && Common.isAbleClick()) {
                                widget.clickCommentLike?.call(widget.bean.commentListItemBean, widget.bean.index);
                              }
                            },
                          )
                        ],
                      ),
                      InkWell(
                        child: Container(
                          margin: EdgeInsets.only(top: AppDimens.margin_5, right: AppDimens.margin_20),
                          child: CommentRichTextWidget(
                            content,
                            clickNameListener: (String uid, String name) {
                              if (!ObjectUtil.isEmptyString(uid)) {
                                Navigator.of(context).push(SlideAnimationRoute(
                                  builder: (_) {
                                    return OthersHomePage(
                                      OtherHomeParamsBean(
                                        uid: uid,
                                        avatar: '',
                                        nickName: name,
                                        isCertification: widget.bean.commentListItemBean.user.isCertification,
                                        rateInfoData: widget.bean.exchangeRateInfoData,
                                        dgpoBean: widget.bean.chainStateBean?.dgpo,
                                      ),
                                    );
                                  },
                                ));
                              }
                            },
                            clickHttpListener: (String url) async {
                              if (ObjectUtil.isNotEmpty(url) && await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              }
                            },
                          ),
                        ),
                        onTap: () {
                          if (widget.bean.showType == CommentListItemParameterBean.showTypeVideoComment) {
                            if (widget.clickChildrenWindows != null && Common.isAbleClick()) {
                              widget.clickChildrenWindows?.call(widget.bean.commentListItemBean, widget.bean.index, true);
                            }
                          } else {
                            if (widget.clickCommentReply != null && Common.isAbleClick()) {
                              widget.clickCommentReply?.call(widget.bean.commentListItemBean, widget.bean.index);
                            }
                          }
                        },
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              VideoAddMoneyWidget(
                                key: Common.getAddMoneyViewKeyFromSymbol(widget.bean.commentListItemBean.cid),
                                baseWidget: Text(
                                  '${Common.getCurrencySymbolByLanguage()} $totalRevenue',
                                  style: TextStyle(
                                    color: AppThemeUtil.setDifferentModeColor(
                                      lightColor: AppColors.color_333333,
                                      darkColorStr: "A0A0A0",
                                    ),
                                    fontSize: AppDimens.text_size_12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                textStyle: TextStyle(
                                  color: AppThemeUtil.setDifferentModeColor(
                                    lightColor: AppColors.color_333333,
                                    darkColorStr: "A0A0A0",
                                  ),
                                  fontSize: AppDimens.text_size_12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: AppDimens.margin_10),
                                child: Text(
                                  Common.calcDiffTimeByStartTime(widget.bean.commentListItemBean.createdAt),
                                  style: AppStyles.text_style_a0a0a0_12,
                                ),
                              ),
                              Material(
                                color: AppColors.color_transparent,
                                child: Ink(
                                  child: InkWell(
                                    child: Container(
                                      margin: EdgeInsets.only(left: AppDimens.margin_15),
                                      padding: EdgeInsets.all(AppDimens.margin_5),
                                      child: Text(
                                        InternationalLocalizations.videoCommentReply,
                                        style: TextStyle(
                                          color: AppThemeUtil.setDifferentModeColor(
                                            lightColor: AppColors.color_333333,
                                            darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                                          ),
                                          fontSize: AppDimens.text_size_12,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      if (widget.bean.showType == CommentListItemParameterBean.showTypeVideoComment) {
                                        if (widget.clickChildrenWindows != null && Common.isAbleClick()) {
                                          widget.clickChildrenWindows?.call(widget.bean.commentListItemBean, widget.bean.index, true);
                                        }
                                      } else {
                                        if (widget.clickCommentReply != null && Common.isAbleClick()) {
                                          widget.clickCommentReply?.call(widget.bean.commentListItemBean, widget.bean.index);
                                        }
                                      }
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                          Offstage(
                            offstage: !isShowDeleteComment,
                            child: Material(
                              color: AppColors.color_transparent,
                              child: Ink(
                                child: InkWell(
                                  child: Padding(
                                    padding: EdgeInsets.all(AppDimens.margin_5),
                                    child: Image.asset(AppThemeUtil.getCommentMoreIcn()),
                                  ),
                                  onTap: () {
                                    if (widget.clickCommentDelete != null && Common.isAbleClick()) {
                                      widget.clickCommentDelete?.call(widget.bean.commentListItemBean);
                                    }
                                  },
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      Offstage(
                        offstage: childrenTotalLength == 0,
                        child: InkWell(
                          child: Container(
                            child: AutoSizeText(
                              seeMore,
                              style: AppStyles.text_style_3674ff_bold_14,
                              textAlign: TextAlign.left,
                              minFontSize: 8,
                            ),
                          ),
                          onTap: () {
                            if (widget.clickChildrenWindows != null && Common.isAbleClick()) {
                              widget.clickChildrenWindows?.call(widget.bean.commentListItemBean, widget.bean.index, false);
                            }
                          },
                        ),
                      ),
                      Offstage(
                        offstage: newSendChildrenCount == 0,
                        child: Column(
                          children: List.generate(newSendChildrenCount, (int index) {
                            CommentChildrenParameterBean bean = CommentChildrenParameterBean();
                            bean.uid = widget.bean.commentListItemBean.children?[index].uid ?? "";
                            bean.content = widget.bean.commentListItemBean.children?[index].content ?? "";
                            bean.cid = widget.bean.commentListItemBean.cid;
                            bean.commentName = widget.bean.commentListItemBean.children?[index].user.nickname ?? "";
                            bean.avatar = avatar;
                            bean.isShowInsertColor = widget.bean.commentListItemBean.children?[index].isShowInsertColor ?? false;
                            bean.isCreator = widget.bean.commentListItemBean.children?[index].isCreator ?? "";
                            return _buildCommentChildrenItem(context, bean);
                          }),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Offstage(
          offstage: (widget.bean.showType == CommentListItemParameterBean.showTypeCommentList || widget.bean.isLoadMoreComment),
          child: Container(
            margin: EdgeInsets.only(left: AppDimens.margin_45),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Offstage(
                  offstage: (widget.bean.index != commentLength - 1 || commentTotal <= commentLength),
                  child: InkWell(
                    child: Container(
                      padding: EdgeInsets.all(AppDimens.margin_5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AutoSizeText(
                            InternationalLocalizations.videoClickMoreComment,
                            style: AppStyles.text_style_3674ff_14,
                            minFontSize: 8,
                          ),
                          Container(
                            margin: EdgeInsets.only(left: AppDimens.margin_3),
                            child: Image.asset('assets/images/ic_right_comment.png'),
                          )
                        ],
                      ),
                    ),
                    onTap: () {
                      if (widget.clickLoadMoreComment != null && Common.isAbleClick()) {
                        widget.clickLoadMoreComment?.call();
                      }
                    },
                  ),
                ),
                Offstage(
                  offstage: (widget.bean.index != commentLength - 1 || commentPage <= 2),
                  child: InkWell(
                    child: Container(
                      padding: EdgeInsets.all(AppDimens.margin_5),
                      child: AutoSizeText(
                        InternationalLocalizations.videoCommentFold,
                        style: AppStyles.text_style_3674ff_14,
                        minFontSize: 8,
                      ),
                    ),
                    onTap: () {
                      if (widget.clickCommentFold != null && Common.isAbleClick()) {
                        widget.clickCommentFold?.call();
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
        Offstage(
          offstage: (widget.bean.showType == CommentListItemParameterBean.showTypeCommentList ||
              !widget.bean.isLoadMoreComment ||
              widget.bean.index != widget.bean.commentLength - 1),
          child: Align(
            alignment: Alignment.center,
            child: BottomProgressIndicator(),
          ),
        ),
        Offstage(
          offstage: (widget.bean.showType == CommentListItemParameterBean.showTypeCommentList ||
              widget.bean.index != widget.bean.commentLength - 1 ||
              commentTotal > commentLength),
          child: NoMoreDataWidget(
            bottomMessage: InternationalLocalizations.videoNoMoreComment,
          ),
        ),
        Offstage(
          offstage: (widget.bean.showType == CommentListItemParameterBean.showTypeCommentList || widget.bean.commentLength != 0),
          child: Container(
            height: AppDimens.item_line_height_0_5,
            color: AppColors.color_ebebeb,
          ),
        )
      ],
    );
  }
}
