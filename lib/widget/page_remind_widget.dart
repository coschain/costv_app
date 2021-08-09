import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum RemindType {
  UnknownPage,
  NetRequestFail, //网络接口请求失败
  SubscriptionPageLogIn, //订阅界面提醒登录
  MessagePageLogIn, //消息界面提醒登录
  WatchHistoryPageLogIn, //观看历史界面提醒登录
  SubscriptionPageFollow, //订阅界面提醒用户关注创作者
  MessageNoData, //消息界面无数据
  CommentListPageLogIn, //评论一级界面提醒登录
  CommentChildrenListPageLogIn, //评论二级界面提醒登录
  VideoUploadPageLogIn, //视频上传界面提醒登录
  VideoUploadPageSuccess, //视频上传成功界面
}

typedef ClickCallBack = void Function();

class PageRemindWidget extends StatelessWidget {
  final RemindType remindType;
  final ClickCallBack clickCallBack;

  PageRemindWidget({this.clickCallBack, this.remindType});

  @override
  Widget build(BuildContext context) {
    Size bgSize = MediaQuery.of(context).size;
    return Container(
      color: AppThemeUtil.setDifferentModeColor(
        darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
      ),
      width: bgSize.width,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //图片
            Container(
              child: Image.asset(
                _getImagePath(),
                fit: BoxFit.cover,
              ),
            ),
            //标题
            Container(
              margin: EdgeInsets.only(top: _getTitleTopMargin()),
              child: Text(
                _getTitle(),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  color: AppThemeUtil.setDifferentModeColor(
                    lightColor: Common.getColorFromHexString("333333", 1.0),
                    darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                  ),
                  fontSize: 16,
                ),
              ),
            ),
            //描述
            Offstage(
              offstage: (remindType == RemindType.MessageNoData),
              child: Container(
                margin: EdgeInsets.only(top: 5),
                child: Text(
                  _getDesc(),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                    color: Common.getColorFromHexString("858585", 1.0),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Offstage(
              offstage: (remindType == RemindType.MessageNoData),
              child: _getBottomWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBottomWidget() {
    if (remindType == RemindType.SubscriptionPageFollow) {
      //描述
      return Container(
        margin: EdgeInsets.only(top: 25),
        child: Text(
          InternationalLocalizations.noSubscribe,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 3,
          style: TextStyle(
            color: Common.getColorFromHexString("858585", 1.0),
            fontSize: 14,
          ),
        ),
      );
    }
    //按钮
    return Container(
      margin: EdgeInsets.only(top: 20),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        color: Common.getColorFromHexString("3674FF", 1.0),
        onPressed: _onClickLogIn,
        child: Text(
          _getBtnTitle(),
          style: TextStyle(
            color: Common.getColorFromHexString("FFFFFF", 1.0),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _onClickLogIn() {
    if (clickCallBack != null) {
      clickCallBack();
    }
  }

  String _getImagePath() {
    if (remindType == RemindType.NetRequestFail) {
      return "assets/images/img_request_fail.png";
    } else if (remindType == RemindType.SubscriptionPageLogIn ||
        remindType == RemindType.SubscriptionPageFollow ||
        remindType == RemindType.MessagePageLogIn ||
        remindType == RemindType.CommentListPageLogIn ||
        remindType == RemindType.CommentChildrenListPageLogIn) {
      return "assets/images/img_subscription_remind.png";
    } else if (remindType == RemindType.MessageNoData) {
      return "assets/images/img_message_remind.png";
    } else if (remindType == RemindType.WatchHistoryPageLogIn) {
      return "assets/images/img_watch_history_remind.png";
    } else if (remindType == RemindType.VideoUploadPageLogIn) {
      return "assets/images/img_subscription_remind.png";
    } else if (remindType == RemindType.VideoUploadPageSuccess) {
      return "assets/images/img_upload_succ.png";
    }
    return "";
  }

  double _getTitleTopMargin() {
    double margin = 0;
    if (remindType == RemindType.NetRequestFail) {
      margin = 60;
    } else if (remindType == RemindType.WatchHistoryPageLogIn ||
        remindType == RemindType.MessagePageLogIn ||
        remindType == RemindType.SubscriptionPageLogIn ||
        remindType == RemindType.CommentListPageLogIn ||
        remindType == RemindType.CommentChildrenListPageLogIn ||
        remindType == RemindType.VideoUploadPageLogIn ||
        remindType == RemindType.VideoUploadPageSuccess) {
      return 40;
    }
    return margin;
  }

  String _getTitle() {
    if (remindType == RemindType.NetRequestFail) {
      return InternationalLocalizations.netRequestFailTips;
    } else if (remindType == RemindType.SubscriptionPageLogIn ||
        remindType == RemindType.MessagePageLogIn ||
        remindType == RemindType.WatchHistoryPageLogIn ||
        remindType == RemindType.CommentListPageLogIn ||
        remindType == RemindType.CommentChildrenListPageLogIn ||
        remindType == RemindType.VideoUploadPageLogIn ) {
      return InternationalLocalizations.notLogInTips;
    } else if (remindType == RemindType.MessageNoData) {
      return InternationalLocalizations.messageNoData;
    } else if (remindType == RemindType.VideoUploadPageSuccess) {
      return InternationalLocalizations.videoUploadSuccess;
    }
    return "";
  }

  String _getDesc() {
    if (remindType == RemindType.NetRequestFail) {
      return InternationalLocalizations.netRequestFailDesc;
    } else if (remindType == RemindType.SubscriptionPageLogIn) {
      return InternationalLocalizations.subscriptionLogInTips;
    } else if (remindType == RemindType.MessagePageLogIn ||
        remindType == RemindType.CommentListPageLogIn ||
        remindType == RemindType.CommentChildrenListPageLogIn) {
      return InternationalLocalizations.messageLogInTips;
    } else if (remindType == RemindType.WatchHistoryPageLogIn) {
      return InternationalLocalizations.watchHistoryLogInTips;
    } else if (remindType == RemindType.VideoUploadPageLogIn) {
      return InternationalLocalizations.videoUploadLogInTips;
    } else if (remindType == RemindType.VideoUploadPageSuccess) {
      return InternationalLocalizations.videoUploadSuccessDesc;
    }
    return "";
  }

  String _getBtnTitle() {
    if (remindType == RemindType.NetRequestFail) {
      return InternationalLocalizations.reloadData;
    } else if (remindType == RemindType.SubscriptionPageLogIn ||
        remindType == RemindType.MessagePageLogIn ||
        remindType == RemindType.WatchHistoryPageLogIn ||
        remindType == RemindType.CommentListPageLogIn ||
        remindType == RemindType.CommentChildrenListPageLogIn ||
        remindType == RemindType.VideoUploadPageLogIn ) {
      return InternationalLocalizations.logIn;
    } else if (remindType == RemindType.VideoUploadPageSuccess) {
      return InternationalLocalizations.videoUploadSuccessBtn;
    }
    return "";
  }
}
