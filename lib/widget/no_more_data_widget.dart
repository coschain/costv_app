import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:flutter/material.dart';

class NoMoreDataWidget extends StatelessWidget {

  String bottomMessage;

  NoMoreDataWidget({
    this.bottomMessage,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if(bottomMessage == null){
      bottomMessage = InternationalLocalizations.noMoreData;
    }

    if (bottomMessage == '') {
      return Container();
    }
    return Container(
      margin: EdgeInsets.only(
          top: AppDimens.margin_25, bottom: AppDimens.margin_25),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: AppDimens.item_size_12_5,
            child: Divider(
              height: AppDimens.item_line_height_0_5,
              color: AppColors.color_c0c0c0,
            ),
          ),
          Container(
            padding: EdgeInsets.only(
                left: AppDimens.margin_10, right: AppDimens.margin_10),
            child: Text(
              bottomMessage,
              style: AppStyles.text_style_c0c0c0_14,
            ),
          ),
          Container(
            width: AppDimens.item_size_12_5,
            child: Divider(
              height: AppDimens.item_line_height_0_5,
              color: AppColors.color_c0c0c0,
            ),
          ),
        ],
      ),
    );
  }
}
