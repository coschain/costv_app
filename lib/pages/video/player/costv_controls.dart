import 'dart:async';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/video_detail_data_change_event.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/data_report_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/auto_play_recommend_video_item.dart';
import 'package:costv_android/widget/refresh_recommend_video_widget.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/pages/video/player/costv_video_progress_bar.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/bean/get_video_info_bean.dart';
import 'package:costv_android/bean/relate_list_bean.dart';
import "package:costv_android/utils/video_detail_data_manager.dart";
import 'package:costv_android/pages/video/auto_play/auto_play_progress_bar.dart';
import "package:costv_android/widget/recommend_default_video_item.dart";
import 'package:costv_android/pages/user/others_home_page.dart';
import 'package:costv_android/bean/get_video_list_new_bean.dart';

typedef PlayNextVideoCallBack = Function();
typedef VideoPlayEndCallBack = Function();
typedef RefreshRecommendVideoCallBack = Function();
typedef HandelFollowCallBack = Function();
typedef PlayCreatorRecommendVideoCallBack = Function(
    GetVideoListNewDataListBean videoInfo);
typedef FetchFollowingRecommendVideoCallBack = Function();
typedef PlayPreVideoCallBack = Function();
typedef ClickZoomOutCallBack = Function();

class CosTVControls extends StatefulWidget {
  static const int showTypeNormal = 1;
  static const int showTypeSmallWindows = 2;
  CosTVControlsState cosTVControlsState;
  final String controlsKey;
  final PlayNextVideoCallBack playNextVideoCallBack;
  final VideoPlayEndCallBack videoPlayEndCallBack;
  final RefreshRecommendVideoCallBack refreshRecommendVideoCallBack;
  final ClickRecommendVideoCallBack clickRecommendVideoCallBack;
  final HandelFollowCallBack handelFollowCallBack;
  final FetchFollowingRecommendVideoCallBack
  fetchFollowingRecommendVideoCallBack;
  final PlayCreatorRecommendVideoCallBack playCreatorRecommendVideoCallBack;
  final PlayPreVideoCallBack playPreVideoCallBack;
  final ClickZoomOutCallBack clickZoomOutCallBack;
  final int showType;

  CosTVControls(this.controlsKey, {
    Key key,
    this.playNextVideoCallBack,
    this.videoPlayEndCallBack,
    this.refreshRecommendVideoCallBack,
    this.clickRecommendVideoCallBack,
    this.handelFollowCallBack,
    this.fetchFollowingRecommendVideoCallBack,
    this.playCreatorRecommendVideoCallBack,
    this.playPreVideoCallBack,
    this.clickZoomOutCallBack,
    this.showType = showTypeNormal,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    cosTVControlsState = CosTVControlsState();
    return cosTVControlsState;
  }
}

class CosTVControlsState extends State<CosTVControls> {
  VideoPlayerValue _latestValue;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  bool _isPlayEnd = false;
  bool _isReplayStatus = false;
  StreamSubscription _eventControls;
  Timer _countDownTimer;

  VideoPlayerController controller;
  ChewieController chewieController;
  bool _showDefaultProgress = true;
  bool _isAnimateDefaultProgress = false;

