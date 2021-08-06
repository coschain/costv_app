import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:flutter/material.dart';

class VideoTimeWidget extends StatelessWidget {

  final String _time;

  VideoTimeWidget(this._time);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(AppDimens.margin_5),
      width: AppDimens.item_size_46,
      height: AppDimens.item_size_20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.color_000000,
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimens.radius_size_3),
        ),
      ),
      child: Text(
        _time ?? '0.0',
        style: AppStyles.text_style_ffffff_12,
      ),
    );
  }

}