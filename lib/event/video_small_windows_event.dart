class VideoSmallWindowsEvent {

  /// 视频小窗口显示
  static const statusSmallWindowsShow = 1;

  /// 视频小窗口关闭
  static const statusSmallWindowsClose = 2;

  int status;

  VideoSmallWindowsEvent(this.status);

}