import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/relate_list_bean.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/widget/video_time_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef ClickRecommendVideoCallBack = Function(RelateListItemBean videoInfo);

class AutoPlayRecommendVideoItem extends StatefulWidget {
  final RelateListItemBean videoInfo;
  final double rightPadding;
  final double leftMargin;
  final ClickRecommendVideoCallBack clickRecommendVideoCallBack;

  AutoPlayRecommendVideoItem({
    this.videoInfo,
    this.rightPadding,
    this.leftMargin = 0,
    this.clickRecommendVideoCallBack,
  });

  @override
  State<StatefulWidget> createState() {
    return AutoPlayRecommendVideoItemState();
  }
}

class AutoPlayRecommendVideoItemState
    extends State<AutoPlayRecommendVideoItem> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double baseWidth = min(screenWidth, screenHeight);
    double ratio = baseWidth / 375, coverRatio = 9 / 16;
    double bgWidth = ratio * 152;
    double coverHeight = bgWidth * coverRatio;
    return Container(
      padding: EdgeInsets.only(right: widget.rightPadding),
      margin: EdgeInsets.only(left: widget.leftMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
//        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildVideoCover(bgWidth, coverHeight),
          _buildVideoTitle(bgWidth),
          _buildNickName(bgWidth),
        ],
      ),
    );
  }

  Widget _buildVideoCover(double coverWidth, double coverHeight) {
    String imageUrl = widget.videoInfo?.videoImageCompress?.videoCompressUrl ?? '';
    if(ObjectUtil.isEmptyString(imageUrl)){
      imageUrl = widget.videoInfo?.videoCoverBig ?? '';
    }
    return InkWell(
      child: Stack(
        children: <Widget>[
          //封面
          Container(
              width: coverWidth,
              height: coverHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(1.5)),
                color: Common.getColorFromHexString("A0A0A0", 1.0),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Common.getColorFromHexString("838383", 1),
                    Common.getColorFromHexString("333333", 1),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: CachedNetworkImage(
                  fit: BoxFit.contain,
                  placeholder: (BuildContext context, String url) {
                    return Container();
                  },
                  imageUrl: imageUrl,
                  errorWidget: (context, url, error) => Container(),
                ),
              )),
          //视频时长
          _getVideoDurationWidget(),
        ],
      ),
      onTap: () {
        if (widget.clickRecommendVideoCallBack != null) {
          widget.clickRecommendVideoCallBack(widget.videoInfo);
        }
      },
    );
  }

  Widget _getVideoDurationWidget() {
    if (Common.checkVideoDurationValid(widget.videoInfo?.duration)) {
      return Positioned(
        right: 0,
        bottom: 0,
        child: VideoTimeWidget(
            Common.formatVideoDuration(widget.videoInfo?.duration)),
      );
    }
    return Container();
  }

  Widget _buildVideoTitle(double titleWidth) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      width: titleWidth,
      child: Text(
        widget.videoInfo?.title ?? '',
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        maxLines: 1,
        style: TextStyle(
            fontSize: 13,
            color: Common.getColorFromHexString("FFFFFF", 1.0),
            fontFamily: "Roboto"),
      ),
    );
  }

  Widget _buildNickName(double bgWidth) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      width: bgWidth,
      child: Text(
        widget.videoInfo?.anchorNickname ?? '',
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        maxLines: 1,
        style: TextStyle(
            fontSize: 11,
            color: Common.getColorFromHexString("FFFFFF", 1.0),
            fontWeight: FontWeight.bold,
            fontFamily: "Roboto"),
      ),
    );
  }
}
