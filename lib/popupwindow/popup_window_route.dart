import 'package:flutter/material.dart';

class PopupWindowRoute extends PopupRoute {
  final Duration _duration = Duration(milliseconds: 300);
  Widget child;

  PopupWindowRoute({required this.child});

  @override
  Color get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => "";

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return child;
  }

  @override
  Duration get transitionDuration => _duration;
}
