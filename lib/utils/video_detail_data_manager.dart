import 'package:costv_android/bean/get_video_info_bean.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/bean/relate_list_bean.dart';
import 'package:costv_android/pages/video/bean/video_detail_all_data_bean.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/utils/common_util.dart';

int cRecommendCountDownTime = 5;

class VideoDetailDataMgr {
  static VideoDetailDataMgr? _instance;

  factory VideoDetailDataMgr() => _getInstance();

  static VideoDetailDataMgr get instance => _getInstance();
  Map<String, VideoDetailDataCacheBean> pageDataMap = {};

  VideoDetailDataMgr._();

  static VideoDetailDataMgr _getInstance() {
    if (_instance == null) {
      _instance = VideoDetailDataMgr._();
    }
    return _instance!;
  }

  void updateCurrentVideoDetailDataByKey(String pageKey, GetVideoInfoDataBean? videoInfo, List<RelateListItemBean> recommendVideoList) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      dataCacheBean?.updateCurrentVideoDetailData(videoInfo, recommendVideoList);
    }
  }

  void updateLoadStatuesByKey(String pageKey, bool isLoad) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      dataCacheBean?.updateLoadStatues(isLoad);
    }
  }

  bool getLoadStatuesByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      return dataCacheBean?._isLoad ?? false;
    }
    return false;
  }

  void updateFollowStatusByKey(String pageKey, bool isFollow) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      dataCacheBean?._isFollow = isFollow;
    }
  }

  bool getFollowStatusByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      return dataCacheBean?._isFollow ?? false;
    }
    return false;
  }

  bool checkIsLoadVideoByKey(String pageKey) {
    if (Common.checkIsNotEmptyStr(pageKey) && judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      return dataCacheBean?._isLoad ?? false;
    }
    return false;
  }

  List<RelateListItemBean>? getRecommendVideoListByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      return dataCacheBean?._recommendVideoList;
    }
    return [];
  }

  GetVideoInfoDataBean? getCurrentVideoInfoByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      return dataCacheBean?._curVideoData;
    }
    return null;
  }

  void updateCachedNextVideoInfoByKey(String pageKey, VideoDetailAllDataBean? data) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      dataCacheBean?.updateCachedNextVideoInfo(data);
    }
  }

  bool checkHasRecommendVideoByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      return dataCacheBean?.checkHasRecommendVideo() ?? false;
    }
    return false;
  }

  bool checkHasFollowingRecommendVideoByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      return dataCacheBean?.checkHasFollowingRecommendVideo() ?? false;
    }
    return false;
  }

  GetVideoListNewDataListBean? getFirstFollowingRecommendVideoByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? dataCacheBean = pageDataMap[pageKey];
      return dataCacheBean?.getFirstFollowingRecommendVideo();
    }
    return null;
  }

  bool judgeContainPageByKey(String pageKey) {
    if (pageDataMap.containsKey(pageKey)) {
      return true;
    }
    return false;
  }

  void resetData() {
    pageDataMap.clear();
  }

  void clearCachedDataByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      pageDataMap.remove(pageKey);
    }
  }

  void addPageCachedDataByKey(String pageKey) {
    if (!judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = VideoDetailDataCacheBean();
      pageDataMap[pageKey] = cacheBean;
    }
  }

  void updateCurrentVideoParamsBeanByKey(String pageKey, VideoDetailPageParamsBean paramsBean) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      cacheBean?._videoDetailPageParamsBean = paramsBean;
    }
  }

  void updateRecommendVideoByKey(String pageKey, List<RelateListItemBean> recommendVideoList) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      cacheBean?._recommendVideoList = recommendVideoList;
    }
  }

  void updateFollowingRecommendVideoByKey(String pageKey, List<GetVideoListNewDataListBean> followingRecommendVideoList) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      cacheBean?._followingRecommendVideoList = followingRecommendVideoList;
    }
  }

  VideoDetailAllDataBean? getCachedNextVideoDataByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?._cachedNextVideoData;
    }
    return null;
  }

  bool getIsShowUserRecommendByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?._isShowUserRecommend ?? false;
    }
    return false;
  }

  void updateShowUserRecommendByKey(String pageKey, bool val) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      cacheBean?._isShowUserRecommend = val;
    }
  }

  void updateReplayStatusByKey(String pageKey, bool val) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      cacheBean?._isReplayStatus = val;
    }
  }

  bool getIsReplayStatusByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?._isReplayStatus ?? false;
    }
    return false;
  }

  void updatePlayEndStatusByKey(String pageKey, bool val) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      cacheBean?._isPlayEnd = val;
    }
  }

  bool getIsPlayEndStatusByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?._isPlayEnd ?? false;
    }
    return false;
  }

  void updateIsHandelRequestStatusByKey(String pageKey, bool val) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      cacheBean?._isHandelRequest = val;
    }
  }

  bool getIsHandelRequestStatusByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?._isHandelRequest ?? false;
    }
    return false;
  }

  void updateRecommendCountDownValueByKey(String pageKey, int val) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      cacheBean?._recommendCountDownValue = val;
    }
  }

  int getRecommendCountDownValueByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?._recommendCountDownValue ?? 0;
    }
    return cRecommendCountDownTime;
  }

  void updateCurCountDownValueByKey(String pageKey, double val) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      cacheBean?._curCountDownValue = val;
    }
  }

  double getCurCountDownValueByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?._curCountDownValue ?? 0;
    }
    return 0;
  }

  bool getHasPreVideo(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?.checkHasPrevVideo() ?? false;
    }
    return false;
  }

  void pushPreVideoPageParamsByKey(String pageKey, VideoDetailPageParamsBean? paramsBean) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?.pushPageParams(paramsBean);
    }
  }

  VideoDetailPageParamsBean? popPreVideoPageParamsByKey(String pageKey) {
    if (judgeContainPageByKey(pageKey)) {
      VideoDetailDataCacheBean? cacheBean = pageDataMap[pageKey];
      return cacheBean?.popPageParams();
    }
    return null;
  }
}

