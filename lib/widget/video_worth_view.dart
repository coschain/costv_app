import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/common_util.dart';

class VideoWorthWidget extends StatelessWidget {

  final String _symbol,_amount;

  VideoWorthWidget(this._symbol, this._amount);

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.only(left: AppDimens.margin_6, right: AppDimens.margin_6, bottom: AppDimens.margin_1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppThemeUtil.setDifferentModeColor(
          lightColorStr: "FAF1D4",
          darkColorStr: "FAF1D4",
          darkAlpha: 0.9
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(22.0),
        ),
      ),
      child: DefaultTextStyle(
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Common.getColorFromHexString("D19900", 1.0),
          fontSize: 12.5,
          fontFamily: "DIN",
        ),
        child: Text(
          _getDesc(),
        ),
      ),

    );
  }

  String _getDesc() {
    String desc = "";
    if (_symbol.length > 0) {
      desc += _symbol + " ";
    }
    if (_amount.length > 0) {
      desc += _amount;
    }
    return desc;
  }

}