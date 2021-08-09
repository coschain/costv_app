import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/utils/video_report_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:costv_android/widget/video_time_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_widgets/flutter_widgets.dart';

enum HistoryItemPageSource {
  unKnownSource,
  watchVideoHistoryPage, //观看历史界面
  likedVideoListPage, //点赞视频列表界面
  ticketRewardVideoListPage, //礼物票打赏的视频列表界面
  OtherHome, //他人页
}

typedef DeleteVideoCallback = void Function(String uid, String vid);
typedef VisibilityChangedCallback = Function(int index, double visibleFraction);

class HistoryVideoItem extends StatefulWidget {
  final GetVideoListNewDataListBean video;
  final ExchangeRateInfoData exchangeRate; //汇率
  final dynamic_properties dgpoBean;
  final int index;
  final DeleteVideoCallback deleteCallBack;
  final String logPrefix;
  final HistoryItemPageSource source;
  final bool isEnableDelete;
  final VisibilityChangedCallback visibilityChangedCallback;
  final double radius;
  final SlidableController controller;

  HistoryVideoItem({
    this.video,
    this.exchangeRate,
    this.dgpoBean,
    this.index,
    this.deleteCallBack,
    this.logPrefix = "",
    this.source,
    this.isEnableDelete = true,
    this.visibilityChangedCallback,
    this.radius = 4,
    this.controller,
  });

  @override
  State<StatefulWidget> createState() {
    return _HistoryVideoItemState();
  }
}

class _HistoryVideoItemState extends State<HistoryVideoItem> {
  String _logPrefix;

  @override
  void initState() {
    super.initState();
    if (!Common.checkIsNotEmptyStr(widget.logPrefix)) {
      _logPrefix = _getLogPrefix();
    } else {
      _logPrefix = widget.logPrefix;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width - 20;
    double rate = screenWidth / 375.0, coverRate = 9 / 16;
    double coverWidth = 149 * rate,
        coverHeight = coverWidth * coverRate,
        boldFontSize = 14,
        normalFontSize = 11,
        rDescMargin = 8.0;
    double rightDescWidth = screenWidth - rDescMargin - coverWidth;
    String imageUrl = widget.video?.videoImageCompress?.videoCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(imageUrl)) {
      imageUrl = widget.video?.videoCoverBig ?? '';
    }
    return VisibilityDetector(
      key: Key(widget.video.id ?? widget.index),
      child: Slidable(
        key: Key('key${widget?.index?.toString() ?? widget.video.id}'),
        controller: widget.controller ?? SlidableController(),
        enabled: widget.isEnableDelete,
        child: Container(
          padding: EdgeInsets.only(top: AppDimens.margin_15),
          width: screenWidth,
//        height: 92,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              //左侧视频封面
              Container(
                width: coverWidth,
                height: coverHeight,
                child: Material(
                  child: Ink(
                    color: Common.getColorFromHexString("3F3F3F3F", 0.05),
                    child: InkWell(
                      onTap: () {
                        _onClickPlayVideo();
                      },
                      child: Stack(
                        children: <Widget>[
                          Container(
                            width: coverWidth,
                            height: coverHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(widget.radius ?? 0)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Common.getColorFromHexString("838383", 1),
                                  Common.getColorFromHexString("333333", 1),
                                ],
                              ),
                            ),
                            child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(widget.radius ?? 0),
                                child: CachedNetworkImage(
                                  fit: BoxFit.contain,
                                  imageUrl: imageUrl,
                                  placeholder: (context, url) => Container(
                                    color: Common.getColorFromHexString(
                                        "D6D6D6", 1.0),
                                  ),
                                )),
                          ),
                          _getVideoTimeWidget(),
//                          Positioned(
//                            left: 10,
//                            top: 10,
//                            child: Text(
//                              widget.video.id ?? '',
//                              style: TextStyle(
//                                color: Colors.red,
//                                fontSize: 10
//                              ),
//                            ),
//                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: rightDescWidth,
                height: coverHeight,
                margin: EdgeInsets.only(left: rDescMargin),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    //标题
                    Text(
                      widget.video?.title ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: boldFontSize,
                        color: AppThemeUtil.setDifferentModeColor(
                            lightColor:
                                Common.getColorFromHexString("333333", 1.0),
                            darkColorStr: DarkModelTextColorUtil
                                .firstLevelBrightnessColorStr),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // 作者
                    Text(
                      widget.video?.anchorNickname ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: normalFontSize,
                        color: AppThemeUtil.setDifferentModeColor(
                            lightColor:
                                Common.getColorFromHexString("A0A0A0", 1.0),
                            darkColorStr: DarkModelTextColorUtil
                                .secondaryBrightnessColorStr),
                      ),
                    ),
                    // 视频价值
                    Text(
                      _getVideoWorth(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: boldFontSize,
                          color: AppThemeUtil.setDifferentModeColor(
                              lightColor:
                                  Common.getColorFromHexString("333333", 1.0),
                              darkColorStr: DarkModelTextColorUtil
                                  .firstLevelBrightnessColorStr),
                          fontFamily: "DIN"),
                    ),
                    // 播放量和时间
                    DefaultTextStyle(
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                            lightColor:
                                Common.getColorFromHexString("A0A0A0", 1.0),
                            darkColorStr: DarkModelTextColorUtil
                                .secondaryBrightnessColorStr),
                        fontSize: normalFontSize,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: rightDescWidth,
                        ),
                        child: Text(
                          '${VideoUtil.formatPlayTimes(context, widget.video)}${VideoUtil.formatVideoCreateTime(context, widget.video)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              //右侧视频描述信息
            ],
          ),
        ),
        actionExtentRatio: 0.25,
        actionPane: SlidableDrawerActionPane(),
        actions: <Widget>[],
        secondaryActions: <Widget>[
          InkWell(
            child: Image.asset(
              "assets/images/ic_delete.png",
              fit: BoxFit.cover,
            ),
            onTap: () {
              _showDeleteConfirmDialog();
            },
          ),

//          IconSlideAction(
//            caption: '',
//            color: Common.getColorFromHexString("FA4F00", 1.0),
//            iconWidget: Container(
//              width: screenWidth*0.25,
//              color: Colors.black,
//              child: Image.asset(
//                "assets/images/ic_delete.png",
//                fit: BoxFit.cover,
//              ),
//            ),
//            onTap: () => _showDeleteConfirmDialog(),
//          ),
        ],
      ),
      onVisibilityChanged: (VisibilityInfo info) {
        if (widget.visibilityChangedCallback != null) {
          widget.visibilityChangedCallback(
              widget.index ?? -1, info.visibleFraction);
        }
      },
    );
  }

