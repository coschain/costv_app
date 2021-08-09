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

enum VideoExposureType {
  HomePageType, //首页
  HotPageType,  //热门
  SubscribePageType, //订阅
  OtherCenterType, //他人页
  HistoryType,//观看历史
  UserLikedType,//点赞过的视频
  HotTopicType, //热门详情
  VideoDetailType, //视频详情
  SearchType, //搜索
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

  static String getVideoExposureEventName(VideoExposureType tp) {
    if (tp == VideoExposureType.VideoDetailType) {
      return "Video_exposed_videoplay";
    } else if (tp == VideoExposureType.OtherCenterType) {
      return "Video_exposed_creator";
    } else if (tp == VideoExposureType.SubscribePageType) {
      return "Video_exposed_subscribe";
    } else if (tp == VideoExposureType.HistoryType) {
      return "Video_exposed_history";
    } else if (tp == VideoExposureType.HotPageType) {
      return "Video_exposed_hot";
    } else if (tp == VideoExposureType.SearchType) {
      return "Video_exposed_search";
    } else if (tp == VideoExposureType.HotTopicType) {
      return "Video_exposed_tab";
    } else if (tp == VideoExposureType.UserLikedType) {
      return "Video_exposed_like";
    } else if (tp == VideoExposureType.HomePageType) {
      return "Video_exposed_home";
    }
    return '';
  }


  static void reportVideoExposure(VideoExposureType tp, String vid, String uid) {
    String eventName = getVideoExposureEventName(tp);
    DataReportUtil.instance.reportData(
      eventName: eventName,
      params: {"vid": vid ??'', "uid": uid ?? ''}
    );
  }
}
