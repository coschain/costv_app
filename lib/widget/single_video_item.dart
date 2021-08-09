import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:common_utils/common_utils.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/pages/user/others_home_page.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/player/costv_controls.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/video_report_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:costv_android/widget/video_player_item_widget.dart';
import 'package:costv_android/widget/video_time_widget.dart';
import 'package:costv_android/widget/video_worth_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:video_player/video_player.dart';

enum EnterSource {
  HomePage,
  HotPage,
  SubscribePage,
  OtherCenter,
  HotTopicGame,
  HotTopicFun,
  HotTopicCutePet,
  HotTopicMusic,
}

typedef ClickPlayVideoCallBack = Function(GetVideoListNewDataListBean video);
typedef VisibilityChangedCallback = Function(int index, double visibleFraction);

class SingleVideoItem extends StatefulWidget {
  final GetVideoListNewDataListBean videoData;
  final ExchangeRateInfoData exchangeRate; //汇率
  final dynamic_properties dgpoBean;
  final int index;
  final ClickPlayVideoCallBack playVideoCallBack;
  final EnterSource source;
  final VisibilityChangedCallback visibilityChangedCallback;
  final bool isNeedAutoPlay;

  SingleVideoItem({
    Key key,
    this.videoData,
    this.exchangeRate,
    this.dgpoBean,
    this.index,
    this.playVideoCallBack,
    this.source,
    this.visibilityChangedCallback,
    this.isNeedAutoPlay = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SingleVideoItemState();
  }
}

class SingleVideoItemState extends State<SingleVideoItem> with RouteAware {
  bool _isNeedAutoPlay = false, _isIniting = false, _initSuccess = false;
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  String _tag = "SingleVideoItem";

  @override
  void dispose() {
    if (widget.visibilityChangedCallback != null) {
      widget.visibilityChangedCallback(widget.index ?? -1, 0.0);
    }
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isNeedAutoPlay = widget.isNeedAutoPlay;
    if (_isNeedAutoPlay) {
      _initVideoPlayers(widget?.videoData?.videosource, false);
    }
  }

  @override
  void didPushNext() {
    stopPlay();
    super.didPushNext();
  }

