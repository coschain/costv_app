import 'package:common_utils/common_utils.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserSettingType {
  UnknownSetting,
  AutoPlaySetting, //自动播放
}

String autoPlayVideoDefault = "-1";

class UserUtil {
  static const String contentUidStart = 'data-id="';
  static const String contentUidEnd = '">@';
  static const String contentNickNameStart = '">@';
  static const String contentNickNameEnd = '</a>';

  static bool checkIsFollowByStateCode(String code) {
    if (!TextUtil.isEmpty(code)) {
      if (code == FollowStateResponse.followStateFollowing || code == FollowStateResponse.followStateFriend) {
        return true;
      }
    }
    return false;
  }

  static String getContentUid(String content) {
    if (ObjectUtil.isEmptyString(content)) {
      return '';
    }
    String contentUid = "";
    int indexStart = content.indexOf(contentUidStart);
    if (indexStart >= 0) {
      String subStringLinkUid = content.substring(indexStart + contentUidStart.length, content.length);
      int indexEnd = subStringLinkUid.indexOf(contentUidEnd);
      if (indexEnd >= 0) {
        contentUid = subStringLinkUid.substring(0, indexEnd);
      }
    }
    return contentUid;
  }

  static String getContentNickName(String content) {
    if (ObjectUtil.isEmptyString(content)) {
      return '';
    }
    String contentNickName = "";
    int indexStart = content.indexOf(contentNickNameStart);
    if (indexStart >= 0) {
      String subStringLinkUid = content.substring(indexStart + contentNickNameStart.length, content.length);
      int indexEnd = subStringLinkUid.indexOf(contentNickNameEnd);
      if (indexEnd >= 0) {
        contentNickName = subStringLinkUid.substring(0, indexEnd);
      }
    }
    return contentNickName;
  }

  static String getContentReply(String content) {
    if (ObjectUtil.isEmptyString(content)) {
      return '';
    }
    String reply = '';
    int indexLast = content.lastIndexOf(">");
    if (indexLast >= 0 && (indexLast + 1) < content.length) {
      reply = content.substring(indexLast + 1);
    }
    return reply;
  }

  ///获取用户是否打开自动播放的配置
  ///uid 作为key
  static Future<bool> getUserAutoPlaySetting(String uid) async {
    if (TextUtil.isEmpty(uid)) {
      return false;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? val = prefs.getBool(uid);
    if (val == null) {
      return false; //默认改为关闭,显示推荐列表
    }
    return val;
  }

  ///更新用户是否打开自动播放的配置
  static Future<void> updateUserAutoPlaySetting(String uid, bool val) async {
    if (TextUtil.isEmpty(uid)) {
      return null;
    }
    if (Common.judgeHasLogIn() && Constant.uid == uid) {
      usrAutoPlaySetting = val;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(uid, val);
  }
}
