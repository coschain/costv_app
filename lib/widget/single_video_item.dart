import 'package:cached_network_image/cached_network_image.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/widget/video_time_widget.dart';
import 'package:costv_android/widget/video_worth_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cosdart/types.dart';
import 'package:costv_android/pages/user/others_home_page.dart';
import 'package:costv_android/utils/video_report_util.dart';

enum EnterSource {
  HomePage,
  HotPage,
  SubscribePage,
  OtherCenter,
  HotDetail,
}

typedef ClickPlayVideoCallBack = Function (GetVideoListNewDataListBean video);

class SingleVideoItem extends StatefulWidget {
  final GetVideoListNewDataListBean videoData;
  final ExchangeRateInfoData exchangeRate;//汇率
  final dynamic_properties dgpoBean;
  final int index;
  final ClickPlayVideoCallBack playVideoCallBack;
  final EnterSource source;
  SingleVideoItem({
    Key key,
    this.videoData,
    this.exchangeRate,
    this.dgpoBean,
    this.index,
    this.playVideoCallBack,
    this.source,
    }):super(key: key);
  @override
  State<StatefulWidget> createState() {
    return SingleVideoItemState();
  }
}

class SingleVideoItemState extends State<SingleVideoItem> with WidgetsBindingObserver{
//  IjkMediaController _mediaController;
//  Stream<IjkStatus> _ijkStatusStream;
//  bool isPlaying = false;
//  bool isPlayWhenEnterBack;
//  @override
//  void didChangeAppLifecycleState(AppLifecycleState state) {
//    super.didChangeAppLifecycleState(state);
//    if (state == AppLifecycleState.paused) {
//      //后台
//      if (_mediaController != null && _mediaController.isPlaying) {
//        _mediaController.pause();
//        isPlayWhenEnterBack = true;
//      } else {
//        isPlayWhenEnterBack = false;
//      }
//    } else if (state == AppLifecycleState.resumed) {
//      //前台
//      if (isPlayWhenEnterBack) {
//        _mediaController.play();
//        isPlayWhenEnterBack = false;
//      }
//    }
//  }

  @override
  void dispose() {
    super.dispose();
//    if (_mediaController != null) {
//         _mediaController.stop();
//        _mediaController.dispose();
//        _mediaController.isPlaying = false;
//    }

//    WidgetsBinding.instance.removeObserver(this);
  }

//  @override
//  void didUpdateWidget(SingleVideoItem oldWidget) {
//    super.didUpdateWidget(oldWidget);
//    if (widget.videoData?.id != null && Common.checkIsNotEmptyStr(widget.videoData.id)) {
//      if (oldWidget.videoData?.id != null
//          && Common.checkIsNotEmptyStr(oldWidget.videoData.id)
//          && widget.videoData.id != oldWidget.videoData.id) {
//        resetMediaController();
//      }
//    }
//    WidgetsBinding.instance.removeObserver(this);
//    WidgetsBinding.instance.addObserver(this);
//  }


