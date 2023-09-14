import "package:costv_android/bean/get_video_info_bean.dart";
import "package:costv_android/bean/relate_list_bean.dart";

class VideoDetailDataChangeEvent {
  String flag;
  GetVideoInfoDataBean? curVideoData;
  List<RelateListItemBean> recommendVideoList;
  bool isReset;

  VideoDetailDataChangeEvent(this.flag, this.curVideoData, this.recommendVideoList, this.isReset);
}

class AutoPlaySwitchEvent {
  String flag;
  bool isOpen;
  AutoPlaySwitchEvent(this.flag, this.isOpen);
}

class AutoPlayCountDownStatusEvent {
  String flag;
  bool isFinish;
  AutoPlayCountDownStatusEvent(this.flag, this.isFinish);
}

class RefreshRecommendVideoFinishEvent {
  String flag;
  bool isSuccess;
  RefreshRecommendVideoFinishEvent(this.flag, this.isSuccess);
}

class FollowStatusChangeEvent {
  String flag;
  bool isFollow;
  bool isSuccess;
  FollowStatusChangeEvent(this.flag, this.isFollow, this.isSuccess);
}

class FetchFollowingRecommendVideoFinishEvent {
  String flag;
  bool isSuccess;
  FetchFollowingRecommendVideoFinishEvent(this.flag,this.isSuccess);
}