class VideoDetailDataCacheBean {
  GetVideoInfoDataBean? _curVideoData;
  List<RelateListItemBean> _recommendVideoList = [];
  List<GetVideoListNewDataListBean> _followingRecommendVideoList = [];
  bool _isLoad = false;
  bool _isReplayStatus = false;
  bool _isPlayEnd = false;
  bool _isShowUserRecommend = false;
  bool _isFollow = false;
  bool _isHandelRequest = false;
  double _curCountDownValue = 0;
  int _recommendCountDownValue = cRecommendCountDownTime; //默认5s倒计时
  VideoDetailAllDataBean? _cachedNextVideoData;
  VideoDetailPageParamsBean? _videoDetailPageParamsBean;
  List<VideoDetailPageParamsBean> _prePageParamsList = [];

  VideoDetailDataCacheBean();

  void updateCurrentVideoDetailData(GetVideoInfoDataBean? videoInfo, List<RelateListItemBean> recommendVideoList) {
    _curVideoData = videoInfo;
    _recommendVideoList = recommendVideoList;
  }

  void updateLoadStatues(bool isLoad) {
    _isLoad = isLoad;
  }

  void updateCachedNextVideoInfo(VideoDetailAllDataBean? data) {
    _cachedNextVideoData = data;
  }

  bool checkHasRecommendVideo() {
    if (_recommendVideoList.isNotEmpty) {
      return true;
    }
    return false;
  }

  bool checkHasFollowingRecommendVideo() {
    if (_followingRecommendVideoList.isNotEmpty) {
      GetVideoListNewDataListBean video = _followingRecommendVideoList[0];
      String recUid = video.uid;
      String curUid = _videoDetailPageParamsBean?.getUid ?? '';
      if (recUid == curUid) {
        return true;
      }
    }
    return false;
  }

  GetVideoListNewDataListBean? getFirstFollowingRecommendVideo() {
    if (_followingRecommendVideoList.isNotEmpty) {
      return _followingRecommendVideoList[0];
    }
    return null;
  }

  bool checkHasPrevVideo() {
    if (_prePageParamsList.isNotEmpty) {
      return true;
    }
    return false;
  }

  void pushPageParams(VideoDetailPageParamsBean? paramsBean) {
    if (paramsBean == null) {
      return;
    }
    if (_prePageParamsList == null) {
      _prePageParamsList = [];
    }
    _prePageParamsList.add(paramsBean);
  }

  VideoDetailPageParamsBean popPageParams() {
    VideoDetailPageParamsBean pageParamsBean = VideoDetailPageParamsBean();
    if (_prePageParamsList.isNotEmpty) {
      pageParamsBean = _prePageParamsList.last;
      _prePageParamsList.removeLast();
    }
    return pageParamsBean;
  }
}