  @override
  void didUpdateWidget(SingleVideoItem oldWidget) {
    String oldUrl = oldWidget.videoData?.videosource;
    String newUrl = widget.videoData?.videosource;
    if (Common.checkIsNotEmptyStr(newUrl) && oldUrl != newUrl) {
      final oldPlayerController = _videoPlayerController;
      final oldChewieController = _chewieController;
      oldPlayerController?.pause();

      _videoPlayerController = null;
      _chewieController = null;
      if (widget.isNeedAutoPlay) {
        _initVideoPlayers(newUrl, false);
      }

      Future.delayed(Duration(seconds: 3), () {
        oldPlayerController?.dispose();
        oldChewieController?.dispose();
      });
    }
    routeObserver.subscribe(this, ModalRoute.of(context));
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    double itemWidth = _getItemWidth();
    double avatarSize = 33.0, descMargin = 8.0;
    double imgHeight = _getCoverHeight();
    double descWidth = itemWidth - avatarSize - descMargin, descBgHeight = 88;
    double worthWidth = descWidth * 0.4;
    double calcWidth = _calcVideoWorthWidth();
    //优先显示视频价值
    if (calcWidth >= descWidth * 0.8) {
      worthWidth = descWidth * 0.8;
    } else {
      worthWidth = calcWidth + 10;
    }
    double authorBgWidth = descWidth - worthWidth - 5;
    String imageUrl =
        widget.videoData?.videoImageCompress?.videoCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(imageUrl)) {
      imageUrl = widget.videoData?.videoCoverBig ?? '';
    }
    String avatar =
        widget.videoData?.anchorImageCompress?.avatarCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(avatar)) {
      avatar = widget.videoData?.anchorAvatar ?? '';
    }
    return VisibilityDetector(
      key: GlobalObjectKey(widget.videoData.id ?? (widget.index?.toString() ?? "")),
      onVisibilityChanged: (VisibilityInfo info) {
        if (widget.visibilityChangedCallback != null) {
          widget.visibilityChangedCallback(
              widget.index ?? -1, info.visibleFraction);
        }
        if (info.visibleFraction < 1.0 && mounted) {
          if (ModalRoute.of(context).isCurrent) {
            //如果当前是顶层路由，则停止，避免点搜索的时候被暂停
            stopPlay();
          }
        }
      },
      child: Container(
        color: AppThemeUtil.setDifferentModeColor(
            lightColor: AppColors.color_f6f6f6,
            darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: <Widget>[
            //video cover
            _buildVideoParts(itemWidth, imgHeight, imageUrl),
            // video desc
            Container(
              color: AppThemeUtil.setDifferentModeColor(
                  lightColor: AppColors.color_f6f6f6,
                  darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
              margin: EdgeInsets.only(
                  left: AppDimens.margin_10, right: AppDimens.margin_10),
              padding: EdgeInsets.only(
                  top: AppDimens.margin_13, bottom: AppDimens.margin_13),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                //author avatar
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      _onClickAvatar();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.color_ebebeb,
                            width: AppDimens.item_line_height_0_5),
                        borderRadius: BorderRadius.circular(avatarSize / 2),
                      ),
                      child: Stack(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: AppColors.color_ffffff,
                            radius: avatarSize / 2,
                            backgroundImage: AssetImage(
                                'assets/images/ic_default_avatar.png'),
                          ),
                          CircleAvatar(
                            backgroundColor: AppColors.color_transparent,
                            radius: avatarSize / 2,
                            backgroundImage: CachedNetworkImageProvider(
                              avatar,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  // title 、 watch number 、 author 、date
                  Expanded(
                      child: InkWell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        //title
                        Container(
                          margin: EdgeInsets.fromLTRB(descMargin, 0, 0, 0),
                          child: Text(
                            widget.videoData?.title ?? "",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppThemeUtil.setDifferentModeColor(
                                lightColorStr: "333333",
                                darkColorStr: DarkModelTextColorUtil
                                    .firstLevelBrightnessColorStr,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // author · watch number · date
                        Container(
                          margin: EdgeInsets.fromLTRB(descMargin, 2, 0, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
//                              Container(
//                                constraints: BoxConstraints(
//                                  maxWidth: authorBgWidth,
//                                ),
//                                child: Row(
//                                  crossAxisAlignment: CrossAxisAlignment.center,
//                                  children: <Widget>[
//                                    Container(
//                                      constraints: BoxConstraints(
//                                        maxWidth: authorBgWidth / 2,
//                                      ),
//                                      child: Text(
//                                        _formatAuthor() ?? "",
//                                        maxLines: 1,
//                                        overflow: TextOverflow.ellipsis,
//                                        style: TextStyle(
//                                          textBaseline: TextBaseline.alphabetic,
//                                          color: Common.getColorFromHexString(
//                                              "858585", 1.0),
//                                          fontSize: 11,
//                                        ),
//                                      ),
//                                    ),
//                                    Container(
//                                      constraints: BoxConstraints(
//                                        maxWidth: authorBgWidth / 2,
//                                      ),
//                                      child: Text(
//                                        _formatWatchNumber() ?? "",
//                                        maxLines: 1,
//                                        overflow: TextOverflow.ellipsis,
//                                        style: TextStyle(
//                                          color: Common.getColorFromHexString(
//                                              "858585", 1.0),
//                                          fontSize: 11,
//                                        ),
//                                      ),
//                                    ),
////                                Container(
////                                  constraints: BoxConstraints(
////                                    maxWidth: authorBgWidth / 3,
////                                  ),
////                                  child:  Text (
////                                    _formatCreateTimeDesc() ?? "",
////                                    maxLines: 1,
////                                    overflow: TextOverflow.ellipsis,
////                                    style: TextStyle(
////                                      color: Common.getColorFromHexString("858585", 1.0),
////                                      fontSize: 11,
////                                    ),
////                                  ),
////                                ),
//                                  ],
//                                ),
//                              ),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: authorBgWidth,
                                ),
                                child: Text(
                                  '${_formatAuthor() ?? ''}${_formatWatchNumber() ?? ''}',
                                  textAlign: TextAlign.start,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppThemeUtil.setDifferentModeColor(
                                      lightColorStr: "858585",
                                      darkColorStr: DarkModelTextColorUtil
                                          .secondaryBrightnessColorStr,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              //author
                              //视频价值
                              Container(
                                constraints:
                                    BoxConstraints(maxWidth: worthWidth),
                                child: VideoWorthWidget(
                                    _getCurrencySymbol(), _calcVideoWorth()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _onClickToPlayVideo(
                        widget.videoData?.id,
                        widget.videoData?.uid,
                        widget.videoData?.videosource,
                      );
                    },
                  ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

//  Future<void> resetMediaController() async {
//    if (_mediaController != null) {
//      _mediaController.reset(true);
//    }
//  }
//
  void startPlay() {
    if (!mounted) {
      return;
    }
    if (!_isNeedAutoPlay) {
      setState(() {
        _isNeedAutoPlay = true;
      });
    }

    if (_videoPlayerController != null && _chewieController != null) {
      if (_videoPlayerController?.value?.isPlaying ?? false) {
        return;
      }
      _videoPlayerController.play();
    } else {
      if (_isIniting) {
        return;
      }
      _initVideoPlayers(widget.videoData?.videosource, false);
    }
  }

  void stopPlay() {
    if (!mounted) {
      return;
    }

    if (_isNeedAutoPlay || _isIniting) {
      setState(() {
        _isNeedAutoPlay = false;
        _isIniting = false;
      });
    }
    if (_videoPlayerController?.value?.isPlaying ?? false) {
      _videoPlayerController.pause();
      VideoPlayerValue playValue = _videoPlayerController?.value;
      if (playValue != null && playValue.position != null && playValue.position > Duration(seconds: 0)) {
        _videoPlayerController.seekTo(Duration(seconds: 0));
      }
    }
  }

  Widget _buildVideoParts(double itemWidth, double imgHeight, String imageUrl) {
    if (_isNeedAutoPlay && !_isIniting && _initSuccess) {
      return _buildPlayerWidget(itemWidth, imgHeight);
    }
    return _buildVideoCover(itemWidth, imgHeight, imageUrl);
  }

  Widget _buildPlayerWidget(double imgWidth, double imgHeight) {
    double itemWidth = _getItemWidth();
    double imgHeight = _getCoverHeight();
    return InkWell(
      child: Container(
        height: imgHeight,
        width: imgWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromRGBO(84, 84, 84, 1.0), Colors.black],
          ),
        ),
        child: (_chewieController != null && _videoPlayerController != null)
            ? ClipRect(
                child: Chewie(
                controller: _chewieController,
              ))
            : _buildVideoCover(
                itemWidth, imgHeight, widget.videoData?.videosource),
      ),
      onTap: () {
        _onClickToPlayVideo(
          widget.videoData?.id,
          widget.videoData?.uid,
          widget.videoData?.videosource,
        );
      },
    );
  }

  Widget _buildVideoCover(double itemWidth, double imgHeight, String imageUrl) {
    return Container(
      color: AppThemeUtil.setDifferentModeColor(
          lightColor: AppColors.color_f6f6f6,
          darkColorStr: DarkModelBgColorUtil.pageBgColorStr),
//      padding: EdgeInsets.symmetric(horizontal: 10),
      width: itemWidth,
      height: imgHeight,
      child: InkWell(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            Container(
              width: itemWidth,
              height: imgHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Common.getColorFromHexString("838383", 1),
                    Common.getColorFromHexString("333333", 1),
                  ],
                ),
              ),
              child: CachedNetworkImage(
                fit: BoxFit.contain,
                placeholder: (BuildContext context, String url) {
                  return Container();
                },
                imageUrl: imageUrl,
                errorWidget: (context, url, error) => Container(),
              ),
            ),

            _buildBottomParts(),

//                    Positioned(
//                      left: 10,
//                      top: 10,
//                      child: Text(
//                        widget.videoData.id ?? '',
//                        style: TextStyle(
//                          color: Colors.red,
//                        ),
//                      ),
//                    ),
          ],
        ),
        onTap: () {
          _onClickToPlayVideo(
            widget.videoData?.id,
            widget.videoData?.uid,
            widget.videoData?.videosource,
          );
        },
      ),
    );
  }

  //计算视频价值文字的宽度
  double _calcVideoWorthWidth() {
    TextStyle style = TextStyle(
        fontSize: 12.5,
        color: Common.getColorFromHexString("D19900", 1.0),
        fontFamily: "DIN");
    //使用MediaQuery.of(context).textScaleFactor,避免不同机型计算的宽度不够
    TextPainter painter = TextPainter(
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr,
    );
    String text = _getCurrencySymbol() + " " + _calcVideoWorth();
    painter.text = TextSpan(text: text, style: style);
    painter.layout();
    double width = painter.width.roundToDouble() + 12;
    return width;
  }

  Widget _getVideoDurationWidget() {
    if (Common.checkVideoDurationValid(widget.videoData?.duration)) {
      return VideoTimeWidget(
          Common.formatVideoDuration(widget.videoData?.duration));
    }
    return Container();
  }

  //底部视频时长等
  Widget _buildBottomParts() {
    double bottomPosition = 0;
    if (!Common.checkVideoDurationValid(widget.videoData?.duration)) {
      bottomPosition = 10;
    }
    return Positioned(
      right: 0,
      bottom: bottomPosition,
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            _buildVideoLoadingWidget(),
            //视频时长
            _getVideoDurationWidget()
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLoadingWidget() {
    if (_isIniting) {
      return Container(
        margin: EdgeInsets.only(right: 10),
        child: SizedBox(
          height: 15,
          width: 15,
          child: Container(
              color: Colors.transparent,
              child: CircularProgressIndicator(
                strokeWidth: 1.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Common.getColorFromHexString("FFFFFF", 1.0)),
              )),
        ),
      );
    }
    return Container();
  }

  String _getCurrencySymbol() {
    return Common.getCurrencySymbolByLanguage();
  }

  String _formatAuthor() {
    String desc = "";
    if (Common.checkIsNotEmptyStr(widget.videoData?.anchorNickname)) {
      desc += widget.videoData.anchorNickname + " ";
    }
    return desc;
  }

  String _formatWatchNumber() {
    String desc = "";
    if (Common.checkIsNotEmptyStr(widget.videoData?.watchNum)) {
      if (_formatAuthor().length > 0) {
        desc += "· ";
      }
      desc +=
          '${InternationalLocalizations.watchNumberDesc(widget.videoData.watchNum)} ';
    }
    return desc;
  }

  String _formatCreateTimeDesc() {
    String desc = "";
    if (Common.checkIsNotEmptyStr(widget.videoData?.createdAt)) {
      if (_formatAuthor().length > 0 || _formatWatchNumber().length > 0) {
        desc += "· ";
      }
      desc += Common.calcDiffTimeByStartTime(widget.videoData.createdAt);
    }
    return desc;
  }

  void _onClickToPlayVideo(String vid, String uid, String videoSource) {
    _reportVideoClick();
    if (!Common.checkIsNotEmptyStr(vid)) {
      CosLogUtil.log("$_tag: fail to jumtp to video detail page "
          "due to empty vid");
      return;
    }

//    if (!Common.checkIsNotEmptyStr(uid)) {
//      CosLogUtil.log("SingleVideoItem: fail to jumtp to video detail page"
//          "due to empty uid");
//      return;
//    }
//    stopPlay(false);
    stopPlay();
    if (widget.playVideoCallBack != null) {
      widget.playVideoCallBack(widget.videoData);
    }
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

  void _onClickAvatar() {
    String avatar =
        widget.videoData?.anchorImageCompress?.avatarCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(avatar)) {
      avatar = widget.videoData?.anchorAvatar ?? '';
    }
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return OthersHomePage(OtherHomeParamsBean(
          uid: widget.videoData?.uid ?? "",
          nickName: widget.videoData?.anchorNickname ?? '',
          avatar: avatar,
          isCertification: widget.videoData?.isCertification ?? '',
          rateInfoData: widget.exchangeRate,
          dgpoBean: widget.dgpoBean,
        ));
      },
    ));
  }

  ///计算视频收益
  String _calcVideoWorth() {
    return VideoUtil.getVideoWorth(
        widget.exchangeRate, widget.dgpoBean, widget.videoData);
  }

  void _reportVideoClick() {
    if (widget?.videoData?.id != null) {
      if (widget.source == EnterSource.HomePage) {
        VideoReportUtil.reportClickVideo(
            ClickVideoSource.HomePage, widget.videoData?.id);
      } else if (widget.source == EnterSource.HotPage) {
        VideoReportUtil.reportClickVideo(
            ClickVideoSource.Hot, widget.videoData?.id);
      } else if (widget.source == EnterSource.SubscribePage) {
        VideoReportUtil.reportClickVideo(
            ClickVideoSource.Subscribe, widget.videoData?.id);
      } else if (widget.source == EnterSource.OtherCenter) {
        VideoReportUtil.reportClickVideo(
            ClickVideoSource.OtherCenter, widget.videoData?.id);
      } else if (_judgeEnterFromTopicDetail()) {
        VideoReportUtil.reportClickVideo(
            ClickVideoSource.HotTopic, widget.videoData?.id);
      }
    }
  }

  VideoDetailsEnterSource _getVideoDetailEnterSource() {
    if (widget.source == EnterSource.HotPage) {
      return VideoDetailsEnterSource.VideoDetailsEnterSourceHot;
    } else if (widget.source == EnterSource.HomePage) {
      return VideoDetailsEnterSource.VideoDetailsEnterSourceHome;
    } else if (widget.source == EnterSource.SubscribePage) {
      return VideoDetailsEnterSource.VideoDetailsEnterSourceSubscription;
    } else if (widget.source == EnterSource.HotTopicGame) {
      return VideoDetailsEnterSource.VideoDetailsEnterSourceTopicGame;
    } else if (widget.source == EnterSource.HotTopicCutePet) {
      return VideoDetailsEnterSource.VideoDetailsEnterSourceTopicCutePet;
    } else if (widget.source == EnterSource.HotTopicFun) {
      return VideoDetailsEnterSource.VideoDetailsEnterSourceTopicFun;
    } else if (widget.source == EnterSource.HotTopicMusic) {
      return VideoDetailsEnterSource.VideoDetailsEnterSourceTopicMusic;
    } else if (widget.source == EnterSource.OtherCenter) {
      return VideoDetailsEnterSource.VideoDetailsEnterSourceOtherCenter;
    }
    return VideoDetailsEnterSource.VideoDetailsEnterSourceUnknown;
  }

  bool _judgeEnterFromTopicDetail() {
    if (widget.source == EnterSource.HotTopicCutePet ||
        widget.source == EnterSource.HotTopicFun ||
        widget.source == EnterSource.HotTopicGame ||
        widget.source == EnterSource.HotTopicMusic) {
      return true;
    }
    return false;
  }

  Future<void> _initVideoPlayers(String videoUrl, bool isFullScreen) async {
    if (!Common.checkIsNotEmptyStr(videoUrl)) {
      CosLogUtil.log("$_tag: fail to init video, the video source is empty");
      return;
    }
    _isIniting = true;
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    await _videoPlayerController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isIniting = false;
        if (_isNeedAutoPlay) {
          _initSuccess = true;
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            aspectRatio: _videoPlayerController.value.aspectRatio,
            autoPlay: true,
            looping: true,
            showControlsOnInitialize: false,
            allowMuting: false,
            isLive: _videoPlayerController.value.duration == Duration.zero,
            customControls: VideoPlayerItemWidget(
              key: UniqueKey(),
            ),
            materialProgressColors: CosTVControlColor.MaterialProgressColors,
            deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
            isInitFullScreen: false,
          );
          //静音播放
          _chewieController.setVolume(0);
        } else {
          _videoPlayerController = null;
          _chewieController = null;
        }
      });
    }).catchError((err) {
      CosLogUtil.log("$_tag: fail to init video "
          "source:${widget?.videoData?.videosource ?? ""}, the error is $err");
      setState(() {
        _initSuccess = false;
        _isIniting = false;
      });
    });
  }

  double _getItemWidth() {
    double itemWidth = MediaQuery.of(context).size.width - 20;
    return itemWidth;
  }

  double _getCoverHeight() {
    double itemWidth = _getItemWidth();
    double imgRatio = 9 / 16;
    double imgHeight = imgRatio * itemWidth;
    return imgHeight;
  }
}
