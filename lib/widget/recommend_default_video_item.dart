import 'package:costv_android/utils/common_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class RecommendDefaultVideoItem extends StatelessWidget {
  final double rightPadding;
  final double leftMargin;
  RecommendDefaultVideoItem({this.rightPadding = 21, this.leftMargin = 0});
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double baseWidth = min(screenWidth, screenHeight);
    double ratio = baseWidth / 375, coverRatio = 9/16;
    double bgWidth = ratio*152;
    double coverHeight = bgWidth * coverRatio;
    return Container(
      padding: EdgeInsets.fromLTRB(leftMargin, 0, rightPadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCover(bgWidth,coverHeight),
          _buildVideoTitle(bgWidth),
          _buildNickName(bgWidth),
        ],
      ),
    );
  }

  Widget _buildCover(double coverWidth, double coverHeight) {
   return Container(
     width: coverWidth,
     height: coverHeight,
     decoration: BoxDecoration(
       borderRadius: BorderRadius.all(Radius.circular(1.5)),
       color: Common.getColorFromHexString("A0A0A0", 1.0),
     ),
   );
  }

  Widget _buildVideoTitle(double titleWidth) {
    return Container(
      margin: EdgeInsets.only(top: 7.5),
      width: titleWidth,
      height: 10,
      color: Common.getColorFromHexString("A0A0A0", 1.0),
    );
  }

  Widget _buildNickName(double bgWidth) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      width: bgWidth * (62.5 / 152),
      height: 10,
      color: Common.getColorFromHexString("A0A0A0", 1.0),
    );
  }

}