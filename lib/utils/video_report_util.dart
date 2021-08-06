import 'package:costv_android/utils/data_report_util.dart';

enum ClickVideoSource {
  HomePage,
  Hot,
  Subscribe,
  OtherCenter,
  History,
  UserLiked,
  Search,
  VideoDetail,//视频详情
  HotTopic
}

class VideoReportUtil {
  static reportClickVideo(ClickVideoSource source, String vid) {
    String sourceStr = getClickVideoReportSourceName(source);
    DataReportUtil.instance.reportData(
        eventName: "Click_video",
        params: {
          "Click_video": vid ?? '',
          "source": sourceStr ?? ''
        }
    );
  }

  static String getClickVideoReportSourceName(ClickVideoSource source) {
    if (source == ClickVideoSource.HomePage) {
      return "homepage";
    } else if (source == ClickVideoSource.Hot) {
      return "hot";
    } else if (source == ClickVideoSource.Subscribe) {
      return "subscribe";
    } else if (source == ClickVideoSource.OtherCenter) {
      return "Creator";
    } else if (source == ClickVideoSource.History) {
      return "history";
    } else if (source == ClickVideoSource.Search) {
      return "search";
    } else if (source == ClickVideoSource.UserLiked) {
      return "like";
    } else if (source == ClickVideoSource.VideoDetail) {
      return "videoplay";
    } else if (source == ClickVideoSource.HotTopic) {
      return "tab";
    }
    return "";
  }
}