  Widget _getVideoTimeWidget() {
    if (Common.checkVideoDurationValid(widget.video?.duration)) {
      return Positioned(
        right: 0,
        bottom: 0,
        child:
            VideoTimeWidget(Common.formatVideoDuration(widget.video?.duration)),
      );
    }
    return Container();
  }

  void _onClickPlayVideo() {
    _reportVideoClick();
    String vid = widget.video?.id,
        uid = widget.video?.uid,
        videoSource = widget.video?.videosource;
    if (!Common.checkIsNotEmptyStr(vid)) {
      CosLogUtil.log("$_logPrefix: fail to jumtp to video detail page "
          "due to empty vid");
      return;
    }

//    if (!Common.checkIsNotEmptyStr(uid)) {
//      CosLogUtil.log("$pageLogPrefix: fail to jumtp to video detail page"
//          "due to empty uid");
//      return;
//    }
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
          vid: vid,
          uid: uid,
          videoSource: videoSource,
          enterSource: _getVideoDetailEnterSource(),
        ));
      },
      settings: RouteSettings(name: videoDetailPageRouteName),
      isCheckAnimation: true,
    ));
  }

  void _reportVideoClick() {
    if (widget?.video?.id != null) {
//      DataReportUtil.instance.reportData(
//          eventName: "Click_video",
//          params: {"Click_video": widget.video.id}
//      );
      if (widget.source == HistoryItemPageSource.OtherHome) {
        VideoReportUtil.reportClickVideo(
            ClickVideoSource.OtherCenter, widget.video?.id ?? '');
      } else if (widget.source == HistoryItemPageSource.likedVideoListPage) {
        VideoReportUtil.reportClickVideo(
            ClickVideoSource.UserLiked, widget.video?.id ?? '');
      } else if (widget.source == HistoryItemPageSource.watchVideoHistoryPage) {
        VideoReportUtil.reportClickVideo(
            ClickVideoSource.History, widget.video?.id ?? '');
      }
    }
  }

  String _getVideoWorth() {
    String symbol = Common.getCurrencySymbolByLanguage();
    String worth = VideoUtil.getVideoWorth(
        widget.exchangeRate, widget.dgpoBean, widget.video);
    return '$symbol $worth';
  }

  void _showDeleteConfirmDialog() async {
    var dialog = AlertDialog(
      title: Text(""),
      content: Text(InternationalLocalizations.deleteVideoTips),
      actions: <Widget>[
        new FlatButton(
          onPressed: () {
            if (widget.deleteCallBack != null) {
              widget.deleteCallBack(widget.video?.uid, widget.video?.id);
            }
            Navigator.of(context).pop(true);
          },
          child: new Text(InternationalLocalizations.confirm),
        ),
        new FlatButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: new Text(InternationalLocalizations.cancel),
        ),
      ],
    );
    var isDismiss = await showDialog(
        context: context,
        builder: (context) {
          return dialog;
        });
    if (isDismiss) {
      if (widget.deleteCallBack != null) {
        widget.deleteCallBack(widget.video?.uid, widget.video?.id);
      }
    }
  }

  String _getLogPrefix() {
    if (widget.source == HistoryItemPageSource.watchVideoHistoryPage) {
      return "watchVideoHistoryPage";
    } else if (widget.source == HistoryItemPageSource.likedVideoListPage) {
      return "LikedVideoListPage";
    } else if (widget.source ==
        HistoryItemPageSource.ticketRewardVideoListPage) {
      return "TicketRewardVideoListPage";
    }
    return "";
  }

  VideoDetailsEnterSource _getVideoDetailEnterSource() {
    VideoDetailsEnterSource source =
        VideoDetailsEnterSource.VideoDetailsEnterSourceUnknown;
    if (widget.source == HistoryItemPageSource.watchVideoHistoryPage) {
      source = VideoDetailsEnterSource.VideoDetailsEnterSourceWatchHistoryList;
    } else if (widget.source == HistoryItemPageSource.likedVideoListPage) {
      source = VideoDetailsEnterSource.VideoDetailsEnterSourceUserLikedList;
    } else if (widget.source == HistoryItemPageSource.OtherHome) {
      source = VideoDetailsEnterSource.VideoDetailsEnterSourceOtherCenter;
    }
    return source;
  }
}
