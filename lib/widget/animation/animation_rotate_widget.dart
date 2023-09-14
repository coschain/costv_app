import 'package:flutter/material.dart';

///中心处旋转动画，注意角度传递的是π
class AnimationRotateWidget extends StatefulWidget {
  /// 注意这个角度，π为180°
  static const PI = 3.1415926;
  final double endAngle;
  final bool rotated;
  final int duration;
  final Widget child;

  @override
  _AnimationRotateWidgetState createState() => _AnimationRotateWidgetState();

  AnimationRotateWidget({this.endAngle = PI, this.rotated = false, this.duration = 300, required this.child});
}

class _AnimationRotateWidgetState extends State<AnimationRotateWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double angle = 0;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.duration));
    _animation = Tween(begin: 0.0, end: widget.endAngle).animate(_controller)
      ..addListener(() {
        setState(() {
          angle = _animation.value;
        });
      });
    super.initState();
  }

  @override
  void didUpdateWidget(AnimationRotateWidget oldWidget) {
    if (oldWidget.rotated == widget.rotated) return; //防止多余刷新
    if (!widget.rotated) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: widget.child,
    );
  }
}
