class VideoDetailPageParamsBean {

  String _vid;
  String _uid;
  String _videoSource;
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

  static VideoDetailPageParamsBean createInstance({
    String vid,
    String uid,
    String videoSource,
  }) {
    VideoDetailPageParamsBean videoDetailPageParamsBean = VideoDetailPageParamsBean();
    videoDetailPageParamsBean.setVid = vid;
    videoDetailPageParamsBean.setUid = uid;
    videoDetailPageParamsBean.setVideoSource = videoSource;
    return videoDetailPageParamsBean;
  }
}
