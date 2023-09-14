import 'package:costv_android/language/international_localizations.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/common_util.dart';

class NetRequestFailTipsView extends StatefulWidget{
  final Widget baseWidget;
  NetRequestFailTipsView({Key? key, required this.baseWidget}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return NetRequestFailTipsViewState();
  }
}

class NetRequestFailTipsViewState extends State<NetRequestFailTipsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  bool isAnimation = false, isShowing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fade = Tween<double>(begin: 0.0, end: 0.9).animate(_controller)
      ..addListener(updateState)
      ..addStatusListener(listenAnimationStatus);
  }

  @override
  void dispose() {
    _controller.dispose();
    _fade.removeListener(updateState);
    _fade.removeStatusListener(listenAnimationStatus);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.topCenter,
      children: <Widget>[
        widget.baseWidget,
        IgnorePointer(
          ignoring: true,//屏蔽点击事件
          child: Opacity(
            opacity: _fade.value,
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: Common.getColorFromHexString("3674FF", 1.0),
              padding: EdgeInsets.all(7.0),
              child: Text(
                InternationalLocalizations.netError,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Common.getColorFromHexString("FFFFFF", 1.0),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // 开始播放动画
  Future<void> showWithAnimation() async{
    if (isAnimation || isShowing) {
      return;
    }
    isAnimation = true;
    isShowing = true;
    try {
        _controller.forward().orCancel;
    } on TickerCanceled {}
  }

  void updateState() {
    setState(() {

    });
  }
  
  void listenAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
    } else if (status == AnimationStatus.reverse) {
    } else if (status == AnimationStatus.completed) {
      isAnimation = false;
      if (isShowing) {
        Future.delayed(Duration(seconds: 2), (){
          isAnimation = true;
          _controller.reverse();
        });
      }
    } else if (status == AnimationStatus.dismissed) {
      isShowing = false;
      isAnimation = false;
    }
  }
}
