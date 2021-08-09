import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/triangle_painter.dart';
import 'package:flutter/material.dart';

class CommentHintWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(
              vertical: AppDimens.margin_12, horizontal: AppDimens.margin_15),
          margin: EdgeInsets.only(bottom: AppDimens.margin_9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.item_size_5),
            color: AppColors.color_3674ff,
          ),
          child: Text(
            InternationalLocalizations.commentHint,
            style: AppStyles.text_style_ffffff_12,
          ),
        ),
        CustomPaint(
          size: Size(AppDimens.item_size_20, AppDimens.item_size_20), //指定画布大小
          painter: TrianglePainter(AppColors.color_3674ff),
        )
      ],
    );
  }
}
