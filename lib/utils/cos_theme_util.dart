import 'package:costv_android/utils/common_util.dart';
import 'package:flutter/material.dart';
import 'global_util.dart';

class AppThemeUtil {
  AppThemeUtil._();

  static bool checkIsDarkMode() {
    return brightnessModel == Brightness.dark;
  }

  ///设置不同模式下的色值
  static Color setDifferentModeColor({
    String lightColorStr,
    double lightAlpha = 1.0,
    Color  lightColor,
    String darkColorStr,
    double darkAlpha = 1.0,
    Color  darkColor,
  }) {
    if (checkIsDarkMode()) {
      if (Common.checkIsNotEmptyStr(darkColorStr)) {
        if (darkAlpha < 0) {
          darkAlpha = 0;
        }
        return Common.getColorFromHexString(darkColorStr, darkAlpha);
      } else if (darkColor != null) {
        return darkColor;
      }
    } else {
      if (Common.checkIsNotEmptyStr(lightColorStr)) {
        if (lightAlpha < 0) {
          lightAlpha = 0;
        }
        return Common.getColorFromHexString(lightColorStr, lightAlpha);
      } else if (lightColor != null) {
        return lightColor;
      }
    }
    return null;
  }



  ///获取一级亮度颜色
  static  String getFirstLevelTitleColorStr() {
    return "333333";
  }
  ///获取二级评论颜色
  static String getSecondaryTitleColorStr() {
    if (checkIsDarkMode()) {
      return "858585";
    }
    return "858585";
  }

