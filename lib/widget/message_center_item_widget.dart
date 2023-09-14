import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/get_message_list_bean.dart';
import 'package:costv_android/pages/comment/widget/comment_rich_text_widget.dart';
import 'package:costv_android/pages/user/others_home_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ClickMessageCallBack = Function();

class MessageCenterItemWidget extends StatefulWidget {
  final ClickMessageCallBack? clickMessageCallBack;
  final GetMessageListItemBean? messageData;

  MessageCenterItemWidget({Key? key, this.clickMessageCallBack, this.messageData}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MessageCenterItemState();
  }
}

class MessageCenterItemState extends State<MessageCenterItemWidget> {
  @override
  Widget build(BuildContext context) {
    return _buildItem();
  }

  Widget _buildItem() {
    double screenWidth = MediaQuery.of(context).size.width;
    double ratio = screenWidth / 375;
    double coverRatio = 9.0 / 16.0;
    double coverWidth = 65.0 * ratio;
    double coverHeight = coverWidth * coverRatio;
    double redPointSize = 6.0, avatarLeftMargin = 4.0;
    double avatarSize = 30.0;
    double avatarPartsWidth = redPointSize + avatarLeftMargin + avatarSize;
    double leftPadding = 6, rightPadding = 15;
    double messageDescPartsWidth = screenWidth - leftPadding - avatarPartsWidth - rightPadding - coverWidth;
    return Material(
      color: AppColors.color_transparent,
      child: Ink(
//          color: AppThemeUtil.setDifferentModeColor(
//            lightColor: Common.getColorFromHexString("F6F6F6", 1.0),
//            darkColorStr: DarkModelBgColorUtil.pageBgColorStr
//          ),
          child: InkWell(
        child: Container(
          padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
          margin: EdgeInsets.only(top: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _buildAvatarParts(avatarSize, redPointSize, avatarLeftMargin),
              _buildMessageDetailParts(messageDescPartsWidth),
              _buildVideoCover(coverWidth, coverHeight),
            ],
          ),
        ),
        onTap: () {
          if (widget.clickMessageCallBack != null) {
            widget.clickMessageCallBack!();
          }
        },
      )),
    );
  }

  Widget _buildAvatarParts(double avatarSize, double redPointSize, double avatarLeftMargin) {
    return Container(
      width: avatarSize + redPointSize + avatarLeftMargin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          //red point
          _buildRedPoint(redPointSize),
          //avatar
          _buildAvatar(avatarLeftMargin, avatarSize),
        ],
      ),
    );
  }

  Widget _buildRedPoint(double redPointSize) {
    return Offstage(
      offstage: !_checkIsShowRedPoint(),
      child: Container(
        width: redPointSize,
        height: redPointSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(redPointSize / 2),
          color: Common.getColorFromHexString("FD3232", 1.0),
        ),
      ),
    );
  }

  Widget _buildAvatar(double avatarLeftMargin, double avatarSize) {
    String avatar = widget.messageData?.fromUidInfo.imageCompress?.avatarCompressUrl ?? "";
    if (!Common.checkIsNotEmptyStr(avatar)) {
      avatar = widget.messageData?.fromUidInfo.avatar ?? "";
    }
    return Material(
      color: AppColors.color_transparent,
      child: Ink(
        child: InkWell(
          child: Container(
            width: avatarSize,
            margin: EdgeInsets.only(left: avatarLeftMargin),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(avatarSize / 2),
            ),
            child: Stack(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: AppColors.color_ffffff,
                  radius: avatarSize / 2,
                  backgroundImage: AssetImage('assets/images/ic_default_avatar.png'),
                ),
                CircleAvatar(
                  backgroundColor: AppColors.color_transparent,
                  radius: avatarSize / 2,
                  backgroundImage: CachedNetworkImageProvider(
                    avatar,
                  ),
                )
              ],
            ),
          ),
          onTap: () {
            _jumpToUserCenter();
          },
        ),
      ),
    );
  }

  Widget _buildMessageDetailParts(double partsWidth) {
    bool isRead = !_checkIsShowRedPoint();
    Color timeColor = isRead
        ? AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("A0A0A0", 1.0),
            darkColorStr: "858585",
          )
        : AppThemeUtil.setDifferentModeColor(
            lightColor: Common.getColorFromHexString("858585", 1.0),
            darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
          );
    return Container(
      padding: EdgeInsets.only(left: 15, right: 10),
      width: partsWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          //message content
//          Container(
//            child: Text(
//              _getMessageContent(),
//              maxLines: 3,
//              overflow: TextOverflow.ellipsis,
//              textAlign: TextAlign.left,
//              style: TextStyle(
//                color: descColor,
//                fontSize: 14,
//              ),
//            ),
//          ),
          CommentRichTextWidget(
            _getMessageContent(),
            clickNameListener: (String uid, String name) {
              if (!ObjectUtil.isEmptyString(uid)) {
                Navigator.of(context).push(SlideAnimationRoute(
                  builder: (_) {
                    return OthersHomePage(
                      OtherHomeParamsBean(
                        uid: uid,
                        avatar: '',
                        nickName: name,
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
          //time
          Container(
            margin: EdgeInsets.only(top: 5),
            child: Text(
              _getMessageTime(),
              maxLines: 1,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: timeColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCover(double coverWidth, double coverHeight) {
    String imageUrl = widget.messageData?.videoInfo.videoImageCompress?.videoCompressUrl ?? "";
    if (!Common.checkIsNotEmptyStr(imageUrl)) {
      imageUrl = widget.messageData?.videoInfo.videoCoverBig ?? "";
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
        imageUrl: imageUrl,
        errorWidget: (context, url, error) => Container(),
      ),
    );
  }

  String _getMessageContent() {
    return widget.messageData?.content ?? "";
  }

  String _getMessageTime() {
    return Common.calcDiffTimeByStartTime(widget.messageData?.createdAt ?? "");
  }

  bool _checkIsShowRedPoint() {
    String readStatus = widget.messageData?.isRead ?? "1"; //消息是否已读，1 未读， 2 已读
    return readStatus == "1";
  }

  void _jumpToUserCenter() {
    String avatar = widget.messageData?.fromUidInfo.imageCompress?.avatarCompressUrl ?? '';
    if (!Common.checkIsNotEmptyStr(avatar)) {
      avatar = widget.messageData?.fromUidInfo.avatar ?? '';
    }
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return OthersHomePage(OtherHomeParamsBean(
          uid: widget.messageData?.fromUid ?? "",
          nickName: widget.messageData?.fromUidInfo.nickname ?? '',
          avatar: avatar,
        ));
      },
    ));
  }
}
