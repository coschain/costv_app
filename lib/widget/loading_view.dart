import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 加载中控件
class LoadingView extends StatelessWidget {
  final Widget child;
  final bool isShow;

  LoadingView({@required this.child, @required this.isShow}) {
    assert(this.child != null || this.isShow != null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        isShow
            ? Align(
                alignment: FractionalOffset.center,
                child: new SizedBox(
                  height: AppDimens.item_size_70,
                  width: AppDimens.item_size_70,
                  child: Container(
                      color: AppColors.color_transparent,
                      child: Padding(
                          padding: EdgeInsets.all(AppDimens.margin_15),
                          child: new CircularProgressIndicator())),
                ),
              )
            : Container()
      ],
    );
  }
}