  static String getUnselectedHomeIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.homeUnSelectedIcnPath;

    }
    return LightModelBottomBarImgAssetUtil.homeUnSelectedIcnPath;
  }

  static String getSelectedHomeIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.homeSelectedIcnPath;

    }
    return LightModelBottomBarImgAssetUtil.homeSelectedIcnPath;
  }

  static String getUnselectedHotIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.hotUnSelectedIcnPath;
    }
    return LightModelBottomBarImgAssetUtil.hotUnSelectedIcnPath;
  }

  static String getSelectedHotIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.hotSelectedIcnPath;
    }
    return LightModelBottomBarImgAssetUtil.hotSelectedIcnPath;
  }

  static String getSelectedSubSubscriptionIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.subSubscriptionSelectedIcnPath;
    }
    return LightModelBottomBarImgAssetUtil.subSubscriptionSelectedIcnPath;
  }

  static String getUnselectedSubSubscriptionIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.subSubscriptionUnSelectedIcnPath;
    }
    return LightModelBottomBarImgAssetUtil.subSubscriptionUnSelectedIcnPath;
  }

  static String getSelectedMessageCenterIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.messageSelectedIcnPath;
    }
    return LightModelBottomBarImgAssetUtil.messageSelectedIcnPath;
  }

  static String getUnSelectedMessageCenterIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.messageUnSelectedIcnPath;
    }
    return LightModelBottomBarImgAssetUtil.messageUnSelectedIcnPath;
  }


  static String getUnselectedHistoryIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.historyUnSelectedIcnPath;
    }
    return LightModelBottomBarImgAssetUtil.historyUnSelectedIcnPath;
  }

  static String getSelectedHistoryIcn() {
    if (checkIsDarkMode()) {
      return DarkModelBottomBarImgAssetUtil.historySelectedIcnPath;
    }
    return LightModelBottomBarImgAssetUtil.historySelectedIcnPath;
  }

  ///pop 图标地址
  static String getPopIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_pop.png";
    }
    return "assets/images/ic_title_pop.png";
  }

  ///upload 图标地址
  static String getUploadIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/ic_upload_dark.png";
    }
    return "assets/images/ic_upload.png";
  }

  ///Selection 图标地址
  static String getSelectionIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/ic_selected.png";
    }
    return "assets/images/ic_selected.png";
  }

  ///Selection 图标地址
  static String getMoreIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/ic_more.png";
    }
    return "assets/images/ic_more.png";
  }

  ///搜索图标地址
  static String getSearchIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_serch_icn.png";
    }
    return "assets/images/ic_title_search.png";
  }

  ///返回按钮图标地址
  static String getBackIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_back.png";
    }
    return "assets/images/ic_back.png";
  }

  ///向右箭头图标地址
  static String getRightIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_right.png";
    }
    return "assets/images/ic_right_gift.png";
  }

  static String getHistoryEntranceRightIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_right.png";
    }
    return "assets/images/icn_history_right.png";
  }

  ///logo
  static String getLogoIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_logo_icn.png";
    }
    return "assets/images/ic_title_logo.png";
  }

  ///用户观看历史图标地址
  static String getUserWatchHistoryIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_watch_history.png";
    }
    return "assets/images/ic_watch_history.png";
  }

  ///用户点赞的视频图标地址
  static String getUserLikedIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_liked.png";
    }
    return "assets/images/ic_liked.png";
  }

  ///问题反馈图标地址
  static String getFeedbackIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_ic_watch_feedback.png";
    }
    return "assets/images/ic_watch_feedback.png";
  }

  ///视频未点赞图标地址
  static String getVideoLikedNoIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_video_lieked_no.png";
    }
    return 'assets/images/ic_video_like_no.png';
  }

  ///视频分享图标
  static String getVideoShareIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_share.png";
    }
    return 'assets/images/ic_share.png';
  }

  ///视频举报图标
  static String getVideoReportIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_report.png";
    }
    return 'assets/images/ic_report.png';
  }

  ///自动播放提示箭头
  static String getAutoPlayTipDownArrow() {
    if (checkIsDarkMode()) {
      return 'assets/images/dark_icn_arrow_down.png';
    }
    return "assets/images/icn_arrow_down.png";
  }

  ///自动播放疑问按钮图标地址
  static String getQuestionIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_top_more_msg.png";
    }
    return "assets/images/ic_top_more_msg.png";
  }

  ///icn down
  static String getIcnDownTitle() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_ic_down_title.png";
    }
    return 'assets/images/ic_down_title.png';
  }

  ///video settlement triangle
  static String getSettlementTriangle() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_bg_triangle_black.png";
    }
    return "assets/images/bg_triangle_white.png";
  }

  ///search close icn
  static String getSearchCloseIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_search_close.png";
    }
    return "assets/images/ic_input_close.png";
  }

  ///暗夜/日间模式图标
  static String getModeMenuIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/icn_dark_mode_menu.png";
    }
    return "assets/images/icn_light_mode_menu.png";
  }

  ///暗夜/日间模式toast提示图标
  static String getModeToastIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_mode_toast.png";
    }
    return "assets/images/light_mode_toast.png";
  }

  ///评论未点赞图标
  static String getCommentNotLikedIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_comment_like_no.png";
    }
    return "assets/images/ic_comment_like_no.png";
  }

  ///评论删除等操作按钮
  static String getCommentMoreIcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_comment_more.png";
    }
    return "assets/images/ic_comment_more.png";
  }

  ///评论切换图标
  static String getCommentSwitchICcn() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_icn_comment_switch.png";
    }
    return "assets/images/ic_comment_switch.png";
  }

  ///创作者emoji——解锁弹出框提示图片
  static String getUnlockEmojiBody() {
    if (checkIsDarkMode()) {
      return "assets/images/ic_unlock_emoji_body_dark.png";
    }
    return "assets/images/ic_unlock_emoji_body.png";
  }

  ///视频小窗口页面——等待播放
  static String getSmallWindowVideoPlay() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_ic_small_window_video_play.png";
    }
    return "assets/images/ic_small_window_video_play.png";
  }

  ///视频小窗口页面——正在播放
  static String getSmallWindowVideoStop() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_ic_small_window_video_stop.png";
    }
    return "assets/images/ic_small_window_video_stop.png";
  }

  ///视频小窗口页面——等待重新播放
  static String getSmallWindowVideoReplay() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_ic_small_window_video_replay.png";
    }
    return "assets/images/ic_small_window_video_replay.png";
  }

  ///视频小窗口页面——关闭窗口
  static String getSmallWindowVideoClose() {
    if (checkIsDarkMode()) {
      return "assets/images/dark_ic_small_window_video_close.png";
    }
    return "assets/images/ic_small_window_video_close.png";
  }

  ///视频详情页面——输入emoji表情
  static String getCommentInputEmoji() {
    if (checkIsDarkMode()) {
      return "assets/images/ic_comment_input_emoji_drak.png";
    }
    return "assets/images/ic_comment_input_emoji.png";
  }

  ///视频详情页面——输入普通文本
  static String getCommentInputText() {
    if (checkIsDarkMode()) {
      return "assets/images/ic_comment_input_text_drak.png";
    }
    return "assets/images/ic_comment_input_text.png";
  }

  static Color getUploadHintTextColor() {
    return Common.getColorFromHexString(checkIsDarkMode()? "3E3E3E" : "D6D6D6", 1.0);
  }

  static Color getListSeparatorColor() {
    return Common.getColorFromHexString(checkIsDarkMode()? "3E3E3E" : "D6D6D6", 1.0);
  }

  static Color getButtonDisabledColor() {
    return Common.getColorFromHexString(checkIsDarkMode()? "3E3E3E" : "D6D6D6", 1.0);
  }
}