  @override
  void initState() {
    _listenEvent();
    _isReplayStatus =
        VideoDetailDataMgr.instance.getIsReplayStatusByKey(widget.controlsKey);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue != null && _latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
        context,
        chewieController.videoPlayerController.value.errorDescription,
      )
          : Center(
        child: Icon(
          Icons.error,
          color: Colors.white,
          size: 42,
        ),
      );
    }
    if (widget.showType == CosTVControls.showTypeSmallWindows) {
      return _buildControlsWidget();
    } else {
      return MouseRegion(
        onHover: (_) {
          _cancelAndRestartTimer();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _cancelAndRestartTimer(),
          child: _buildControlsWidget(),
        ),
      );
    }
  }

  Widget _buildControlsWidget() {
    bool isLoad =
    VideoDetailDataMgr.instance.getLoadStatuesByKey(widget.controlsKey);
    if (_isPlayEnd && !isLoad) {
      if (widget.showType == CosTVControls.showTypeSmallWindows) {
        return Container(
          color: AppColors.color_transparent,
        );
      } else {
        return _buildPlayEndWidget();
      }
    } else if (isLoad) {
      return _buildFullScreenLoadingWidget();
    }
    if (widget.showType == CosTVControls.showTypeSmallWindows) {
      return Container();
    } else {
      return _buildPlayStatusView();
    }
  }

  ///播放未结束时的widget
  Widget _buildPlayStatusView() {
    return AbsorbPointer(
      absorbing: _hideStuff,
      child: Column(
        children: <Widget>[
          _buildFullScreenCurrentVideoTitle(),
          _buildHitArea(),
          _buildBottomParts(context),
        ],
      ),
    );
  }

  Widget _buildPlayStatusLoading() {
    if (!_checkIsShowPlayStatusLoading()) {
      return Container();
    }
    double boxSize = _judgeIsFullScreen() ? 30 : 24;
    return IgnorePointer(
      ignoring: true,
      child: SizedBox(
        width: boxSize,
        height: boxSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildPortraitPrevAndNextParts() {
    return AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
//          margin: EdgeInsets.only(top: 30 * _fullscreenFactor(2)),
          child: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                //上一个视频按钮
                _buildPlayPrevIcn(),
                //暂停播放按钮
                !_checkIsShowPlayStatusLoading()
                    ? _buildPlayPause(controller)
                    : _buildPlayStatusLoading(),
                //下一个视频按钮
                _buildPlayNextIcn()
              ],
            ),
          ),
        ));
  }

  Widget _buildFullScreenCurrentVideoTitle() {
    String title = VideoDetailDataMgr.instance
        .getCurrentVideoInfoByKey(widget.controlsKey)
        ?.title;
    if (_judgeIsFullScreen()) {
      return AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          width: MediaQuery
              .of(context)
              .size
              .width - 40,
          margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: Text(
            title ?? "",
            style: TextStyle(
              fontSize: 15,
              color: Common.getColorFromHexString("FFFFFFFF", 1.0),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        _handleClickZoomOut();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: EdgeInsets.only(
              left: AppDimens.margin_10,
              top: AppDimens.margin_16,
              right: AppDimens.margin_10,
              bottom: AppDimens.margin_10,
            ),
            child: _playerImage("zoom_out"),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenPrevAndNextParts() {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        child: Center(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              //上一个视频按钮
              _buildPlayPrevIcn(),
              Container(
                margin: EdgeInsets.only(left: 110),
                child: !_checkIsShowPlayStatusLoading()
                    ? _buildPlayPause(controller)
                    : _buildPlayStatusLoading(),
              ),
              Container(
                margin: EdgeInsets.only(left: 110),
                child: _buildPlayNextIcn(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPrevIcn() {
    bool hasPreVideo =
    VideoDetailDataMgr.instance.getHasPreVideo(widget.controlsKey);
    String icnPath = "assets/images/icn_video_prev.png";
    if (!hasPreVideo) {
      icnPath = "assets/images/icn_video_prev_unable.png";
    }
    return IgnorePointer(
      ignoring: !hasPreVideo,
      child: InkWell(
        child: Container(
          child: Image.asset(
            icnPath,
            fit: BoxFit.contain,
          ),
        ),
        onTap: () {
          _handlePlayPrevVideo();
        },
      ),
    );
  }

  Widget _buildPlayNextIcn() {
    bool hasNextVideo = VideoDetailDataMgr.instance
        .checkHasRecommendVideoByKey(widget.controlsKey);
    String icnPath = "assets/images/icn_video_next.png";
    if (!hasNextVideo) {
      icnPath = "assets/images/icn_video_next_unable.png";
    }
    return IgnorePointer(
      ignoring: !hasNextVideo,
      child: InkWell(
        child: Container(
          child: Image.asset(
            icnPath,
            fit: BoxFit.contain,
          ),
        ),
        onTap: () {
          _handlePlayNextVideo();
        },
      ),
    );
  }

  Widget _buildBottomParts(BuildContext context) {
    if (!_judgeIsFullScreen() &&
        (_showDefaultProgress || _isAnimateDefaultProgress)) {
      return _buildDefaultProgress();
    }
    return _buildBottomBar(context);
  }

  ///横屏下切换视频时数据加载的loading
  Widget _buildFullScreenLoadingWidget() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(84, 84, 84, 1.0), Colors.black],
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(accentColor: Colors.white),
        child: CircularProgressIndicator(),
      ),
    );
  }

  ///自动播放widget
  Widget _buildPlayEndWidget() {
    return Container(
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
      child: Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[
          _buildVideoCover(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Common.getColorFromHexString("545454", 0.5),
                  Common.getColorFromHexString("000000", 0.9),
                ],
              ),
            ),
            child: _buildPlayEndDetailWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayEndDetailWidget() {
    if (!usrAutoPlaySetting ||
        _isReplayStatus ||
        !VideoDetailDataMgr.instance
            .checkHasRecommendVideoByKey(widget.controlsKey)) {
      if (!_judgeIsFullScreen()) {
        //竖屏推荐
        return _buildPortraitRecommendWidget();
      }
      //横屏推荐
      return _buildFullScreenRecommendWidget();
    }
    return _buildAutoPlayWidget();
  }

  Widget _buildAutoPlayWidget() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          //当前视频标题
          _buildCurrentVideoTitle(),
          //下一个视频的信息
          _buildAutoPlayDetail(),
          //播放进度条
          _buildBottomBar(context),
        ],
      ),
    );
  }

  ///竖屏推荐部分(重播+推荐列表+进度条)
  Widget _buildPortraitRecommendWidget() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          //重播
          Container(
            margin: EdgeInsets.fromLTRB(0, 15, 25, 0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                _buildNewReplayWidget(),
              ],
            ),
          ),

          //推荐视频列表
          _buildPortraitRecommendParts(),

          //进度条等
          _buildBottomBar(context),
        ],
      ),
    );
  }

  ///竖屏推荐列表部分
  Widget _buildPortraitRecommendParts() {
    bool hasRecommendVideo = VideoDetailDataMgr.instance
        .checkHasRecommendVideoByKey(widget.controlsKey);
    //推荐数据
    if (hasRecommendVideo) {
      return Expanded(
        child: Container(
          margin: EdgeInsets.only(top: 8),
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _getRecommendVideoListCount(true),
            itemBuilder: (BuildContext context, int index) {
              return _getRecommendVideoItemByIndex(index);
            },
          ),
        ),
      );
    }
    //没有推荐数据,显示默认列表
    return Container(
        margin: EdgeInsets.only(top: 8),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            //默认item
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RecommendDefaultVideoItem(
                  rightPadding: 21,
                ),
                RecommendDefaultVideoItem(
                  rightPadding: 0,
                ),
              ],
            ),

            //刷新按钮
            Positioned(
              top: 31,
              child: RefreshRecommendVideoWidget(
                maxWidth: min(MediaQuery
                    .of(context)
                    .size
                    .width,
                    MediaQuery
                        .of(context)
                        .size
                        .height),
                refreshRecommendVideoCallBack: () {
                  if (widget.refreshRecommendVideoCallBack != null) {
                    widget.refreshRecommendVideoCallBack();
                  }
                },
              ),
            ),
          ],
        ));
  }

  ///横屏推荐部分(重播+推荐列表+进度条)
  Widget _buildFullScreenRecommendWidget() {
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    return Stack(
      children: <Widget>[
        Container(
          height: screenHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              //创作者信息
              _buildCreatorParts(),
              _buildFullScreenRecommendBottom()
            ],
          ),
        ),

        //重播
        _buildFullScreenReplay(),
        _buildFollowLoading(),
      ],
    );
  }

  Widget _buildFollowLoading() {
    if (VideoDetailDataMgr.instance
        .getIsHandelRequestStatusByKey(widget.controlsKey)) {
      return Align(
        alignment: FractionalOffset.center,
        child: Theme(
          data: Theme.of(context).copyWith(accentColor: Colors.white),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Container();
  }

  ///横屏重播
  Widget _buildFullScreenReplay() {
    if (_judgeIsShowFullScreenReplay()) {
      return Positioned(
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 15, 25, 0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              _buildNewReplayWidget(),
            ],
          ),
        ),
      );
    }
    return Container();
  }

  ///横屏推荐列表
  Widget _buildFullScreenRecommendParts() {
    bool hasRecommendVideo = VideoDetailDataMgr.instance
        .checkHasRecommendVideoByKey(widget.controlsKey);
    //推荐数据
    if (hasRecommendVideo) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: 130,
        ),
        margin: EdgeInsets.only(bottom: 15),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: AlwaysScrollableScrollPhysics(),
          itemCount: _getRecommendVideoListCount(false),
          itemBuilder: (BuildContext context, int index) {
            return _getRecommendVideoItemByIndex(index);
          },
        ),
      );
    }

    double lrSpace = _getFullScreenLRSpace();
    double screenWith = _getFullScreenWidth() - 2 * lrSpace;
    //默认列表
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //加载失败文案、刷新按钮
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              //加载失败文案
              Container(
                constraints: BoxConstraints(maxWidth: screenWith / 2),
                margin: EdgeInsets.only(left: lrSpace),
                child: Text(
                  InternationalLocalizations.loadFail,
                  style: TextStyle(
                    color: Common.getColorFromHexString("D6D6D6 ", 1),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              //刷新按钮
              Container(
                constraints: BoxConstraints(maxWidth: screenWith / 2),
                margin: EdgeInsets.only(left: 20),
                child: RefreshRecommendVideoWidget(
                  maxWidth: screenWith / 2,
                  isPortrait: false,
                  refreshRecommendVideoCallBack: () {
                    VideoDetailDataMgr.instance
                        .updateIsHandelRequestStatusByKey(
                        widget.controlsKey, true);
                    setState(() {});
                    if (widget.refreshRecommendVideoCallBack != null) {
                      widget.refreshRecommendVideoCallBack();
                    }
                  },
                ),
              ),
            ],
          ),
          Container(
            constraints: BoxConstraints(
              maxHeight: 120,
            ),
            margin: EdgeInsets.fromLTRB(0, 15, 0, 20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: 10,
              itemBuilder: (BuildContext context, int index) {
                double leftMargin = 0;
                if (index == 0) {
                  leftMargin = lrSpace;
                }
                return RecommendDefaultVideoItem(
                  leftMargin: leftMargin,
                  rightPadding: 15,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenRecommendBottom() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildFullScreenRecommendParts(),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  ///当前视频创作者信息部分
  Widget _buildCreatorParts() {
    double lrSpace = _getFullScreenLRSpace();
    return Container(
      margin: EdgeInsets.fromLTRB(lrSpace, 29, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _buildUserInfoWidget(),
          //创作者的推荐视频
          _buildCreatorRecommendVideoInfoWidget(),
        ],
      ),
    );
  }

  ///创作者具体信息
  Widget _buildUserInfoWidget() {
    String pageKey = widget.controlsKey;
    GetVideoInfoDataBean videoInfo =
    VideoDetailDataMgr.instance.getCurrentVideoInfoByKey(pageKey);
    String nickName = videoInfo?.anchorNickname ?? "";
    String followCnt = videoInfo?.followerCount ?? "0";
    bool isFollow = VideoDetailDataMgr.instance.getFollowStatusByKey(pageKey);
    String avatar = '';
    if (videoInfo != null) {
      avatar = videoInfo.anchorImageCompress?.avatarCompressUrl ?? '';
      if (ObjectUtil.isEmptyString(avatar)) {
        avatar = videoInfo.anchorAvatar ?? '';
      }
    }
    double avatarSize = 40;
    bool isShowUserRecommend = !_judgeIsShowFullScreenReplay();
    double screenHeight = _getFullScreenWidth();
    double maxNameWidth = isShowUserRecommend
        ? (screenHeight * 0.3 - AppDimens.item_size_80 - 20)
        : screenHeight * 0.8;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        //头像
        InkWell(
          onTap: () {
            if (_judgeIsFullScreen()) {
              _onExpandCollapse();
              _onClickAvatar();
            }
          },
          child: ClipOval(
              child: SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: CachedNetworkImage(
                  placeholder: (context, url) {
                    return Image.asset('assets/images/ic_default_avatar.png');
                  },
                  imageUrl: avatar,
                  fit: BoxFit.cover,
                ),
              )),
        ),

        //昵称和粉丝数
        Container(
          margin: EdgeInsets.only(left: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              //昵称
              Container(
                constraints: BoxConstraints(
                  maxWidth: maxNameWidth,
                ),
                child: Text(
                  nickName,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      color: Common.getColorFromHexString("FFFFFF", 1.0),
                      fontWeight: FontWeight.bold),
                ),
              ),
              //粉丝数
              Container(
                margin: EdgeInsets.only(top: 2.5),
                constraints: BoxConstraints(
                  maxWidth: maxNameWidth,
                ),
                child: Text(
                  '$followCnt ${InternationalLocalizations
                      .videoSubscriptionCount}',
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Common.getColorFromHexString("D6D6D6", 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),

        //订阅按钮
        Flexible(
          flex: 1,
          child: Container(
            margin: EdgeInsets.only(left: 13),
            height: AppDimens.item_size_25,
            child: Material(
              borderRadius: BorderRadius.circular(
                  AppDimens.radius_size_21),
              color: isFollow
                  ? Common.getColorFromHexString("858585", 1.0)
                  : AppColors.color_3674ff,
              child: MaterialButton(
                minWidth: AppDimens.item_size_70,
                padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.margin_12),
                child: Text(
                  isFollow
                      ? InternationalLocalizations.videoSubscriptionFinish
                      : InternationalLocalizations.videoSubscription,
                  style: AppStyles.text_style_ffffff_12,
                  maxLines: 1,
                ),
                onPressed: () {
                  VideoDetailDataMgr.instance
                      .updateIsHandelRequestStatusByKey(pageKey, true);
                  setState(() {});
                  if (widget.handelFollowCallBack != null) {
                    widget.handelFollowCallBack();
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  ///创作者的推荐视频信息
  Widget _buildCreatorRecommendVideoInfoWidget() {
    String pageKey = widget.controlsKey;
    bool isShowUserRecommend = !_judgeIsShowFullScreenReplay();
    double coverWidth = 105;
    double coverHeight = 105 * (9 / 16);
    GetVideoListNewDataListBean videoInfo = VideoDetailDataMgr.instance
        .getFirstFollowingRecommendVideoByKey(pageKey);
    String cover = videoInfo?.videoImageCompress?.videoCompressUrl ?? '';
    if (ObjectUtil.isEmptyString(cover)) {
      cover = videoInfo?.videoCoverBig ?? '';
    }
    String title = videoInfo?.title ?? '';
    double maxWidth = _getFullScreenWidth() * 0.7 - 130;
    double descMargin = 10,
        closeBtnMargin = 20;
    double lrSpace = _getFullScreenLRSpace();
    if (isShowUserRecommend) {
      return Container(
        margin: EdgeInsets.only(left: 35),
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //封面
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _cancelTimer();
                if (widget.playNextVideoCallBack != null) {
                  widget.playCreatorRecommendVideoCallBack(VideoDetailDataMgr
                      .instance
                      .getFirstFollowingRecommendVideoByKey(pageKey));
                }
                setState(() {});
              },
              child: Container(
                  width: coverWidth,
                  height: coverHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(0.5)),
                    color: Common.getColorFromHexString("A0A0A0", 1.0),
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
                    borderRadius: BorderRadius.circular(0.5),
                    child: CachedNetworkImage(
                      fit: BoxFit.contain,
                      placeholder: (BuildContext context, String url) {
                        return Container();
                      },
                      imageUrl: cover,
                      errorWidget: (context, url, error) => Container(),
                    ),
                  )),
            ),
            Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth -
                    descMargin -
                    closeBtnMargin -
                    coverWidth -
                    lrSpace -
                    15,
              ),
              margin: EdgeInsets.only(left: descMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  //视频标题
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Common.getColorFromHexString("FFFFFF", 1.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  //倒计时描述
                  Container(
                    margin: EdgeInsets.only(top: 2),
                    child: Text(
                      '${InternationalLocalizations.recommendCountDownTips ??
                          ''}'
                          '${InternationalLocalizations.countDownSeconds(
                          VideoDetailDataMgr.instance
                              .getRecommendCountDownValueByKey(pageKey)
                              .toString())}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Common.getColorFromHexString("FFFFFF", 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //关闭按钮
            Container(
              padding: EdgeInsets.all(5),
              margin: EdgeInsets.only(left: closeBtnMargin),
              child: Material(
                color: Common.getColorFromHexString("000000", 0),
                child: Ink(
                  child: InkWell(
                    child: Image.asset(
                      'assets/images/icn_recommend_close.png',
                      fit: BoxFit.contain,
                      width: 12,
                      height: 12,
                    ),
                    onTap: () {
                      _cancelTimer();
                      setState(() {});
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }
    return Container();
  }

  ///重播按钮和文字描述
  Widget _buildNewReplayWidget() {
    return Material(
      color: Colors.transparent,
      child: Ink(
        child: InkWell(
          onTap: () {
            replay();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              //图标
              Container(
                child: Image.asset(
                  "assets/images/portrait_replay.png",
                  width: 15,
                  height: 15,
                ),
              ),
              //replay 文案
              Container(
                margin: EdgeInsets.only(left: 10),
                child: Text(
                  InternationalLocalizations.replay,
                  style: TextStyle(
                    fontSize: 14,
                    color: Common.getColorFromHexString("FFFFFF", 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountDownProgress() {
    bool isFullScreen = _judgeIsFullScreen();
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    double rate = screenWidth / 375;
    double baseWidth = isFullScreen ? 180 : 160;
    if (isFullScreen) {
      rate = screenHeight / 667;
    }
    double width = baseWidth * rate;
    return Container(
      margin: EdgeInsets.only(top: 12),
      child: AutoPlayProgressBar(
        widget.controlsKey,
        isFullScreen: isFullScreen,
        countdownTime: 5, //5s倒计时
        countDownFinishCallBack: () {
          //倒计时结束,播放下一个视频
          _isReplayStatus = false;
          VideoDetailDataMgr.instance
              .updateReplayStatusByKey(widget.controlsKey, false);
          if (widget.playNextVideoCallBack != null) {
            widget.playNextVideoCallBack();
          }
        },
        bgWidth: width,
      ),
    );
  }

  Widget _buildVideoCover() {
    double coverWidth = MediaQuery
        .of(context)
        .size
        .width;
    double coverHeight = coverWidth * 9.0 / 16;
    String coverPath = "";
    RelateListItemBean recVideo;
    if (_checkHasRecommendVideo()) {
      recVideo = VideoDetailDataMgr.instance
          .getRecommendVideoListByKey(widget.controlsKey)[0];
      coverPath = recVideo?.videoImageCompress?.videoCompressUrl ?? '';
      if (ObjectUtil.isEmptyString(coverPath)) {
        coverPath = recVideo?.videoCoverBig ?? '';
      }
    } else {
      coverPath = VideoDetailDataMgr.instance
          ?.getCurrentVideoInfoByKey(widget.controlsKey)
          ?.videoImageCompress
          ?.videoCompressUrl ??
          "";
      if (ObjectUtil.isEmptyString(coverPath)) {
        coverPath = VideoDetailDataMgr.instance
            ?.getCurrentVideoInfoByKey(widget.controlsKey)
            ?.videoCoverBig ??
            "";
      }
    }
    return Container(
      width: coverWidth,
      height: coverHeight,
      child: CachedNetworkImage(
        imageUrl: coverPath ?? '',
        fit: BoxFit.contain,
        placeholder: (BuildContext context, String url) {
          return Container();
        },
      ),
    );
  }

  ///横屏时当前播放视频的标题
  Widget _buildCurrentVideoTitle() {
    double lrSpace = _getFullScreenLRSpace();
    String title = VideoDetailDataMgr.instance
        .getCurrentVideoInfoByKey(widget.controlsKey)
        ?.title;
    if (_judgeIsFullScreen()) {
      return Container(
        width: MediaQuery
            .of(context)
            .size
            .width - lrSpace * 2,
        margin: EdgeInsets.fromLTRB(lrSpace, 20, lrSpace, 0),
        child: Text(
          title ?? "",
          style: TextStyle(
            fontSize: 15,
            color: Common.getColorFromHexString("FFFFFFFF", 1.0),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
        ),
      );
    }
    return Container();
  }

  ///自动播放: 下一个视频的标题等信息
  Widget _buildAutoPlayDetail() {
    bool isLoad =
    VideoDetailDataMgr.instance.getLoadStatuesByKey(widget.controlsKey);
    if (isLoad) {
      return Center(
          child: Theme(
            data: Theme.of(context).copyWith(accentColor: Colors.white),
            child: CircularProgressIndicator(),
          ));
    }
    double lrSpace = _getFullScreenLRSpace();
    RelateListItemBean recVideo;
    if (_checkHasRecommendVideo()) {
      recVideo = VideoDetailDataMgr.instance
          .getRecommendVideoListByKey(widget.controlsKey)[0];
    } else {
      return _buildReplay();
    }
    return Container(
      margin: EdgeInsets.only(top: (!_judgeIsFullScreen() ? 12 : 5)),
      padding: EdgeInsets.symmetric(horizontal: lrSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          //即将播放文案
          Text(
            InternationalLocalizations.aboutToPlay,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: Common.getColorFromHexString("FFFFFF", 1.0)),
          ),

          //下一个视频标题
          Container(
            margin: EdgeInsets.only(top: (_judgeIsFullScreen() ? 8 : 7.5)),
            child: Text(
              recVideo?.title ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Common.getColorFromHexString("FFFFFF", 1.0),
                  fontSize: _judgeIsFullScreen() ? 17 : 14,
                  fontWeight: FontWeight.bold),
            ),
          ),

          //下一个视频作者
          Container(
            margin: EdgeInsets.only(top: 4),
            child: Text(
              recVideo?.anchorNickname ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Common.getColorFromHexString("A0A0A0 ", 1.0),
                fontSize: 12,
              ),
            ),
          ),

          //进度条
          _buildCountDownProgress(),

          //取消、立即播放按钮
          Container(
            margin: EdgeInsets.only(top: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                //取消按钮
                Material(
                  color: Common.getColorFromHexString("000000", 0),
                  child: Ink(
                    child: InkWell(
                      onTap: () {
                        VideoDetailDataMgr.instance
                            .updateCurCountDownValueByKey(
                            widget.controlsKey, 0);
                        _notifyStopCountDown();
                        if (!_isReplayStatus) {
                          VideoDetailDataMgr.instance.updateReplayStatusByKey(
                              widget.controlsKey, true);
                          _isReplayStatus = true;
                          setState(() {});
                        }
                      },
                      child: Text(
                        InternationalLocalizations.cancel,
                        style: TextStyle(
                          fontSize: 13,
                          color: Common.getColorFromHexString("FFFFFFFF", 1.0),
                        ),
                      ),
                    ),
                  ),
                ),

                //立即播放按钮
                Container(
                  margin: EdgeInsets.only(left: 25),
                  child: Material(
                    color: Common.getColorFromHexString("000000", 0),
                    child: Ink(
                      child: InkWell(
                        onTap: () {
                          _notifyStopCountDown();
                          _isReplayStatus = false;
                          VideoDetailDataMgr.instance.updateReplayStatusByKey(
                              widget.controlsKey, false);
                          if (widget.playNextVideoCallBack != null) {
                            widget.playNextVideoCallBack();
                          }
                        },
                        child: Text(
                          InternationalLocalizations.playNow,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                            Common.getColorFromHexString("FFFFFFFF ", 1.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplay() {
    String imageName = _judgeIsFullScreen()
        ? "assets/images/full_screenreplay.png"
        : "assets/images/portraitreplay.png";
    return Container(
      margin: EdgeInsets.only(top: (_judgeIsFullScreen() ? 0 : 10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: Image.asset(imageName),
            onTap: () {
              replay();
            },
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              replay();
            },
            child: Container(
              margin: EdgeInsets.only(left: (_judgeIsFullScreen() ? 13 : 11)),
              child: Text(
                InternationalLocalizations.replay ?? "",
                style: TextStyle(
                  fontSize: _judgeIsFullScreen() ? 19 : 16,
                  color: Common.getColorFromHexString("FFFFFFFF", 1.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cancelListenEvent();
    _dispose();
    _cancelTimer();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    _isReplayStatus =
        VideoDetailDataMgr.instance.getIsReplayStatusByKey(widget.controlsKey);
    _isPlayEnd =
        VideoDetailDataMgr.instance.getIsPlayEndStatusByKey(widget.controlsKey);
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;
    if (_oldController != chewieController) {
      _dispose();
      if (chewieController.isInitFullScreen && !chewieController.isFullScreen) {
        Future.delayed(Duration(milliseconds: 500), () {
          setState(() {
            chewieController.toggleFullScreen();
          });
        });
      }
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildDefaultProgress() {
    double pHeight = 30 * _fullscreenFactor(2);
    return AnimatedOpacity(
      opacity: _showDefaultProgress ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      onEnd: () {
        if (mounted) {
          _isAnimateDefaultProgress = false;
          if (!_showDefaultProgress) {
            setState(() {
              _hideStuff = false;
            });
          }
        }
      },
      child: Container(
        alignment: Alignment.center,
//        height: 2,
        height: pHeight,
        padding: EdgeInsets.only(
          left: _judgeIsFullScreen() ? 25 : 0,
          right: _judgeIsFullScreen() ? 25 : 0,
          top: pHeight - 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            chewieController.isLive
                ? const SizedBox()
                : _buildProgressBar(false),
          ],
        ),
      ),
    );
  }

  AnimatedOpacity _buildBottomBar(BuildContext context,) {
    final iconColor = Theme
        .of(context)
        .textTheme
        .button
        .color;
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      onEnd: () {
        if (mounted) {
          if (_hideStuff) {
            if (!_isPlayEnd) {
              setState(() {
                _isAnimateDefaultProgress = true;
                _showDefaultProgress = true;
              });
            }
          } else {
            _hideTimer?.cancel();
            _startHideTimer();
          }
        }
      },
      child: Container(
        height: 30 * _fullscreenFactor(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: _getFullScreenLRSpace()),
            ),
            chewieController.isLive
                ? Expanded(child: const Text('LIVE'))
                : _buildPosition(iconColor),
            chewieController.isLive
                ? const SizedBox()
                : _buildProgressBar(true),
            chewieController.isLive ? Container() : _buildDuration(iconColor),
            chewieController.allowFullScreen
                ? _buildFullscreenToggle()
                : Container(),
          ],
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            child: _judgeIsFullScreen()
                ? _buildFullScreenPrevAndNextParts()
                : _buildPortraitPrevAndNextParts(),
          ),
          (_checkIsShowPlayStatusLoading() && _hideStuff)
              ? _buildPlayStatusLoading()
              : Container(),
        ],
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    String imageName = controller.value.isPlaying ? "pause" : "play";
    if (_isPlayEnd) {
      imageName = "replay";
    }
    return GestureDetector(
      onTap: _isPlayEnd ? replay : _playPause,
      behavior: HitTestBehavior.opaque,
      child: Container(
//        padding: EdgeInsets.all(_getFullScreenLRSpace()),
        child: _playerImage(imageName),
      ),
    );
  }

  GestureDetector _buildFullscreenToggle() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(_getFullScreenLRSpace()),
        child: _playerImage("toggle_fullscreen"),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;

    return Text(
      '${VideoUtil.formatDuration(position)}',
      style: TextStyle(
        fontSize: 11.0,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDuration(Color iconColor) {
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Text(
      '${VideoUtil.formatDuration(duration)}',
      style: TextStyle(
        fontSize: 11.0,
        color: Colors.white,
      ),
    );
  }

  void _cancelAndRestartTimer() {
    if (!_hideStuff) {
      _hideTimer?.cancel();
//      _startHideTimer();
      //按产品要求: 如果进度条展现的时候点击屏幕,则立即隐藏进度条
      _hideStuff = true;
    } else {
      if (!_judgeIsFullScreen()) {
        if (_showDefaultProgress) {
          _showDefaultProgress = false;
          _isAnimateDefaultProgress = true;
        } else {
          _hideStuff = false;
        }
      } else {
        _hideStuff = false;
      }
    }
    setState(() {
      _displayTapped = true;
    });
  }

  Future<Null> _initialize() async {
    controller.addListener(_updateState);
    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;
      _showDefaultProgress = true;
      _isAnimateDefaultProgress = true;
      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        _startHideTimer();
        controller.pause();
      } else {
//        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            _hideStuff = true;
            _showDefaultProgress = true;
            _isAnimateDefaultProgress = true;
            controller.play();
          });
        } else {
          if (isFinished) {
            _hideStuff = true;
            _showDefaultProgress = true;
            _isAnimateDefaultProgress = true;
            controller.seekTo(Duration(seconds: 0));
          }
          controller.play();
        }
      }
    });
  }

  void replay() async {
    _notifyStopCountDown();
    setState(() {
      _hideStuff = true;
      _showDefaultProgress = true;
      _isAnimateDefaultProgress = true;
    });
    await controller.seekTo(Duration(seconds: 0));
    await controller.play();
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _isPlayEnd = false;
        VideoDetailDataMgr.instance
            .updatePlayEndStatusByKey(widget.controlsKey, false);
        _isReplayStatus = false;
        VideoDetailDataMgr.instance
            .updateReplayStatusByKey(widget.controlsKey, false);
        controller.play();
      });
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    if (_latestValue != null &&
        _latestValue.position == controller.value.position) {
      return;
    }
    setState(() {
      _latestValue = controller.value;
      if (_latestValue.position == _latestValue.duration) {
        _isPlayEnd = true;
        _showDefaultProgress = false;
        _isAnimateDefaultProgress = false;
        _hideTimer?.cancel();
        _startHideTimer();
        VideoDetailDataMgr.instance
            .updatePlayEndStatusByKey(widget.controlsKey, true);
        if (!usrAutoPlaySetting) {
          _isReplayStatus = true;
          VideoDetailDataMgr.instance
              .updateReplayStatusByKey(widget.controlsKey, true);
        }
        _reportAutoPlayStatus();
        if (widget.videoPlayEndCallBack != null) {
          widget.videoPlayEndCallBack();
        }
      }
    });
  }

  Widget _buildProgressBar(bool isEnableDrag) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
            left: isEnableDrag ? 10.0 : 0, right: isEnableDrag ? 10.0 : 0),
        child: IgnorePointer(
          ignoring: _isPlayEnd || !isEnableDrag, //播放结束禁止拖动
          child: CosTVVideoProgressBar(
            controller,
            onDragStart: () {
              setState(() {
                _dragging = true;
                _hideStuff = false;
              });

              _hideTimer?.cancel();
            },
            onDragEnd: () {
              setState(() {
                _dragging = false;
              });
              _startHideTimer();
            },
            colors: chewieController.materialProgressColors ??
                ChewieProgressColors(
                    playedColor: Theme
                        .of(context)
                        .accentColor,
                    handleColor: Theme
                        .of(context)
                        .accentColor,
                    bufferedColor: Theme
                        .of(context)
                        .backgroundColor,
                    backgroundColor: Theme
                        .of(context)
                        .disabledColor),
            isEnableDrag: isEnableDrag,
          ),
        ),
      ),
    );
  }

  Widget _playerImage(String name) {
    String assetName;
    bool fullscreen = chewieController?.isFullScreen ?? false;
    switch (name) {
      case "play":
        assetName = fullscreen
            ? "icn_video_fullscreen_pause.png"
            : "icn_video_portrait_screen_pause.png";
        break;
      case "pause":
        assetName = fullscreen
            ? "icn_video_fullscreen_play.png"
            : "icn_video_portrait_play.png";
        break;
      case "replay":
        assetName =
        fullscreen ? "player_fullscreenreplay.png" : "playerreplay.png";
        break;
      case "prev":
        assetName = "player_prev.png";
        break;
      case "next":
        assetName = "player_next.png";
        break;
      case "toggle_fullscreen":
        assetName = fullscreen
            ? "player_fullscreen_exit.png"
            : "player_enter_fullscreen.png";
        break;
      case "lock":
        assetName = "player_fullscreen_lock.png";
        break;
      case "unlock":
        assetName = "player_fullscreen_unlock.png";
        break;
      case "replay":
        assetName = "playerreplay.png";
        break;
      case "zoom_out":
        assetName = "ic_zoom_out_white.png";
        break;
    }
    return assetName != null
        ? Image.asset("assets/images/" + assetName)
        : Container();
  }

  double _fullscreenFactor(double factor) {
    return chewieController.isFullScreen ? factor : 1.0;
  }

  bool _judgeIsFullScreen() {
    return chewieController.isFullScreen;
  }

  bool _checkHasRecommendVideo() {
    List<RelateListItemBean> recommendVideoList = VideoDetailDataMgr.instance
        .getRecommendVideoListByKey(widget.controlsKey);
    if (recommendVideoList != null && recommendVideoList.isNotEmpty) {
      return true;
    }
    return false;
  }

  void _listenEvent() {
    String pageKey = widget.controlsKey;
    if (_eventControls == null) {
      _eventControls = EventBusHelp.getInstance().on().listen((event) {
        if (event == null || !mounted) {
          return;
        }
        if (event is VideoDetailDataChangeEvent) {
          if (!_judgeIsCurrentEvent(event.flag)) {
            return;
          }
          if (!mounted) {
            return;
          }
          if (event.isReset != null && event.isReset) {
            _isPlayEnd = false;
            VideoDetailDataMgr.instance
                .updatePlayEndStatusByKey(pageKey, false);
            _isReplayStatus = false;
            VideoDetailDataMgr.instance.updateReplayStatusByKey(pageKey, false);
            VideoDetailDataMgr.instance
                .updateCurCountDownValueByKey(pageKey, 0);
          }

          setState(() {});
        } else if (event is AutoPlaySwitchEvent) {
          if (!_judgeIsCurrentEvent(event.flag)) {
            return;
          }
          if (event.isOpen != null) {
            if (_isPlayEnd && !event.isOpen) {
              _notifyStopCountDown();
              _isReplayStatus = true;
              VideoDetailDataMgr.instance
                  .updateReplayStatusByKey(widget.controlsKey, true);
              setState(() {});
            }
          }
        } else if (event is RefreshRecommendVideoFinishEvent) {
          if (!_judgeIsCurrentEvent(event.flag)) {
            return;
          }
          if (!mounted) {
            return;
          }
          if (event.isSuccess != null) {
            VideoDetailDataMgr.instance
                .updateIsHandelRequestStatusByKey(widget.controlsKey, false);
            if (VideoDetailDataMgr.instance
                .getIsPlayEndStatusByKey(widget.controlsKey)) {
              setState(() {});
            }
          }
        } else if (event is FollowStatusChangeEvent) {
          if (!_judgeIsCurrentEvent(event.flag)) {
            return;
          }
          if (event.isFollow != null && event.isSuccess != null) {
            VideoDetailDataMgr.instance
                .updateIsHandelRequestStatusByKey(widget.controlsKey, false);
            if (mounted &&
                VideoDetailDataMgr.instance
                    .getIsPlayEndStatusByKey(widget.controlsKey)) {
              if (!_judgeIsFullScreen()) {
                return;
              }
              if (event.isFollow && event.isSuccess) {
                //关注成功，显示关注的人的推荐视频
                VideoDetailDataMgr.instance
                    .updateShowUserRecommendByKey(widget.controlsKey, true);
                if (VideoDetailDataMgr.instance
                    .checkHasFollowingRecommendVideoByKey(widget.controlsKey)) {
                  _initCountDownTimer();
                  setState(() {});
                } else {
                  VideoDetailDataMgr.instance.updateIsHandelRequestStatusByKey(
                      widget.controlsKey, true);
                  if (widget.fetchFollowingRecommendVideoCallBack != null) {
                    widget.fetchFollowingRecommendVideoCallBack();
                  }
                  return;
                }
              } else if (!event.isFollow && event.isSuccess) {
                //取消关注
                _cancelTimer();
                setState(() {});
              } else {
                setState(() {});
              }
            }
          }
        } else if (event is FetchFollowingRecommendVideoFinishEvent) {
          if (!_judgeIsCurrentEvent(event.flag)) {
            return;
          }
          if (event.isSuccess != null && event.isSuccess) {
            if (mounted &&
                VideoDetailDataMgr.instance
                    .getIsPlayEndStatusByKey(widget.controlsKey)) {
              VideoDetailDataMgr.instance
                  .updateIsHandelRequestStatusByKey(widget.controlsKey, false);
              if (VideoDetailDataMgr.instance
                  .checkHasFollowingRecommendVideoByKey(widget.controlsKey)) {
                _initCountDownTimer();
              }
              setState(() {});
            }
          }
        }
      });
    }
  }

  bool _judgeIsCurrentEvent(String flag) {
    if (Common.checkIsNotEmptyStr(flag) && widget.controlsKey == flag) {
      return true;
    }
    return false;
  }

  void _cancelListenEvent() {
    if (_eventControls != null) {
      _eventControls.cancel();
      _eventControls = null;
    }
  }

  void _notifyStopCountDown() {
    EventBusHelp.getInstance()
        .fire(AutoPlayCountDownStatusEvent(widget.controlsKey, true));
  }

  int _getRecommendVideoListCount(bool isPortrait) {
    List<RelateListItemBean> videoList = VideoDetailDataMgr.instance
        .getRecommendVideoListByKey(widget.controlsKey);
    if (videoList != null && videoList.isNotEmpty) {
      if (isPortrait) {
        if (videoList.length >= 2) {
          return 2;
        }
        return 1;
      } else {
        return videoList.length;
      }
    }
    return 0;
  }

  AutoPlayRecommendVideoItem _getRecommendVideoItemByIndex(int index) {
    double rightPadding = 21;
    double leftMargin = 0;
    if (_judgeIsFullScreen()) {
      rightPadding = 15;
      if (index == 0) {
        leftMargin = _getFullScreenLRSpace();
      }
    }

    List<RelateListItemBean> videoList = VideoDetailDataMgr.instance
        .getRecommendVideoListByKey(widget.controlsKey);
    if (videoList != null && videoList.isNotEmpty && index < videoList.length) {
      return AutoPlayRecommendVideoItem(
        videoInfo: videoList[index],
        rightPadding: rightPadding,
        leftMargin: leftMargin,
        clickRecommendVideoCallBack: (RelateListItemBean videoInfo) {
          if (widget.clickRecommendVideoCallBack != null) {
            widget.clickRecommendVideoCallBack(videoInfo);
          }
        },
      );
    }
    return AutoPlayRecommendVideoItem();
  }

  void _onClickAvatar() {
    GetVideoInfoDataBean videoInfo = VideoDetailDataMgr.instance
        .getCurrentVideoInfoByKey(widget.controlsKey);
    String uid = videoInfo?.uid ?? "";
    if (videoInfo != null && Common.checkIsNotEmptyStr(uid)) {
      String nickName = videoInfo?.anchorNickname ?? "";
      String avatar = videoInfo?.anchorImageCompress?.avatarCompressUrl ?? '';
      if (ObjectUtil.isEmptyString(avatar)) {
        avatar = videoInfo?.anchorAvatar ?? '';
      }
      String isCertification = videoInfo?.isCertification ?? '';
      Navigator.of(context).push(SlideAnimationRoute(
        builder: (_) {
          return OthersHomePage(OtherHomeParamsBean(
            uid: uid,
            nickName: nickName,
            avatar: avatar,
            isCertification: isCertification,
          ));
        },
      ));
    }
  }

  bool _judgeIsShowFullScreenReplay() {
    if (VideoDetailDataMgr.instance
        .checkHasFollowingRecommendVideoByKey(widget.controlsKey) &&
        VideoDetailDataMgr.instance
            .getIsShowUserRecommendByKey(widget.controlsKey)) {
      return false;
    }
    return true;
  }

  double _getFullScreenLRSpace() {
    return 7.5 * _fullscreenFactor(20.0 / 7.5);
  }

  _cancelTimer() {
    VideoDetailDataMgr.instance
        .updateShowUserRecommendByKey(widget.controlsKey, false);
    if (_countDownTimer != null) {
      _countDownTimer.cancel();
      _countDownTimer = null;
    }
    VideoDetailDataMgr.instance.updateRecommendCountDownValueByKey(
        widget.controlsKey, cRecommendCountDownTime);
  }

  _initCountDownTimer() {
    String pageKey = widget.controlsKey;
    if (_countDownTimer == null) {
      _countDownTimer = Timer.periodic(Duration(seconds: 1), (t) {
        if (mounted &&
            VideoDetailDataMgr.instance.getIsPlayEndStatusByKey(pageKey) &&
            VideoDetailDataMgr.instance.getIsShowUserRecommendByKey(pageKey)) {
          int oldVal = VideoDetailDataMgr.instance
              .getRecommendCountDownValueByKey(pageKey);
          if (oldVal >= 1) {
            int newVal = cRecommendCountDownTime -
                (_countDownTimer.tick % (cRecommendCountDownTime + 1));
            VideoDetailDataMgr.instance
                .updateRecommendCountDownValueByKey(pageKey, newVal);
            setState(() {});
          } else {
            _cancelTimer();
            if (widget.playCreatorRecommendVideoCallBack != null) {
              widget.playCreatorRecommendVideoCallBack(VideoDetailDataMgr
                  .instance
                  .getFirstFollowingRecommendVideoByKey(pageKey));
            }
          }
        }
      });
    }
  }

  double _getFullScreenWidth() {
    return max(
        MediaQuery
            .of(context)
            .size
            .width, MediaQuery
        .of(context)
        .size
        .height);
  }

  void _reportAutoPlayStatus() {
    String isAutoPlay = usrAutoPlaySetting ? "1" : '0';
    DataReportUtil.instance.reportData(
        eventName: "Video_autoplay", params: {"if_autoplay": isAutoPlay});
  }

  void _handlePlayPrevVideo() {
    if (widget.playPreVideoCallBack != null) {
      widget.playPreVideoCallBack();
    }
  }

  void _handlePlayNextVideo() {
    if (widget.playNextVideoCallBack != null) {
      widget.playNextVideoCallBack();
    }
  }

  void _handleClickZoomOut() {
    if(widget.clickZoomOutCallBack != null){
      widget.clickZoomOutCallBack();
    }
  }

  bool _checkIsShowPlayStatusLoading() {
    bool isLoadData =
    VideoDetailDataMgr.instance.getLoadStatuesByKey(widget.controlsKey);
    if (_latestValue != null &&
        !_latestValue.isPlaying &&
        _latestValue.duration == null ||
        _latestValue.isBuffering ||
        isLoadData) {
      return true;
    }
    return false;
  }
}

class CosTVControlColor {
  static final MaterialProgressColors = ChewieProgressColors(
    playedColor: Color.fromRGBO(54, 116, 255, 0.8),
    handleColor: Color.fromRGBO(54, 116, 255, 1.0),
    bufferedColor: Color.fromRGBO(214, 214, 214, 1.0),
    backgroundColor: Color.fromRGBO(133, 133, 133, 1.0),
  );
}
