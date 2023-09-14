import 'package:costv_android/overlay/bean/video_small_windows_bean.dart';

enum VideoDetailsEnterSource {
  VideoDetailsEnterSourceUnknown,
  VideoDetailsEnterSourceHome, //首页进入
  VideoDetailsEnterSourceHot, //热门页
  VideoDetailsEnterSourceSubscription, //订阅页
  VideoDetailsEnterSourceWatchHistory, //观看历史页面
  VideoDetailsEnterSourceWatchHistoryList, //用户观看历史列表详情页
  VideoDetailsEnterSourceUserLikedList, //用户点赞过的视频列表详情页
  VideoDetailsEnterSourceSearch, //搜索页
  VideoDetailsEnterSourceTopicGame, //游戏主题页
  VideoDetailsEnterSourceTopicFun, //有趣主题页
  VideoDetailsEnterSourceTopicCutePet, //萌宠主题页
  VideoDetailsEnterSourceTopicMusic, //音乐主题页
  VideoDetailsEnterSourceH5LikeRewardVideo, //h5给奖励列表中的视频点赞
  VideoDetailsEnterSourceH5WorksOrDynamic, //h5我的作品或是动态
  VideoDetailsEnterSourceVideoDetail, //视频详情页当前页面切换
  VideoDetailsEnterSourceOtherCenter, //他人中心
  VideoDetailsEnterSourceVideoRecommend, //视频详情页的相关推荐
  VideoDetailsEnterSourceAutoPlay, //自动播放的下一个视频
  VideoDetailsEnterSourceEndRecommend, //播放结束后的推荐
  VideoDetailsEnterSourceNotification, //消息通知（消息中心页面或消息中心的评论页面）
  VideoDetailsEnterSourceVideoSmallWindows, //视频小窗口
}

class VideoDetailPageParamsBean {
  static const fromTypeVideoSmallWindows = 1;
  static const fromTypeOther = 2;
  int _fromType = 0;
  bool _isVideoSmallInit = false;
  String _vid = "'";
  String _uid = "";
  String _videoSource = "";
  VideoDetailsEnterSource? _enterSource;
  VideoSmallWindowsBean? _videoSmallWindowsBean;

  int get getFromType => _fromType;

  set setFromType(int value) {
    _fromType = value;
  }

  bool get isVideoSmallInit => _isVideoSmallInit;

  set setIsVideoSmallInit(bool value) {
    _isVideoSmallInit = value;
  }

  String get getVid => _vid;

  set setVid(String value) {
    _vid = value;
  }

  String get getUid => _uid;

  set setUid(String value) {
    _uid = value;
  }

  String get getVideoSource => _videoSource;

  set setVideoSource(String source) {
    _videoSource = source;
  }

  set setEnterSource(VideoDetailsEnterSource? enterSource) {
    _enterSource = enterSource;
  }

  VideoDetailsEnterSource? get getEnterSource => _enterSource;

  VideoSmallWindowsBean? get getVideoSmallWindowsBean => _videoSmallWindowsBean;

  set setVideoSmallWindowsBean(VideoSmallWindowsBean? value) {
    _videoSmallWindowsBean = value;
  }

  static VideoDetailPageParamsBean createInstance({
    int fromType = fromTypeOther,
    bool isVideoSmallInit = false,
    String vid = "",
    String uid = "",
    String videoSource = "",
    VideoDetailsEnterSource? enterSource,
    VideoSmallWindowsBean? videoSmallWindowsBean,
  }) {
    VideoDetailPageParamsBean videoDetailPageParamsBean = VideoDetailPageParamsBean();
    videoDetailPageParamsBean.setFromType = fromType;
    videoDetailPageParamsBean.setIsVideoSmallInit = isVideoSmallInit;
    videoDetailPageParamsBean.setVid = vid;
    videoDetailPageParamsBean.setUid = uid;
    videoDetailPageParamsBean.setVideoSource = videoSource;
    videoDetailPageParamsBean.setEnterSource = enterSource;
    videoDetailPageParamsBean.setVideoSmallWindowsBean = videoSmallWindowsBean;
    return videoDetailPageParamsBean;
  }
}