///暗黑模式文字颜色
class DarkModelTextColorUtil {
  DarkModelTextColorUtil._();
  static const String firstLevelBrightnessColorStr = "D6D6D6";
  static const String secondaryBrightnessColorStr = "858585";
  static const String videoWorthColorStr = "D19900";
}

///暗黑模式页面、弹窗等背景色
class DarkModelBgColorUtil {
  DarkModelBgColorUtil._();
  //页面背景颜色
  static const String pageBgColorStr = "1D1D1D";
  //弹窗、状态栏等二级界面颜色
  static const String secondaryPageColorStr = "2A2A2A";
  //确认按钮等背景颜色
  static const String confirmBgColorStr = "858585";
  //取消按钮等背景颜色
  static const String cancelBgColorStr = "285EDB";
}

///暗黑模式底部bar本地图片Asset地址
class DarkModelBottomBarImgAssetUtil {
  DarkModelBottomBarImgAssetUtil._();
  static const String homeSelectedIcnPath = "assets/images/dark_icn_home_select.png";
  static const String homeUnSelectedIcnPath = "assets/images/dark_icn_home_unselect.png";
  static const String hotSelectedIcnPath = "assets/images/dark_icn_hot_select.png";
  static const String hotUnSelectedIcnPath = "assets/images/dark_icn_hot_unselect.png";
  static const String subSubscriptionSelectedIcnPath = "assets/images/dark_icn_subscription_select.png";
  static const String subSubscriptionUnSelectedIcnPath = "assets/images/dark_icn_subscription_unselect.png";
  static const String messageSelectedIcnPath = "assets/images/dark_icn_message_select.png";
  static const String messageUnSelectedIcnPath = "assets/images/dark_icn_message_unselect.png";
  static const String historySelectedIcnPath = "assets/images/dark_icn_history_select.png";
  static const String historyUnSelectedIcnPath = "assets/images/dark_icn_history_unselect.png";
  static const String watchHistoryLikedIcnPath = "assets/images/dark_icn_liked.png";
}


class LightModelBottomBarImgAssetUtil {
  LightModelBottomBarImgAssetUtil._();
  static const String homeSelectedIcnPath = "assets/images/ic_home_select.png";
  static const String homeUnSelectedIcnPath = "assets/images/ic_home.png";
  static const String hotSelectedIcnPath = "assets/images/ic_popular_select.png";
  static const String hotUnSelectedIcnPath = "assets/images/ic_popular.png";
  static const String subSubscriptionSelectedIcnPath = "assets/images/ic_my_subscription_select.png";
  static const String subSubscriptionUnSelectedIcnPath = "assets/images/ic_my_subscription.png";
  static const String messageSelectedIcnPath = "assets/images/ic_message_select.png";
  static const String messageUnSelectedIcnPath = "assets/images/ic_message.png";
  static const String historySelectedIcnPath = "assets/images/ic_see_history_select.png";
  static const String historyUnSelectedIcnPath = "assets/images/ic_see_history.png";
  static const String watchHistoryLikedIcnPath = "assets/images/ic_liked.png";
}