  @override
  void initState() {
    super.initState();
//    _initMediaController();
//    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    double itemWidth = MediaQuery.of(context).size.width;
    double imgRatio = 190/355, avatarSize = 33.0, descMargin = 8.0;
    double imgHeight = imgRatio * itemWidth;
    double descWidth = itemWidth - 20 - avatarSize - descMargin, descBgHeight = 88;
    double worthWidth = descWidth * 0.4;
    double calcWidth = _calcVideoWorthWidth();
    //优先显示视频价值
    if (calcWidth >= descWidth*0.8) {
      worthWidth = descWidth*0.8;
    } else {
      worthWidth = calcWidth + 5;
    }
    double authorBgWidth = descWidth - worthWidth -5;
    return Container(
      width: itemWidth,
      child: Column(
        children: <Widget>[
          //video cover
          Container(
//            color: Common.getColorFromHexString("D6D6D6", 1.0),
            color: Common.getColorFromHexString("FFFFFF", 1.0),
            padding: EdgeInsets.symmetric(horizontal: 10),
            width: itemWidth,
            height: imgHeight,
            child: GestureDetector(
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
                      placeholder: (BuildContext context, String url){
                        return Container();
                      },
                      imageUrl: widget.videoData?.videoCoverBig ?? "",
                      errorWidget: (context, url, error) => Container(
                      ),
                    ),
                  ),

                  _getVideoDurationWidget(),
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
          ),
          // video desc
          Container(
            width: itemWidth,
//            height: descBgHeight,
            padding: EdgeInsets.fromLTRB(10, 13, 10, 13),
            color: Common.getColorFromHexString("FFFFFF", 1.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              //author avatar
              children: <Widget>[
                InkWell(
                  onTap: () {
                    _onClickAvatar();
                  },
                  child: ClipOval(
                      child: SizedBox(
                        width: avatarSize,
                        height: avatarSize,
                        child: CachedNetworkImage(
                          placeholder: (context,url) {
                            return Image.asset('assets/images/ic_default_avatar.png');
                          },
                          imageUrl: widget.videoData?.anchorAvatar ?? "",
                          fit: BoxFit.cover,
                        ),
                      )
                  ),
                ),
                // title 、 watch number 、 author 、date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    //title
                    Container(
                      width: descWidth,
                      margin: EdgeInsets.fromLTRB(descMargin, 0, 0, 0),
                      child: Text(
                        widget.videoData?.title ?? "",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 13,
                          color: Common.getColorFromHexString("333333", 1.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // author · watch number · date
                    Container(
                      width: descWidth,
                      margin: EdgeInsets.fromLTRB(descMargin, 2, 0, 0),
                      child:  Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: authorBgWidth,
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(top: 2),
                                  constraints: BoxConstraints(
                                    maxWidth: authorBgWidth / 2,
                                  ),
                                  child:  Text (
                                    _formatAuthor() ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      textBaseline: TextBaseline.alphabetic,
                                      color: Common.getColorFromHexString("858585", 1.0),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: authorBgWidth / 2,
                                  ),
                                  child:  Text (
                                    _formatWatchNumber() ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Common.getColorFromHexString("858585", 1.0),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
//                                Container(
//                                  constraints: BoxConstraints(
//                                    maxWidth: authorBgWidth / 3,
//                                  ),
//                                  child:  Text (
//                                    _formatCreateTimeDesc() ?? "",
//                                    maxLines: 1,
//                                    overflow: TextOverflow.ellipsis,
//                                    style: TextStyle(
//                                      color: Common.getColorFromHexString("858585", 1.0),
//                                      fontSize: 11,
//                                    ),
//                                  ),
//                                ),
                              ],
                            ),
                          ),
                          //author
                          //视频价值
                          Container(
                            constraints: BoxConstraints(
                                maxWidth: worthWidth
                            ),
                            child: VideoWorthWidget(_getCurrencySymbol(), _calcVideoWorth()),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

//  Future<void> resetMediaController() async {
//    if (_mediaController != null) {
//      _mediaController.reset(true);
//    }
//  }
//
//  Future<void> startPlay() async {
//    isPlaying = true;
//    if (_mediaController != null && (!_mediaController.isPlaying || _mediaController.ijkStatus != IjkStatus.playing)) {
//      VideoInfo info = await _mediaController.getVideoInfo();
//      if (info.hasData && info.currentPosition > 0) {
//        _mediaController.play(pauseOther: true);
//      } else {
//        await _mediaController.pauseOtherController();
//        _mediaController.setNetworkDataSource(
//            widget.videoData?.videosource ?? '', autoPlay: true);
//      }
//      _mediaController.isPlaying = true;
//
//    }
//  }
//
//  Future<void> stopPlay(bool isRestart) async {
//    isPlaying = false;
//    if (_mediaController != null) {
//      await _mediaController.pause();
//      _mediaController.isPlaying = false;
//      if (isRestart) {
//        await _mediaController.seekTo(0);
//      }
//    }
//  }

  //计算视频价值文字的宽度
  double _calcVideoWorthWidth() {
    TextStyle style = TextStyle(fontSize: 12.5,color: Common.getColorFromHexString("D19900", 1.0));
    //使用MediaQuery.of(context).textScaleFactor,避免不同机型计算的宽度不够
    TextPainter painter = TextPainter(
        maxLines: 1,
        textScaleFactor: MediaQuery.of(context).textScaleFactor,
        textDirection: TextDirection.ltr,
    );
    String text = _getCurrencySymbol() + " " + _calcVideoWorth();
    painter.text = TextSpan(text: text, style: style);
    painter.layout();
    double width =  painter.width.roundToDouble() + 12;
    return width;
  }

//  void _initMediaController() {
//    if (_mediaController == null) {
//      _mediaController = IjkMediaController(needChangeSpeed: false);
//      IjkOption op1 = IjkOption(IjkOptionCategory.player, "start-on-prepared",1);
//      IjkOption op2 = IjkOption(IjkOptionCategory.format, "http-detect-range-support",0);
//      IjkOption op3 = IjkOption(IjkOptionCategory.codec, "skip_loop_filter",48);
//      IjkOption op4 = IjkOption(IjkOptionCategory.format, "probesize", 1024);
//      IjkOption op5 = IjkOption(IjkOptionCategory.player, "framedrop",1);
//      IjkOption op6 =  IjkOption(IjkOptionCategory.player, "mediacodec", 0);
//      IjkOption op7 =  IjkOption(IjkOptionCategory.player, "loop", 0);//循环播放
//      Iterable<IjkOption>  opList = [op1,op2,op3,op4,op5,op6,op7];
//      _mediaController.setIjkPlayerOptions([TargetPlatform.android, TargetPlatform.iOS], opList);
//      _ijkStatusStream = _mediaController.ijkStatusStream;
//      _ijkStatusStream.listen((status) {
//        if (status == IjkStatus.prepared || status == IjkStatus.playing) {
//          _mediaController.refreshVideoInfo();
//        }
//      });
//    }
//  }

//  Widget _getPlayer(double imgHeight, double itemWidth) {
//    _initMediaController();
//    return Container(
//      height: imgHeight,
//      width: itemWidth,
//      child:  IjkPlayer(
//        mediaController: _mediaController,
//        controllerWidgetBuilder: (mediaController){
//          return Container();
//
//        },
//        statusWidgetBuilder: (
//            BuildContext context,
//            IjkMediaController controller,
//            IjkStatus status,
//        ){
//          if (!controller.isPlaying) {
//            return Stack(
//              alignment: AlignmentDirectional.center,
//              children: <Widget>[
//                Container(
//                  width: itemWidth,
//                  height: imgHeight,
//                  color: Common.getColorFromHexString("D6D6D6", 1.0),
//                  child: CachedNetworkImage(
//                    fit: BoxFit.contain,
//                    placeholder: (BuildContext context, String url){
//                      return Container();
//                    },
//                    imageUrl: widget.videoData?.videoCoverBig ?? "",
//                  ),
//                ),
//
//                _getVideoDurationWidget(),
//              ],
//            );
//          }
//          return IjkStatusWidget.buildStatusWidget(context, controller, status);
//        },
//      ),
//    );
//  }

  Widget _getVideoDurationWidget() {
    if (Common.checkVideoDurationValid(widget.videoData?.duration)) {
      return Positioned(
        right: 5,
        bottom: 5,
        child: VideoTimeWidget(Common.formatVideoDuration(widget.videoData?.duration)),
      );
    }
    return Container();
  }

  String _getCurrencySymbol() {
    return Common.getCurrencySymbolByLanguage();
  }

  String _formatAuthor() {
    String desc  = "";
    if (Common.checkIsNotEmptyStr(widget.videoData?.anchorNickname)) {
      desc +=  widget.videoData.anchorNickname + " ";
    }
    return desc;
  }

  String _formatWatchNumber() {
    String desc  = "";
    if (Common.checkIsNotEmptyStr(widget.videoData?.watchNum)) {
      if (_formatAuthor().length > 0) {
        desc += "· ";
      }
      desc += '${InternationalLocalizations.watchNumberDesc(widget.videoData.watchNum)} ';
    }
    return desc;
  }

  String _formatCreateTimeDesc() {
    String desc  = "";
    if (Common.checkIsNotEmptyStr(widget.videoData?.createdAt)) {
      if (_formatAuthor().length > 0 || _formatWatchNumber().length > 0) {
        desc += "· ";
      }
      desc += Common.calcDiffTimeByStartTime(widget.videoData.createdAt);
    }
    return desc;
  }

  void _onClickToPlayVideo(String vid,String uid, String videoSource) {
    _reportVideoClick();
    if (!Common.checkIsNotEmptyStr(vid)) {
      CosLogUtil.log("SingleVideoItem: fail to jumtp to video detail page "
          "due to empty vid");
      return;
    }

//    if (!Common.checkIsNotEmptyStr(uid)) {
//      CosLogUtil.log("SingleVideoItem: fail to jumtp to video detail page"
//          "due to empty uid");
//      return;
//    }
//    stopPlay(false);
    if (widget.playVideoCallBack != null) {
      widget.playVideoCallBack(widget.videoData);
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return VideoDetailsPage(VideoDetailPageParamsBean.createInstance(
          vid: vid,
          uid: uid,
          videoSource: videoSource
      ));
    }));

  }

  void _onClickAvatar() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return OthersHomePage(OtherHomeParamsBean(
        uid: widget.videoData?.uid ?? "",
        nickName: widget.videoData?.anchorNickname ?? '',
        avatar: widget.videoData?.anchorAvatar ?? '',
        rateInfoData: widget.exchangeRate,
        dgpoBean: widget.dgpoBean,
      ));
    }));
  }

  ///计算视频收益
  String _calcVideoWorth() {
    return VideoUtil.getVideoWorth(
        widget.exchangeRate, widget.dgpoBean, widget.videoData);
  }

  void _reportVideoClick() {
    if (widget?.videoData?.id != null) {
      if (widget.source == EnterSource.HomePage) {
        VideoReportUtil.reportClickVideo(ClickVideoSource.HomePage, widget.videoData?.id);
      } else if (widget.source == EnterSource.HotPage) {
        VideoReportUtil.reportClickVideo(ClickVideoSource.Hot, widget.videoData?.id);
      } else if (widget.source == EnterSource.SubscribePage) {
        VideoReportUtil.reportClickVideo(ClickVideoSource.Subscribe, widget.videoData?.id);
      } else if (widget.source == EnterSource.OtherCenter) {
        VideoReportUtil.reportClickVideo(ClickVideoSource.OtherCenter, widget.videoData?.id);
      } else if (widget.source == EnterSource.HotDetail) {
        VideoReportUtil.reportClickVideo(ClickVideoSource.HotTopic, widget.videoData?.id);
      }
    }
  }


}
