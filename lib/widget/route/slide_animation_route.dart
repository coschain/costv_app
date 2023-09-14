import 'package:costv_android/constant.dart';
import 'package:flutter/material.dart';

class SlideAnimationRoute extends PageRoute {
  static const int animationTypeHorizontal = 10001;

  static const int animationTypeVertical = 10002;

  SlideAnimationRoute({
    required this.builder,
    RouteSettings? settings,
    this.isCheckAnimation = false,
    this.animationType = animationTypeHorizontal,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.maintainState = true,
  }) : super(settings: settings);

  final WidgetBuilder builder;

  final bool isCheckAnimation;

  final int animationType;

  @override
  final Duration transitionDuration;

  @override
  final bool opaque;

  @override
  final bool barrierDismissible;

  @override
  final Color? barrierColor;

  @override
  final String? barrierLabel;

  @override
  final bool maintainState;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (isCheckAnimation) {
      if (Constant.backAnimationType == animationTypeHorizontal) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: const Offset(0.0, 0.0),
          ).animate(CurvedAnimation(
              parent: animation,
              //fastOutSlowIn快进慢出
              //bounceOut 切换的时候有一种抖动的效果
              //ease 翻书一样的效果
              //easeInExpo有一种退场和进场的慢动作效果
              //slowMiddle进场和退场到一半的时候有一个暂停
              curve: Curves.linear)),
          child: child,
        );
      } else {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: const Offset(0.0, 0.0),
          ).animate(CurvedAnimation(parent: controller!, curve: Curves.linear)),
          child: child,
        );
      }
    } else {
      if (animationType == animationTypeHorizontal) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: const Offset(0.0, 0.0),
          ).animate(CurvedAnimation(parent: animation, curve: Curves.linear)),
          child: child,
        );
      } else {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: const Offset(0.0, 0.0),
          ).animate(CurvedAnimation(parent: animation, curve: Curves.linear)),
          child: child,
        );
      }
    }
  }
}
