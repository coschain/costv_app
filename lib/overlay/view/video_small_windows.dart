import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/get_video_info_bean.dart';
import 'package:costv_android/bean/relate_list_bean.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/video_small_show_status_event.dart';
import 'package:costv_android/overlay/bean/video_small_windows_bean.dart';
import 'package:costv_android/overlay/overlay_video_small_windows_utils.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/player/costv_fullscreen.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:costv_android/pages/video/player/costv_controls.dart';

class VideoSmallWindows extends StatefulWidget {
  final VideoSmallWindowsBean _bean;

  VideoSmallWindows(this._bean);

  @override
  _VideoSmallWindowsState createState() => _VideoSmallWindowsState();
}

class _VideoSmallWindowsState extends State<VideoSmallWindows> with TickerProviderStateMixin {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  late AnimationController _controllerProgress;
  String _pageFlag = DateTime.now().toString();
  double _triggerY = 0;
  double _startY = 0;
  int _currVideoIndex = 0;
  late String _title;
  late String _introduction;
  late CosTVControls _cosTVControls;
  bool _isReplayVideo = false;
  late Animation<double> _animationPosition;
  late Animation<double> _animationOpacity;
  late AnimationController _controllerClose;
  bool _isAnimationCloseRun = false;
  StreamSubscription? _eventSubscription;
  double _marginBottom = AppDimens.margin_64_5;
  Duration _lastPlayerPosition = Duration.zero;
  Duration _currentPlayerPosition = Duration.zero;
  bool _isCanReportVideoEnd = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _listenEvent();
  }

  void _initData() {
    GetVideoInfoDataBean _getVideoInfoDataBean = widget._bean.listDataItem[0] as GetVideoInfoDataBean;
    _pageFlag = '${_getVideoInfoDataBean.videoId}${DateTime.now().toString()}';
    _controllerProgress = AnimationController(
      vsync: this,
    );
    _controllerClose = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    initAnimationClose();
    _controllerClose.addListener(animationCloseUpdate);
    _controllerClose.addStatusListener(animationCloseStatus);
    _triggerY = AppDimens.item_size_65 / 2;
    _title = _getVideoInfoDataBean.title;
    _introduction = _getVideoInfoDataBean.introduction;
    if (widget._bean != null) {
      if (widget._bean.videoPlayerController != null) {
        _videoPlayerController = widget._bean.videoPlayerController!;
        _initChewieController(false, widget._bean.startAt);
        _videoPlayerController.addListener(videoSmallPlayerChanged);
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) {
            _videoPlayerController.addListener(videoSmallPlayerChanged);
            _videoPlayerController.play();
            setState(() {});
          }
        });
      }
    } else {
      _initVideoPlayers(_getVideoInfoDataBean.videosource);
    }
  }

  void initAnimationClose() {
    _animationPosition = Tween<double>(begin: _marginBottom, end: 0.0).animate(_controllerClose);
    _animationOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(_controllerClose);
  }

  void _listenEvent() {
    if (_eventSubscription == null) {
      _eventSubscription = EventBusHelp.getInstance().on().listen((event) {
        if (event != null && event is VideoSmallShowStatusEvent) {
          if (event.isBottomNavigationBar) {
            if (_marginBottom != AppDimens.margin_64_5) {
              setState(() {
                _marginBottom = AppDimens.margin_64_5;
                initAnimationClose();
              });
            }
          } else {
            if (_marginBottom != AppDimens.margin_15_5) {
              setState(() {
                _marginBottom = AppDimens.margin_15_5;
                initAnimationClose();
              });
            }
          }
        }
      });
    }
  }

  void animationCloseUpdate() {
    setState(() {});
  }

  void animationCloseStatus(status) {
    if (status == AnimationStatus.completed) {
      OverlayVideoSmallWindowsUtils.instance.removeVideoSmallWindow();
    }
  }

  Future<void> _initVideoPlayers(String videoUrl) async {
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    await _videoPlayerController.initialize().then((_) {
      setState(() {
        _initChewieController(true, null);
        _videoPlayerController.addListener(videoSmallPlayerChanged);
      });
    });
  }

  void _initChewieController(bool autoPlay, Duration? startAt) {
    if (_videoPlayerController == null) {
      return;
    }
    _cosTVControls = CosTVControls(_pageFlag, showType: CosTVControls.showTypeSmallWindows, videoPlayEndCallBack: () {
      _handleCurVideoPlayEnd();
    });
    if (startAt == null) {
      startAt = Duration();
    }
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: autoPlay,
      startAt: startAt,
      looping: false,
      showControlsOnInitialize: false,
      allowMuting: false,
      isLive: _videoPlayerController.value.duration == Duration.zero,
      customControls: _cosTVControls,
      materialProgressColors: CosTVControlColor.MaterialProgressColors,
      routePageBuilder: CosTvFullScreenBuilder.of(_videoPlayerController.value.aspectRatio),
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
    );
  }

  void _handleCurVideoPlayEnd() {
    if (_isAnimationCloseRun) {
      return;
    }
    if (usrAutoPlaySetting) {
      _currVideoIndex++;
    }
    if (_currVideoIndex < widget._bean.listDataItem.length) {
      if (usrAutoPlaySetting) {
        if (widget._bean.listDataItem[_currVideoIndex] is GetVideoInfoDataBean) {
          GetVideoInfoDataBean _getVideoInfoDataBean = widget._bean.listDataItem[_currVideoIndex] as GetVideoInfoDataBean;
          replayFristVideo(_getVideoInfoDataBean);
        } else if (widget._bean.listDataItem[_currVideoIndex] is RelateListItemBean) {
          RelateListItemBean bean = widget._bean.listDataItem[_currVideoIndex] as RelateListItemBean;
          _title = bean.title;
          _introduction = bean.introduction;
          final oldPlayerController = _videoPlayerController;
          final oldChewieController = _chewieController;
          oldPlayerController.removeListener(videoSmallPlayerChanged);
          _videoPlayerController.dispose();
          _chewieController.dispose();
          oldPlayerController.pause();
          oldChewieController.pause();
          _initVideoPlayers(bean.videosource);
          Future.delayed(Duration(seconds: 3), () {
            oldPlayerController.dispose();
            if (oldChewieController.isLive){
              oldChewieController.dispose();
            }
          });
        }
      } else {
        _currVideoIndex = 0;
        setState(() {
          _isReplayVideo = true;
        });
      }
    } else {
      _currVideoIndex = 0;
      setState(() {
        _isReplayVideo = true;
      });
    }
  }

  void replayFristVideo(GetVideoInfoDataBean _getVideoInfoDataBean) {
    _title = _getVideoInfoDataBean.title;
    _introduction = _getVideoInfoDataBean.introduction;
    final oldPlayerController = _videoPlayerController;
    final oldChewieController = _chewieController;
    oldPlayerController.removeListener(videoSmallPlayerChanged);
    _videoPlayerController.dispose();
    _chewieController.dispose();
    oldPlayerController.pause();
    oldChewieController.pause();
    _initVideoPlayers(_getVideoInfoDataBean.videosource);
    Future.delayed(Duration(seconds: 3), () {
      oldPlayerController.dispose();
      oldChewieController.dispose();
    });
  }

  /// 重播视频
  Future<void> replayVideo() async {
    if (_currVideoIndex > 0) {
      _currVideoIndex = 0;
      GetVideoInfoDataBean _getVideoInfoDataBean = widget._bean.listDataItem[0] as GetVideoInfoDataBean;
      replayFristVideo(_getVideoInfoDataBean);
    } else {
      await _videoPlayerController.seekTo(Duration(seconds: 0));
      await _videoPlayerController.play();
    }
  }

  String _getVideoId() {
    String vid = '';
    if (widget._bean.getVideoInfoDataBean != null && widget._bean.getVideoInfoDataBean?.id != null) {
      vid = widget._bean.getVideoInfoDataBean!.id;
    } else if (widget._bean.vid != null) {
      vid = widget._bean.vid!;
    }
    return vid;
  }

  String _getUidOfVideo() {
    String uid = '';
    if (widget._bean.getVideoInfoDataBean != null && widget._bean.getVideoInfoDataBean?.uid != null) {
      uid = widget._bean.getVideoInfoDataBean!.uid;
    } else if (widget._bean.uid != null) {
      uid = widget._bean.uid!;
    }
    return uid;
  }

  ///视频停止、切换、播放完成、退到后台时的上报
  void reportVideoEnd(VideoPlayerValue playerValue) {
    num? playTimeProportion =
        NumUtil.getNumByValueDouble(NumUtil.multiply(_currentPlayerPosition.inSeconds / playerValue.duration.inSeconds, 100), 2);
    if (playTimeProportion == null) return;
    DataReportUtil.instance.reportData(
      eventName: "Play_time_proportion",
      params: {
        "play_time_proportion": '$playTimeProportion%',
        "vid": _getVideoId(),
        "uid": _getUidOfVideo(),
      },
    );
    DataReportUtil.instance.reportData(
      eventName: "Play_time",
      params: {
        "play_time_proportion": '${_currentPlayerPosition.inSeconds}',
        "vid": _getVideoId(),
        "uid": _getUidOfVideo(),
      },
    );
    String eventName;
    if (playTimeProportion < 30) {
      eventName = "Play_time_proportion_lessthan30";
    } else if (playTimeProportion >= 30 && playTimeProportion < 50) {
      eventName = "Play_time_proportion_30";
    } else if (playTimeProportion >= 50 && playTimeProportion < 80) {
      eventName = "Play_time_proportion_50";
    } else {
      eventName = "Play_time_proportion_80";
    }
    DataReportUtil.instance.reportData(
      eventName: eventName,
      params: {
        "video_duration": playerValue.duration.inSeconds,
        "vid": _getVideoId(),
        "uid": _getUidOfVideo(),
      },
    );
  }

  void videoSmallPlayerChanged() {
    VideoPlayerValue? playerValue = _videoPlayerController.value;
    if (playerValue == null) {
      return;
    }
    CosLogUtil.log("videoSmallPlayerChanged playerValue = $playerValue");
    // 观看时长埋点
    if (playerValue.isPlaying) {
      if (!_isCanReportVideoEnd) {
        _isCanReportVideoEnd = true;
      }
      if (mounted) {
        setState(() {
          double timeValue = playerValue.position.inSeconds / playerValue.duration.inSeconds;
          CosLogUtil.log("videoPlayerChanged timeValue = $timeValue");
          _controllerProgress.value = timeValue;
        });
      }
      if (_currentPlayerPosition != playerValue.position) {
        _lastPlayerPosition = _currentPlayerPosition;
        _currentPlayerPosition = playerValue.position;

        if (_currentPlayerPosition.inSeconds >= 1 && _lastPlayerPosition.inSeconds < 1) {
          if (widget._bean.isVideoDetailsInit) {
            widget._bean.isVideoDetailsInit = false;
          } else {
            DataReportUtil.instance.reportData(
              eventName: "Video_play",
              params: {
                "vid": _getVideoId(),
                "topic_class": widget._bean.getVideoInfoDataBean?.topicClass ?? '',
                "type": widget._bean.getVideoInfoDataBean?.type ?? '',
              },
            );
          }
        }

        if (playerValue.duration > Duration.zero) {
          Duration threshold = playerValue.duration * 0.9;
          if (_currentPlayerPosition >= threshold && _lastPlayerPosition < threshold) {
            DataReportUtil.instance.reportData(
              eventName: "Video_done",
              params: {
                "vid": _getVideoId(),
                "watchtime": _currentPlayerPosition.inSeconds,
              },
            );
          }
        }
        if (_currentPlayerPosition.inSeconds == playerValue.duration.inSeconds && _isCanReportVideoEnd) {
          _isCanReportVideoEnd = false;
          reportVideoEnd(playerValue);
        }
      }
    } else {
      CosLogUtil.log("videoSmallPlayerChanged _isReplayVideo = $_isReplayVideo");
      CosLogUtil.log("videoSmallPlayerChanged _controllerProgress.value = ${_controllerProgress.value}");
      CosLogUtil.log("videoSmallPlayerChanged mounted = $mounted");
      if (_isReplayVideo && _controllerProgress.value < 1.0 && mounted) {
        setState(() {
          _controllerProgress.value = 1.0;
        });
      }
      if (_isCanReportVideoEnd) {
        _isCanReportVideoEnd = false;
        reportVideoEnd(playerValue);
      }
    }
  }

  @override
  void dispose() {
    if (_eventSubscription != null) {
      _eventSubscription?.cancel();
      _eventSubscription = null;
    }
    clearVideoPlayerController();
    _chewieController.dispose();
    _controllerProgress.dispose();
    _controllerClose.removeListener(animationCloseUpdate);
    _controllerClose.removeStatusListener(animationCloseStatus);
    _controllerClose.dispose();
    super.dispose();
  }

  void clearVideoPlayerController() {
    _videoPlayerController.pause();
    _videoPlayerController.removeListener(videoSmallPlayerChanged);
    _videoPlayerController.dispose();
  }

  /// 跳转到视频详情页
  void jumpVideoDetails(BuildContext context) {
    late String videoId;
    late String uid;
    late String videoSource;
    if (_currVideoIndex < widget._bean.listDataItem.length) {
      if (widget._bean.listDataItem[_currVideoIndex] is GetVideoInfoDataBean) {
        GetVideoInfoDataBean? _getVideoInfoDataBean = widget._bean.listDataItem[_currVideoIndex] as GetVideoInfoDataBean?;
        if (_getVideoInfoDataBean != null) {
          videoId = _getVideoInfoDataBean.id;
          uid = _getVideoInfoDataBean.uid;
          videoSource = _getVideoInfoDataBean.videosource;
        }
      } else if (widget._bean.listDataItem[_currVideoIndex] is RelateListItemBean) {
        RelateListItemBean? bean = widget._bean.listDataItem[_currVideoIndex] as RelateListItemBean?;
        if (bean != null) {
          videoId = bean.videoId;
          uid = bean.introduction;
          videoSource = bean.videosource;
        }
      }
    } else {
      GetVideoInfoDataBean? _getVideoInfoDataBean = widget._bean.listDataItem[0] as GetVideoInfoDataBean?;
      if (_getVideoInfoDataBean != null) {
        videoId = _getVideoInfoDataBean.id;
        uid = _getVideoInfoDataBean.uid;
        videoSource = _getVideoInfoDataBean.videosource;
      }
    }
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
          fromType: VideoDetailPageParamsBean.fromTypeVideoSmallWindows,
          isVideoSmallInit: true,
          vid: videoId,
          uid: uid,
          videoSource: videoSource,
          enterSource: VideoDetailsEnterSource.VideoDetailsEnterSourceVideoSmallWindows,
          videoSmallWindowsBean: widget._bean,
        ));
      },
      settings: RouteSettings(name: videoDetailPageRouteName),
      animationType: SlideAnimationRoute.animationTypeVertical,
    ));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width - AppDimens.margin_20;
    double videoWidth = AppDimens.item_size_65 * 16 / 9;
    bool isPlaying = _videoPlayerController.value.isPlaying;
    String imgPlayUrl;
    if (isPlaying) {
      imgPlayUrl = AppThemeUtil.getSmallWindowVideoStop();
    } else {
      if (_isReplayVideo) {
        imgPlayUrl = AppThemeUtil.getSmallWindowVideoReplay();
      } else {
        imgPlayUrl = AppThemeUtil.getSmallWindowVideoPlay();
      }
    }
    return Positioned(
        bottom: _animationPosition.value,
        child: Opacity(
          opacity: _animationOpacity.value,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_isAnimationCloseRun) {
                jumpVideoDetails(context);
                _isAnimationCloseRun = true;
                _videoPlayerController.pause();
                _videoPlayerController.removeListener(videoSmallPlayerChanged);
                _controllerClose.forward();
              }
            },
            onVerticalDragStart: (DragStartDetails details) {
              _startY = details.globalPosition.dy;
            },
            onVerticalDragUpdate: (DragUpdateDetails details) {
              double endY = details.globalPosition.dy;
              double moveY = endY - _startY;
              if (moveY > 0 && moveY >= _triggerY && !_isAnimationCloseRun) {
                _isAnimationCloseRun = true;
                _videoPlayerController.pause();
                _videoPlayerController.removeListener(videoSmallPlayerChanged);
                _controllerClose.forward();
              } else {
                if (moveY.abs() >= _triggerY && !_isAnimationCloseRun) {
                  jumpVideoDetails(context);
                  _isAnimationCloseRun = true;
                  _videoPlayerController.pause();
                  _videoPlayerController.removeListener(videoSmallPlayerChanged);
                  _controllerClose.forward();
                }
              }
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: AppDimens.margin_10),
              width: width,
              height: AppDimens.item_size_65,
              decoration: BoxDecoration(
                color: AppThemeUtil.setDifferentModeColor(
                  lightColor: AppColors.color_e6ffffff,
                  darkColor: AppColors.color_e63e3e3e,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.30),
                    offset: Offset(0, 1),
                    blurRadius: 7,
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: videoWidth,
                        height: AppDimens.item_size_65,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color.fromRGBO(84, 84, 84, 1.0), Colors.black],
                          ),
                        ),
                        child: (_chewieController != null)
                            ? ClipRect(
                                child: Chewie(
                                controller: _chewieController,
                              ))
                            : Center(
                                child: Theme(
                                data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.white)),
                                child: CircularProgressIndicator(),
                              )),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: AppDimens.margin_7),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _title,
                                style: TextStyle(
                                    color: AppThemeUtil.setDifferentModeColor(
                                      lightColor: AppColors.color_333333,
                                      darkColor: AppColors.color_d6d6d6,
                                    ),
                                    fontSize: AppDimens.text_size_11,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                margin: EdgeInsets.only(top: AppDimens.margin_5),
                                child: Text(
                                  _introduction,
                                  style: TextStyle(
                                      color: AppThemeUtil.setDifferentModeColor(
                                        lightColor: AppColors.color_858585,
                                        darkColor: AppColors.color_ebebeb,
                                      ),
                                      fontSize: AppDimens.text_size_11,
                                      decoration: TextDecoration.none),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            if (_videoPlayerController.value.isPlaying) {
                              _videoPlayerController.pause();
                            } else {
                              if (_isReplayVideo) {
                                replayVideo();
                                _isReplayVideo = false;
                              } else {
                                _videoPlayerController.play();
                              }
                            }
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: AppDimens.margin_15),
                          child: Image.asset(imgPlayUrl),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (Common.isAbleClick() && !_isAnimationCloseRun) {
                            _isAnimationCloseRun = true;
                            _videoPlayerController.pause();
                            _videoPlayerController.removeListener(videoSmallPlayerChanged);
                            _controllerClose.forward();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(AppDimens.margin_15),
                          margin: EdgeInsets.only(left: AppDimens.margin_10),
                          child: Image.asset(AppThemeUtil.getSmallWindowVideoClose()),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    width: width,
                    height: AppDimens.item_size_2,
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.color_transparent,
                      value: _controllerProgress.value,
                      valueColor: ColorTween(begin: AppColors.color_3674ff, end: AppColors.color_3674ff).animate(_controllerProgress),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
