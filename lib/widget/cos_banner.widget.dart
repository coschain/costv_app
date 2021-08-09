import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/cos_banner_bean.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef BannerClickCallBack = void Function(CosBannerData data);

class CosBannerWidget extends StatefulWidget {
  final List<CosBannerData> dataList;
  final BannerClickCallBack clickCallBack;
  final Curve curve;
  final bool hasBottomSeparate;

  CosBannerWidget({
    Key key,
    this.dataList,
    this.clickCallBack,
    this.curve = Curves.linear,
    this.hasBottomSeparate = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CosBannerWidgetState();
  }
}

class CosBannerWidgetState extends State<CosBannerWidget> {
  PageController _pageController;
  int _curIndex = 0;
  int totalPage = 0;
  Timer _timer;
  double widthRatio = 345.0 / 375.0;
  bool isFirstLoad = true;

  @override
  void dispose() {
    if (_pageController != null) {
      _pageController.dispose();
    }
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    totalPage = widget.dataList?.length ?? 0;
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: widthRatio,
    );
    if (totalPage > 1) {
      _initTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataList != null && totalPage != widget.dataList.length) {
      totalPage = widget.dataList.length;
    }
    return Container(
      padding: EdgeInsets.only(bottom: widget.hasBottomSeparate ? 15 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildPageView(),
          _buildBottomDesc(),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    double coverRatio = 194.0 / 345.0;
    double screenWidth = MediaQuery.of(context).size.width;
    double coverWidth = screenWidth * widthRatio,
        coverHeight = coverWidth * coverRatio;
    double paddingTop = 10;
    return Container(
      height: coverHeight + paddingTop,
      width: screenWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radius_size_4)),
//        boxShadow: [
//          BoxShadow(
//            color: Color.fromRGBO(0,0,0,0.30),
//            offset: Offset(0, 100),
//            blurRadius: 5,
//          )],
      ),
      padding: EdgeInsets.only(top: paddingTop),
      child: PageView.builder(
        physics: totalPage > 1
            ? AlwaysScrollableScrollPhysics()
            : NeverScrollableScrollPhysics(),
        controller: _pageController,
        itemBuilder: (context, index) {
          if (index == 0 && isFirstLoad) {
            isFirstLoad = false;
            if (totalPage > 1) {
              Future.delayed(Duration(milliseconds: 300), () {
                if (mounted) {
                  _pageController.jumpToPage(totalPage);
                }
              });
            }
          }
          if (totalPage == 1 && index > 0) {
            return Container();
          }
          CosBannerData video = _getDataOfPage(index % totalPage);
          String imageUrl =
              video?.videoInfo?.videoImageCompress?.videoCompressUrl ?? "";
          if (ObjectUtil.isEmptyString(imageUrl)) {
            imageUrl = video?.image ?? '';
          }
          return GestureDetector(
            onPanDown: (details) {
              if (totalPage > 1) {
                _cancelTimer();
              }
            },
            onPanEnd: (details) {
              if (totalPage > 1) {
                _initTimer();
              }
            },
            onPanCancel: () {
              if (totalPage > 1) {
                _initTimer();
              }
            },
            onTap: () {
              _onClickBanner(index % totalPage);
            },
            child: Stack(
              alignment: Alignment.bottomCenter,
              overflow: Overflow.visible,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.fromLTRB(index == 0 ? 0 : 5, 0, 5, 0),
                  width: screenWidth,
                  height: coverHeight,
//                    color: Colors.transparent,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppDimens.radius_size_4)),
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
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimens.radius_size_4)),
                      child: CachedNetworkImage(
                        fit: BoxFit.fitHeight,
                        imageUrl: imageUrl,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppDimens.radius_size_4)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Common.getColorFromHexString("838383", 1),
                                Common.getColorFromHexString("333333", 1),
                              ],
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(),
                      )),
                ),
                Container(
                  width: screenWidth,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppDimens.radius_size_4)),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0,0,0,0.30),
                        offset: Offset(0, 0),
                        blurRadius: 4,
                      )],
                  ),
                ),
              ],
            ),

          );
        },
        onPageChanged: (index) {
          if (mounted) {
            setState(() {
              _curIndex = index;
              if (index == 0 && totalPage > 1) {
                _curIndex = totalPage;
//                _pageController.jumpToPage(_curIndex);
                _pageController.animateToPage(_curIndex,
                    duration: Duration(milliseconds: 10), curve: Curves.linear);
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildBottomDesc() {
    double bgWidth = MediaQuery.of(context).size.width;
    return Container(
      color: AppThemeUtil.setDifferentModeColor(
        lightColorStr: "FFFFFFFF",
        darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr
      ),
      width: bgWidth,
      height: AppDimens.item_size_37,
      padding: EdgeInsets.only(
        left: AppDimens.margin_15,
        right: AppDimens.margin_15,
      ),
      child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: AppDimens.margin_10),
                padding: EdgeInsets.only(left: AppDimens.margin_5),
                child: Text(
                  _getBannerDesc() ?? "",
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: AppThemeUtil.setDifferentModeColor(
                      lightColorStr: "333333",
                      darkColorStr: "FFFFFF "
                    ),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            //页码
            Text(
              _getPageNumberDesc(),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14.0,
                color: AppThemeUtil.setDifferentModeColor(
                  lightColorStr: "000000",
                  darkColorStr: "FFFFFF"
                ),
                fontFamily: "DIN",
              ),
            )
          ]),
    );
  }

  _cancelTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
//      _initTimer();
    }
  }

  _initTimer() {
    if (_timer == null) {
      _timer = Timer.periodic(Duration(seconds: 3), (t) {
        if (mounted && _pageController.hasClients) {
          int page = _curIndex + 1;
          _pageController.animateToPage(
            page,
            duration: Duration(milliseconds: 300),
            curve: Curves.linear,
          );
        }
      });
    }
  }

  _onClickBanner(int idx) {
    if (widget.clickCallBack != null) {
      int listCnt = widget.dataList?.length ?? 0;
      if (idx >= 0 && idx < listCnt) {
        widget.clickCallBack(widget.dataList[idx]);
      } else {
        CosLogUtil.log(
            "Banner: fail to call back,index is $idx, data list is $listCnt");
      }
    }
  }

  CosBannerData _getDataOfPage(int idx) {
    int listCnt = widget.dataList?.length ?? 0;
    if (idx >= 0 && idx < listCnt) {
      return widget.dataList[idx];
    } else {
      return null;
    }
  }

  String _getPageNumberDesc() {
    if (_curIndex != null) {
      int idx = _curIndex % totalPage;
      return "${idx + 1}/$totalPage";
    }
    return "";
  }

  String _getBannerDesc() {
    if (_curIndex != null) {
      return widget.dataList[_curIndex % totalPage].banner;
    }
    return "";
  }
}
