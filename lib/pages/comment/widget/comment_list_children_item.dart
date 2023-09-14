import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/comment_children_list_item_bean.dart';
import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/comment/bean/click_comment_children_item_bean.dart';
import 'package:costv_android/pages/comment/bean/comment_children_list_item_parameter_bean.dart';
import 'package:costv_android/pages/comment/widget/comment_rich_text_widget.dart';
import 'package:costv_android/pages/user/others_home_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/revenue_calculation_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/animation/video_add_money_widget.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ClickCommentChildrenLike(ClickCommentChildrenItemBean bean);
typedef ClickCommentChildrenReply(ClickCommentChildrenItemBean bean);
typedef ClickCommentChildrenDelete(ClickCommentChildrenItemBean bean);

class CommentListChildrenItem extends StatefulWidget {
  final CommentChildrenListItemParameterBean _bean;
  final ClickCommentChildrenLike _clickCommentChildrenLike;
  final ClickCommentChildrenReply _clickCommentChildrenReply;
  final ClickCommentChildrenDelete _clickCommentChildrenDelete;

  CommentListChildrenItem(this._bean, this._clickCommentChildrenLike, this._clickCommentChildrenReply, this._clickCommentChildrenDelete, {Key? key})
      : super(key: key);

  @override
  _CommentListChildrenItemState createState() => _CommentListChildrenItemState();
}

