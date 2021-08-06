import 'package:common_utils/common_utils.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/net/request_manager.dart';

class UserUtil {
  static bool checkIsFollowByStateCode(String code) {
    if (!TextUtil.isEmpty(code)) {
      if (code == FollowStateResponse.followStateFollowing ||
          code == FollowStateResponse.followStateFriend) {
        return true;
      }
    }
    return false;
  }
}