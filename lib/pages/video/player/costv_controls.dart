import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:costv_android/utils/video_util.dart';
import 'package:costv_android/pages/video/player/costv_video_progress_bar.dart';

class CosTVControls extends StatefulWidget {
  const CosTVControls({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CosTVControlsState();
  }
}

class _CosTVControlsState extends State<CosTVControls> {
  VideoPlayerValue _latestValue;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  VideoPlayerController controller;
  ChewieController chewieController;

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
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

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: <Widget>[
              _latestValue != null &&
                  !_latestValue.isPlaying &&
                  _latestValue.duration == null ||
                  _latestValue.isBuffering
                  ? const Expanded(
                child: const Center(
                  child: const CircularProgressIndicator(),
                ),
              )
                  : _buildHitArea(),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
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
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
      BuildContext context,
      ) {
    final iconColor = Theme.of(context).textTheme.button.color;

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
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
            _buildPlayPause(controller),
            chewieController.isLive
                ? Expanded(child: const Text('LIVE'))
                : _buildPosition(iconColor),
            chewieController.isLive ? const SizedBox() : _buildProgressBar(),
            chewieController.isLive
                ? Container()
                : _buildDuration(iconColor),
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
      child: Container(),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(7.5 * _fullscreenFactor(20.0 / 7.5)),
        child: _playerImage(controller.value.isPlaying? "pause" : "play"),
      ),
    );
  }

  GestureDetector _buildFullscreenToggle() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(7.5 * _fullscreenFactor(20.0 / 7.5)),
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
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
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
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration(seconds: 0));
          }
          controller.play();
        }
      }
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
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          child: CosTVVideoProgressBar(
            controller,
            onDragStart: () {
              setState(() {
                _dragging = true;
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
                    playedColor: Theme.of(context).accentColor,
                    handleColor: Theme.of(context).accentColor,
                    bufferedColor: Theme.of(context).backgroundColor,
                    backgroundColor: Theme.of(context).disabledColor),
          ),
        ),
      );
  }

  Widget _playerImage(String name) {
    String assetName;
    bool fullscreen = chewieController?.isFullScreen ?? false;
    switch (name){
      case "play":
        assetName = fullscreen? "player_fullscreen_play.png" : "player_play.png";
        break;
      case "pause":
        assetName = fullscreen? "player_fullscreen_pause.png" : "player_pause.png";
        break;
      case "replay":
        assetName = fullscreen? "player_fullscreen_replay.png" : "player_replay.png";
        break;
      case "prev":
        assetName = "player_prev.png";
        break;
      case "next":
        assetName = "player_next.png";
        break;
      case "toggle_fullscreen":
        assetName = fullscreen? "player_fullscreen_exit.png" : "player_enter_fullscreen.png";
        break;
      case "lock":
        assetName = "player_fullscreen_lock.png";
        break;
      case "unlock":
        assetName = "player_fullscreen_unlock.png";
        break;
    }
    return assetName != null
        ? Image.asset("assets/images/" + assetName)
        : Container();
  }

  double _fullscreenFactor(double factor) {
    return chewieController.isFullScreen? factor : 1.0;
  }

}


class CosTVControlColor {

  static final MaterialProgressColors = ChewieProgressColors(
    playedColor: Color.fromRGBO(54, 116, 255, 0.8),
    handleColor: Color.fromRGBO(54, 116, 255, 1.0),
    bufferedColor: Color.fromRGBO(133, 133, 133, 0.8),
    backgroundColor: Color.fromRGBO(255, 255, 255, 0.3),
  );
}