class _CommentListChildrenItemState extends State<CommentListChildrenItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Color background;
    String avatar;
    String nickname;
    String createdAt;
    String likeCount;
    bool isLike;
    String cid;
    late String totalRevenue;
    String content;
    String uid;
    String commentName;
    bool isShowCreator = false;
    String id;
    String vid;
    bool isEableDeleteComment = false;
    String isCertification;
    bool isSendTicket = false;
    String isHolidayCelebrationStr = "0";
    if (widget._bean.commentChildrenListItemBean is CommentListItemBean) {
      CommentListItemBean commentListItemBean = widget._bean.commentChildrenListItemBean as CommentListItemBean;
      avatar = commentListItemBean.user.imageCompress?.avatarCompressUrl ?? "";
      if (ObjectUtil.isEmptyString(avatar)) {
        avatar = commentListItemBean.user.avatar;
      }
      nickname = commentListItemBean.user.nickname;
      createdAt = commentListItemBean.createdAt;
      likeCount = commentListItemBean.likeCount ?? "";
      isLike = commentListItemBean.isLike == CommentListItemBean.isLikeYes;
      cid = commentListItemBean.cid;
      content = commentListItemBean.content;
      uid = commentListItemBean.uid;
      commentName = commentListItemBean.user.nickname;
      isShowCreator = commentListItemBean.isCreator == CommentListItemBean.isCreatorYes;
      if (commentListItemBean.vestStatus == VideoInfoResponse.vestStatusFinish) {
        /// 奖励完成
        double totalRevenueVest = NumUtil.divide(
          NumUtil.getDoubleByValueStr(commentListItemBean.vest) as num,
          RevenueCalculationUtil.cosUnit,
        );
        double money = RevenueCalculationUtil.vestToRevenue(totalRevenueVest, widget._bean.exchangeRateInfoData);
        totalRevenue = Common.formatDecimalDigit(money, 2);
      } else {
        /// 奖励未完成
        double settlementBonusVest = RevenueCalculationUtil.getReplyVestByPower(commentListItemBean.votepower, widget._bean.chainStateBean?.dgpo);
        double money = (RevenueCalculationUtil.vestToRevenue(settlementBonusVest, widget._bean.exchangeRateInfoData));
        totalRevenue = Common.formatDecimalDigit(money, 2);
      }
      bool isShowInsertColor = commentListItemBean.isShowInsertColor ?? false;
      if (isShowInsertColor) {
        background = AppThemeUtil.setDifferentModeColor(
          lightColor: AppColors.color_eff5ff,
          darkColorStr: "333333 ",
        );
      } else {
        background = AppThemeUtil.setDifferentModeColor(
          lightColor: AppColors.color_f3f3f3,
          darkColor: AppColors.color_3e3e3e,
        );
      }
      id = commentListItemBean.id;
      vid = commentListItemBean.vid;
      isEableDeleteComment = commentListItemBean.isShowDeleteComment;
      isCertification = commentListItemBean.user.isCertification ?? "";
      isSendTicket = commentListItemBean.isSendTicket == CommentListItemBean.isSendTicketYes;
      isHolidayCelebrationStr = commentListItemBean.isHolidayCelebration ?? "";
    } else {
      CommentChildrenListItemBean commentChildrenListItemBean = widget._bean.commentChildrenListItemBean as CommentChildrenListItemBean;
      avatar = commentChildrenListItemBean.user.imageCompress?.avatarCompressUrl ?? "";
      if (ObjectUtil.isEmptyString(avatar)) {
        avatar = commentChildrenListItemBean.user.avatar;
      }
      nickname = commentChildrenListItemBean.user.nickname;
      createdAt = commentChildrenListItemBean.createdAt;
      likeCount = commentChildrenListItemBean.likeCount;
      isLike = commentChildrenListItemBean.isLike == CommentListItemBean.isLikeYes;
      cid = commentChildrenListItemBean.cid;
      content = commentChildrenListItemBean.content;
      uid = commentChildrenListItemBean.uid;
      commentName = commentChildrenListItemBean.user.nickname;
      isShowCreator = commentChildrenListItemBean.isCreator == CommentListItemBean.isCreatorYes;
      if (commentChildrenListItemBean.vestStatus == VideoInfoResponse.vestStatusFinish) {
        /// 奖励完成
        double totalRevenueVest = NumUtil.divide(
          NumUtil.getDoubleByValueStr(commentChildrenListItemBean.vest) as num,
          RevenueCalculationUtil.cosUnit,
        );
        double money = RevenueCalculationUtil.vestToRevenue(totalRevenueVest, widget._bean.exchangeRateInfoData);
        totalRevenue = Common.formatDecimalDigit(money, 2);
      } else {
        /// 奖励未完成
        double settlementBonusVest =
            RevenueCalculationUtil.getReplyVestByPower(commentChildrenListItemBean.votePower, widget._bean.chainStateBean?.dgpo);
        double money = (RevenueCalculationUtil.vestToRevenue(settlementBonusVest, widget._bean.exchangeRateInfoData));
        totalRevenue = Common.formatDecimalDigit(money, 2);
      }
      bool isShowInsertColor = commentChildrenListItemBean.isShowInsertColor ?? false;
      bool isShowParentColor = commentChildrenListItemBean.isShowParentColor ?? false;
      bool isShowTopColor = commentChildrenListItemBean.isShowTopColor ?? false;
      if (isShowInsertColor) {
        background = AppThemeUtil.setDifferentModeColor(
          lightColor: AppColors.color_eff5ff,
          darkColorStr: "333333 ",
        );
      } else {
        if (widget._bean.showType == CommentChildrenListItemParameterBean.showTypeCommentList) {
          if (isShowParentColor) {
            background = AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_f3f3f3,
              darkColor: AppColors.color_3e3e3e,
            );
          } else {
            if (isShowTopColor) {
              background = AppThemeUtil.setDifferentModeColor(
                lightColor: AppColors.color_eff5ff,
                darkColor: AppColors.color_333333,
              );
              Future.delayed(Duration(milliseconds: 1500), () {
                setState(() {
                  commentChildrenListItemBean.isShowTopColor = false;
                });
              });
            } else {
              background = AppThemeUtil.setDifferentModeColor(
                lightColor: AppColors.color_ffffff,
                darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
              );
            }
          }
        } else {
          background = AppThemeUtil.setDifferentModeColor(
            lightColor: AppColors.color_ffffff,
            darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
          );
        }
      }
      id = commentChildrenListItemBean.id;
      vid = commentChildrenListItemBean.vid;
      isEableDeleteComment = commentChildrenListItemBean.isShowDeleteComment ?? false;
      isCertification = commentChildrenListItemBean.user.isCertification;
      isSendTicket = commentChildrenListItemBean.isSendTicket == CommentListItemBean.isSendTicketYes;
      isHolidayCelebrationStr = commentChildrenListItemBean.isHolidayCelebration;
    }
    bool isShowDeleteComment = false;
    if (ObjectUtil.isNotEmpty(widget._bean.creatorUid) &&
        ObjectUtil.isNotEmpty(Constant.uid) &&
        widget._bean.creatorUid == Constant.uid &&
        isEableDeleteComment) {
      isShowDeleteComment = true;
    }
    bool isShowWomenDayIcn = isHolidayCelebrationStr == "1";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Offstage(
          offstage: widget._bean.index == 0,
          child: Container(
            height: AppDimens.item_line_height_0_5,
            color: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_e4e4e4,
              darkColorStr: "3E3E3E",
            ),
          ),
        ),
        Offstage(
          offstage: widget._bean.showType == CommentChildrenListItemParameterBean.showTypeVideoComment || widget._bean.index != 0,
          child: Container(
            alignment: Alignment.centerLeft,
            height: AppDimens.item_size_45,
            padding: EdgeInsets.only(left: AppDimens.item_size_15),
            color: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_ffffff,
              darkColorStr: widget._bean.showType == CommentChildrenListItemParameterBean.showTypeVideoComment
                  ? DarkModelBgColorUtil.pageBgColorStr
                  : DarkModelBgColorUtil.secondaryPageColorStr,
            ),
            child: Text(
              InternationalLocalizations.videoCommentReplyAll,
              style: TextStyle(
                color: AppThemeUtil.setDifferentModeColor(
                    lightColor: AppColors.color_333333, darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr),
                fontSize: AppDimens.text_size_14,
              ),
            ),
          ),
        ),
        Offstage(
          offstage: (widget._bean.showType == CommentChildrenListItemParameterBean.showTypeCommentList || widget._bean.index != 1),
          child: Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_15,
              top: AppDimens.margin_9_5,
              right: AppDimens.margin_15,
            ),
            child: Text(
              InternationalLocalizations.videoCommentReplyAll,
              style: TextStyle(
                color: AppThemeUtil.setDifferentModeColor(
                  lightColor: AppColors.color_333333,
                  darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                ),
                fontSize: AppDimens.text_size_12,
              ),
            ),
          ),
        ),
        Container(
          color: background,
          padding: EdgeInsets.only(
            left: AppDimens.margin_15,
            top: AppDimens.margin_15,
            right: AppDimens.margin_15,
          ),
          child: Stack(
            alignment: Alignment.topLeft,
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
                    if (avatar.isNotEmpty)
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
              Positioned(
                top: 16,
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
                              maxWidth: AppDimens.item_size_80,
                              child: Text(
                                nickname,
                                style: TextStyle(
                                  color: AppThemeUtil.setDifferentModeColor(
                                    lightColor: AppColors.color_333333,
                                    darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                                  ),
                                  fontSize: AppDimens.text_size_12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            //认证标识
                            Offstage(
                              offstage: !(isCertification == CommentListItemBean.isCertificationYes),
                              child: Container(
                                margin: EdgeInsets.only(left: 4, right: 3),
                                child: Image.asset(
                                  "assets/images/ic_comment_certification.png",
                                ),
                              ),
                            ),
                            //创作者标识
                            Offstage(
                              offstage: !isShowCreator,
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
                              offstage: !isSendTicket,
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
                                Text(
                                  likeCount,
                                  style: AppStyles.text_style_a0a0a0_14,
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: AppDimens.margin_5),
                                  child: isLike
                                      ? Image.asset('assets/images/ic_comment_like_yes.png')
                                      : Image.asset(AppThemeUtil.getCommentNotLikedIcn()),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.only(bottom: 10, left: 10),
                          ),
                          onTap: () {
                            if (Common.isAbleClick()) {
                              ClickCommentChildrenItemBean bean = ClickCommentChildrenItemBean();
                              bean.vestStatus = widget._bean.vestStatus;
                              bean.isLike = isLike;
                              bean.cid = cid;
                              bean.index = widget._bean.index;
                              widget._clickCommentChildrenLike(bean);
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
                                      isCertification: isCertification,
                                      rateInfoData: widget._bean.exchangeRateInfoData,
                                      dgpoBean: widget._bean.chainStateBean?.dgpo,
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
                        if (Common.isAbleClick()) {
                          ClickCommentChildrenItemBean bean = ClickCommentChildrenItemBean();
                          bean.commentName = commentName;
                          bean.uid = uid;
                          widget._clickCommentChildrenReply(bean);
                        }
                      },
                    ),
                    Container(
                      margin: EdgeInsets.only(top: AppDimens.margin_5, bottom: AppDimens.item_size_10),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              VideoAddMoneyWidget(
                                key: Common.getAddMoneyViewKeyFromSymbol("$cid + ${widget._bean.index.toString}"),
                                baseWidget: Text(
                                  '${Common.getCurrencySymbolByLanguage()} $totalRevenue',
                                  style: TextStyle(
                                    color: AppThemeUtil.setDifferentModeColor(
                                      lightColor: AppColors.color_333333,
                                      darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                                    ),
                                    fontSize: AppDimens.text_size_12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                textStyle: TextStyle(
                                  color: AppThemeUtil.setDifferentModeColor(
                                    lightColor: AppColors.color_333333,
                                    darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                                  ),
                                  fontSize: AppDimens.text_size_12,
                                  fontWeight: FontWeight.w700,
                                ),
                                translateY: -20,
                              ),
                              Container(
                                margin: EdgeInsets.only(left: AppDimens.margin_10),
                                child: Text(
                                  Common.calcDiffTimeByStartTime(createdAt),
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
                                      child: Text(InternationalLocalizations.videoCommentReply,
                                          style: TextStyle(
                                            color: AppThemeUtil.setDifferentModeColor(
                                              lightColor: AppColors.color_333333,
                                              darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                                            ),
                                            fontSize: AppDimens.text_size_12,
                                          )),
                                    ),
                                    onTap: () {
                                      if (Common.isAbleClick()) {
                                        ClickCommentChildrenItemBean bean = ClickCommentChildrenItemBean();
                                        bean.commentName = commentName;
                                        bean.uid = uid;
                                        widget._clickCommentChildrenReply(bean);
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
                                    if (Common.isAbleClick()) {
                                      ClickCommentChildrenItemBean bean = ClickCommentChildrenItemBean();
                                      bean.id = id;
                                      bean.vid = vid;
                                      bean.creatorUid = widget._bean.creatorUid;
                                      bean.index = widget._bean.index;
                                      widget._clickCommentChildrenDelete(bean);
                                    }
                                  },
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
