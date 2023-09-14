import 'package:costv_android/utils/common_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/values/app_styles.dart';

class VideoAddMoneyWidget extends StatefulWidget {
  final Widget baseWidget;
  final TextStyle textStyle;
  final AlignmentGeometry stackAlignment;
  final double translateY;
  VideoAddMoneyWidget(
      {Key? key, required this.baseWidget, required this.textStyle, this.stackAlignment = AlignmentDirectional.center, this.translateY = -35})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return VideoAddMoneyWidgetState();
  }
}

class VideoAddMoneyWidgetState extends State<VideoAddMoneyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;
  late Animation<double> _translate;
  late Animation<double> _scale;
  bool _isAnimating = false;
  String moneyStr = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 750), vsync: this)
      ..addListener(updateState)
      ..addStatusListener(listenAnimationStatus);
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.05, curve: Curves.easeIn)
    ));
    _translate = Tween<double>(begin:0, end: widget.translateY).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.05, 0.75, curve: Curves.ease)));
    _fadeOut = Tween<double>(begin: 1.0, end: 0).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.75, 1.0, curve: Curves.easeOut)
    ));

    _scale = Tween<double>(begin: 1.0, end: 0.8).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(0.75, 1.0, curve: Curves.easeOut)
    ));
  }

  @override
  void dispose() {
    _controller.removeListener(updateState);
    _fadeIn.removeStatusListener(listenAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: widget.stackAlignment,
      children: <Widget>[
        widget.baseWidget,
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 30,
            ),
            child: IgnorePointer(
              ignoring: true,
                child: Transform.translate(
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Opacity(
                      opacity: _fadeIn.value < 1 ? _fadeIn.value : _fadeOut.value,
                      child: Text(
                        moneyStr ?? "",
                        textAlign: TextAlign.center,
                        style: widget.textStyle ?? AppStyles.text_style_333333_bold_18,
                      ),
                    ),
                  ),
                  offset: Offset(
                    0,_translate != null ? _translate.value : 0,
                  ),
                ),


              ),
            ),
        ),
      ],
    );
  }

  Future<void> startShowWithAni(String val) async {
    if (mounted || Common.checkIsNotEmptyStr(val)) {
      if (_isAnimating) {
        return;
      }
      moneyStr = val;
      _isAnimating = true;
      try{
        _controller.forward().orCancel;
      } catch (e) {

      }
    }
  }

  void updateState() {
    setState(() {

    });
  }

  void listenAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
    } else if (status == AnimationStatus.reverse) {
    } else if (status == AnimationStatus.completed) {
       _isAnimating = false;
       _controller.reset();
    } else if (status == AnimationStatus.dismissed) {

    }
  }
}