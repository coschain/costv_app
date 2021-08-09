import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';

class CosTvFullScreenBuilder {
  final double aspect;

  CosTvFullScreenBuilder(this.aspect);

  AnimatedWidget build(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      dynamic controllerProvider) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _buildFullScreenVideo(
      BuildContext context,
      Animation<double> animation,
      dynamic controllerProvider) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromRGBO(84, 84, 84, 1.0), Colors.black],
          ),
        ),
        child: Container(
          height: MediaQuery.of(context).size.width / aspect,
          child: ClipRect(
            child: controllerProvider,
          )
        )
      ),
    );
  }

  static ChewieRoutePageBuilder of(double aspect) {
    return CosTvFullScreenBuilder(aspect).build;
  }
}
