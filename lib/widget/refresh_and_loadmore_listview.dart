import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/widget/bottom_progress_indicator.dart';
import 'package:costv_android/widget/no_more_data_widget.dart';
import 'package:flutter/material.dart';

typedef Widget ItemBuilder(BuildContext context, int position);
typedef ScrollEndCallBack = Function(double lastPostion, double curPosition);
typedef ScrollStartCallBack = Function();
typedef ScrollStatusCallBack = Function(ScrollNotification notification);

///带下拉刷新和上拉加载更多的列表控件
class RefreshAndLoadMoreListView extends StatefulWidget {
  final int itemCount, pageSize;
  final Widget? itemLine;
  String? bottomMessage;
  final ItemBuilder itemBuilder;
  final Function? onRefresh, onLoadMore;
  final bool isHaveMoreData, isShowItemLine, isRefreshEnable, isLoadMoreEnable;
  final bool hasTopPadding;
  final bool isShowBottomView;
  final double contentTopPadding;
  final ScrollEndCallBack? scrollEndCallBack;
  final ScrollStartCallBack? scrollStartCallBack;
  final ScrollStatusCallBack? scrollStatusCallBack;
  final double scrollPixels;

  RefreshAndLoadMoreListView(
      {Key? key,
      this.itemLine,
      this.pageSize = 20,
      required this.itemBuilder,
      required this.itemCount,
      this.onRefresh,
      this.onLoadMore,
      this.isHaveMoreData = true,
      this.isRefreshEnable = true,
      this.isLoadMoreEnable = true,
      this.isShowItemLine = false,
      this.bottomMessage,
      this.hasTopPadding = true,
      this.isShowBottomView = true,
      this.scrollEndCallBack,
      this.contentTopPadding = 0,
      this.scrollStartCallBack,
      this.scrollStatusCallBack,
      this.scrollPixels = 0.0})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return RefreshAndLoadMoreListViewState();
  }
}

class RefreshAndLoadMoreListViewState extends State<RefreshAndLoadMoreListView> {
  late ScrollController _listController;
  double lastPosition = 0;
  bool _isScrollingToTop = false;

  @override
  void initState() {
    super.initState();
    _listController = ScrollController(initialScrollOffset: widget.scrollPixels);
    if (widget.bottomMessage == null) {
      widget.bottomMessage = InternationalLocalizations.noMoreData;
    }
    _listController.addListener(() {
      if (_listController.position.pixels == _listController.position.maxScrollExtent) {
        if (widget.onLoadMore != null && widget.isHaveMoreData) {
          widget.onLoadMore?.call();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int bottomItemCount = widget.isLoadMoreEnable ? 1 : 0;
    int itemCount = widget.isShowItemLine ? widget.itemCount * 2 - 1 + bottomItemCount : widget.itemCount + bottomItemCount;
    double topPadding = 0;
    if (widget.hasTopPadding) {
      topPadding = MediaQuery.of(context).padding.top;
    }
    var listView = ListView.builder(
      padding: EdgeInsets.only(top: topPadding + widget.contentTopPadding),
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int position) {
        if (widget.isLoadMoreEnable && position == (widget.isShowItemLine ? widget.itemCount * 2 - 1 : widget.itemCount)) {
          if (widget.itemCount == 0 || !widget.isShowBottomView) {
            return Container();
          } else {
            if (widget.isHaveMoreData) {
              return BottomProgressIndicator();
            } else {
              return NoMoreDataWidget(
                bottomMessage: widget.bottomMessage ?? "",
              );
            }
          }
        } else {
          if (widget.isShowItemLine && position.isOdd) {
            return widget.itemLine ??
                Container(
                  height: AppDimens.item_size_1,
                  color: AppColors.color_f4f4f4,
                );
          } else {
            if (widget.isShowItemLine) {
              position = position ~/ 2;
            }
            return widget.itemBuilder(context, position);
          }
        }
      },
      itemCount: itemCount,
      controller: _listController,
    );
    var listViewWidget;
    if (widget.isRefreshEnable && widget.onRefresh != null) {
      listViewWidget = RefreshIndicator(displacement: 20, child: listView, onRefresh: widget.onRefresh as RefreshCallback);
    } else {
      listViewWidget = listView;
    }
    if (widget.scrollEndCallBack != null || widget.scrollStartCallBack != null || widget.scrollStatusCallBack != null) {
      return NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification.metrics.axisDirection == AxisDirection.up || scrollNotification.metrics.axisDirection == AxisDirection.down) {
            widget.scrollStatusCallBack?.call(scrollNotification);
            if (scrollNotification is ScrollStartNotification) {
              widget.scrollStartCallBack?.call();
            } else if (scrollNotification is ScrollUpdateNotification) {
            } else if (scrollNotification is ScrollEndNotification) {
              if (scrollNotification.metrics.axisDirection == AxisDirection.up || scrollNotification.metrics.axisDirection == AxisDirection.down) {
                if (widget.scrollEndCallBack != null) {
                  double scrollPosition = _listController.position.pixels;
                  if (scrollPosition < 0) {
                    scrollPosition = 0;
                  }
                  widget.scrollEndCallBack?.call(lastPosition, scrollPosition);
                }
              }
            }
          }
          return true;
        },
        child: listViewWidget,
      );
    }
    return listViewWidget;
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (_isScrollingToTop) {
      return;
    }
    if (_listController.position == null) {
      return;
    }
    if (_listController.position.pixels > 0) {
      _isScrollingToTop = true;
      _listController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear).whenComplete(() {
        _isScrollingToTop = false;
      });
    }
  }

  void scrollTo(double scrollPixels) {
    if (_isScrollingToTop) {
      return;
    }
    if (_listController.position == null) {
      return;
    }
    if (scrollPixels >= 0 && _listController.position.pixels > 0) {
      _listController.jumpTo(scrollPixels);
    }
  }
}
