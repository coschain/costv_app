import 'package:flutter/cupertino.dart';
import 'package:costv_android/utils/common_util.dart';
import 'dart:async';
import 'package:costv_android/utils/video_detail_data_manager.dart';
import 'package:costv_android/event/video_detail_data_change_event.dart';
import 'package:costv_android/event/base/event_bus_help.dart';

typedef CountDownFinishCallBack = Function();

class AutoPlayProgressBar extends StatefulWidget {
  final String pageKey;
  final bool isFullScreen;
  final double countdownTime;
  final CountDownFinishCallBack countDownFinishCallBack;
  final double bgWidth;
  AutoPlayProgressBar(this.pageKey, {Key key, this.isFullScreen = false,
    this.countdownTime = 5, this.countDownFinishCallBack, this.bgWidth = 168}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return AutoPlayProgressBarState();
  }
}

class AutoPlayProgressBarState extends State<AutoPlayProgressBar>
    with SingleTickerProviderStateMixin{
  AnimationController _controller;
  Animation<double> _widthAni;
  bool _isAnimating = false;
  Timer _timer;
  StreamSubscription _eventProgress;

  @override
  void initState() {
    super.initState();
    _listenEvent();
    _initAniController();
    double initWidth = _getInitProgressWidth();
    _widthAni = Tween<double>(begin: initWidth, end: initWidth).animate(_controller)
    ..addListener(updateState)
    ..addStatusListener(listenAnimationStatus);
    _initTimer();
  }

  @override
  void dispose() {
    _cancelTimer();
    _cancelListenEvent();
    if (_controller != null) {
      _controller.stop(canceled: true);
      _controller.dispose();
    }
    if (_widthAni != null) {
      _widthAni.removeListener(updateState);
      _widthAni.removeStatusListener(listenAnimationStatus);
    }

    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double bgHeight = 1.5;
    return Stack(
      children: <Widget>[
        Container(
          height: bgHeight,
          width: _getProgressWidth(),
          color: Common.getColorFromHexString("A0A0A0 ", 1),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
              color: Common.getColorFromHexString("3674FF", 1.0),
              height: bgHeight,
              width: _widthAni.value,
            ),
          ),
      ],
    );
  }

  double _getProgressWidth() {
//    double screenWidth = MediaQuery.of(context).size.width;
//    double  screenHeight = MediaQuery.of(context).size.height;
//    double rate = screenWidth/375;
//    if (widget.isFullScreen) {
//      rate = screenHeight/667;
//    }
//    return 160*rate;
  return widget.bgWidth;
  }

  void _initAniController() {
    if (_controller == null) {
      _controller = AnimationController(
          duration: const Duration(seconds: 1), vsync: this);
    }
  }

  void startAnimate() {
    if (_isAnimating) {
      return;
    }
    _isAnimating = true;
    _initTimer();
  }

  void stopAnimate() {
    if(_isAnimating) {
      _cancelTimer();
      setState(() {
        VideoDetailDataMgr.instance.updateCurCountDownValueByKey(widget.pageKey, 0);
        _controller.reverse();
      });
    }
  }

  _cancelTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  _initTimer() {
    if (_timer == null) {
      _timer = Timer.periodic(Duration(seconds: 1), (t) {
        if (mounted) {
          double oldProgress = VideoDetailDataMgr.instance.getCurCountDownValueByKey(widget.pageKey);
          double maxWidth = _getProgressWidth();
          double oldWidth = oldProgress/widget.countdownTime*maxWidth;
          oldProgress += 1;
          double newWidth = oldProgress/widget.countdownTime* maxWidth;
          VideoDetailDataMgr.instance.updateCurCountDownValueByKey(widget.pageKey, oldProgress);
          if (_controller == null) {
            _initAniController();
          }
          if (_widthAni.value > oldWidth) {
            oldWidth = _widthAni.value;
          }
          _controller.reset();
          _widthAni =
              Tween<double>(begin: oldWidth, end: newWidth).animate(_controller);
          try {
            _controller.forward();
          } on TickerCanceled {}
        }
      });
    }
  }

  void updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  void listenAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      if (VideoDetailDataMgr.instance.getCurCountDownValueByKey(widget.pageKey) >= widget.countdownTime) {
        _cancelTimer();
      }
    } else if (status == AnimationStatus.reverse) {
    } else if (status == AnimationStatus.completed) {
      _handleCountDownFinish();
    } else if (status == AnimationStatus.dismissed) {
      _isAnimating = false;
    }
  }

  void _handleCountDownFinish() {
    if (VideoDetailDataMgr.instance.getCurCountDownValueByKey(widget.pageKey) >= widget.countdownTime) {
      _cancelTimer();
      _isAnimating = false;
      VideoDetailDataMgr.instance.updateCurCountDownValueByKey(widget.pageKey, 0);
      if (widget.countDownFinishCallBack != null) {
        widget.countDownFinishCallBack();
      }
      setState(() {
        _controller.reverse();
      });
    }
  }

  double _getInitProgressWidth() {
    double oldProgress = VideoDetailDataMgr.instance.getCurCountDownValueByKey(widget.pageKey);
    if (oldProgress != null && oldProgress < 1) {
      return 0;
    }
    double maxWidth = _getProgressWidth();
    return oldProgress/widget.countdownTime*maxWidth;
  }


  void _listenEvent() {
    if (_eventProgress == null) {
      _eventProgress = EventBusHelp.getInstance().on().listen((event) {
        if (event == null) {
          return;
        }
        if (event is AutoPlayCountDownStatusEvent) {
          if (event.isFinish != null) {
            VideoDetailDataMgr.instance.updateCurCountDownValueByKey(widget.pageKey, 0);
            _cancelTimer();
          }
        }
      });
    }
  }

  void _cancelListenEvent() {
    if (_eventProgress != null) {
      _eventProgress.cancel();
      _eventProgress = null;
    }
  }
}