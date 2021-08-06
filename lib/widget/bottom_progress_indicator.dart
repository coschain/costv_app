import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/material.dart';

class BottomProgressIndicator extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimens.item_size_50,
      height: AppDimens.item_size_50,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.radius_size_8),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

}