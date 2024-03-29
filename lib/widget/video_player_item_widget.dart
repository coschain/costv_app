import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/widget/video_time_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

class VideoPlayerItemWidget extends StatefulWidget {
  VideoPlayerItemWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return VideoPlayerItemWidgetState();
  }
}

class VideoPlayerItemWidgetState extends State<VideoPlayerItemWidget> with WidgetsBindingObserver, TickerProviderStateMixin {
  VideoPlayerController? controller;
  ChewieController? chewieController;
  VideoPlayerValue? _latestValue;
  late AnimationController _lottieController;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _lottieController = AnimationController(vsync: this);
    _lottieController.duration = Duration(seconds: 2);
    super.initState();
  }

  @override
  void dispose() {
    _dispose();
    WidgetsBinding.instance.removeObserver(this);
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildCustomPlayerWidget();
  }

  Widget _buildCustomPlayerWidget() {
    return Container(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                child: Container(),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            child: _buildBottomParts(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayStatusParts() {
    if ((_latestValue != null && _latestValue?.duration == null || (_latestValue?.isBuffering ?? false)) || _latestValue == null) {
      return Center(
        child: _buildVideoLoadingWidget(),
      );
    } else if (_latestValue != null && !(_latestValue?.isPlaying ?? false)) {
      //暂停状态,不用显示正在播放标志
      return Container();
    }
    return _buildPlayingAnimationWidget();
  }

  Widget _buildVideoLoadingWidget() {
    return Container(
      margin: EdgeInsets.only(right: 10),
      child: SizedBox(
        height: 15,
        width: 15,
        child: Container(
            color: Colors.transparent,
            child: CircularProgressIndicator(
              strokeWidth: 1.0,
              valueColor: AlwaysStoppedAnimation<Color>(Common.getColorFromHexString("FFFFFF", 1.0)),
            )),
      ),
    );
  }

  //正在播放的状态以及剩余时长
  Widget _buildBottomParts() {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _buildPlayStatusParts(),
          //视频时长
          _buildVideoDuration(),
        ],
      ),
    );
  }

  //正在播放的动画标识
  Widget _buildPlayingAnimationWidget() {
    return Container(
      color: Colors.transparent,
//      margin: EdgeInsets.only(right: 5),
      width: 28,
      height: 28,
      child: Lottie.asset(
        "assets/json/animations/play_status_animation.json",
        controller: _lottieController,
        repeat: true,
        onLoaded: (composition) {
          _lottieController.duration = composition.duration;
        },
      ),
    );
  }

  Widget _buildVideoDuration() {
    final duration = _latestValue != null && _latestValue?.duration != null && _latestValue?.position != null
        ? (_latestValue?.duration ?? Duration.zero - (_latestValue?.position ?? Duration.zero))
        : Duration.zero;
    return Container(
      child: VideoTimeWidget(VideoUtil.formatDuration(duration)),
      margin: EdgeInsets.only(right: 20),
    );
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController?.videoPlayerController;
    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }
    super.didChangeDependencies();
  }

  void _updateState() {
    if (_latestValue != null && _latestValue?.position == controller?.value.position && _latestValue?.isPlaying == controller?.value.isPlaying) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _latestValue = controller?.value;
      if (_latestValue?.isPlaying ?? false) {
        _resumePlayAnimation();
        _startPlayAnimation();
      } else {
        _stopPlayAnimation();
      }
    });
  }

  Future<void> _initialize() async {
    controller?.addListener(_updateState);
    _updateState();
  }

  void _dispose() {
    if (controller != null) {
      controller?.removeListener(_updateState);
    }
  }

  void _stopPlayAnimation() {
    _lottieController.stop();
  }

  void _startPlayAnimation() {
    _lottieController.forward();
  }

  void _resumePlayAnimation() {}
}
