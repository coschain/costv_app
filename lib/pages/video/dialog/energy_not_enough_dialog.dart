import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EnergyNotEnoughDialog {
  final String _tag;
  final GlobalKey<ScaffoldState> _dialogSKey;
  final GlobalKey<ScaffoldState> _pageKey;
  StateSetter _stateSetter;
  String _time;
  BuildContext _context;

  EnergyNotEnoughDialog(this._tag, this._pageKey, this._dialogSKey);

  /// 初始化数据
  void initData(String timeMinutes) {
    _time = timeMinutes;
  }

  void show() {
    showDialog<int>(
      context: _pageKey.currentState.context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, state) {
          _context = context;
          _stateSetter = state;
          return Scaffold(
            key: _dialogSKey,
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            body: SimpleDialog(
              titlePadding: EdgeInsets.all(0.0),
              contentPadding: EdgeInsets.all(0.0),
              children: <Widget>[_buildDialog(context)],
            ),
          );
        });
      },
    );
  }

  Widget _buildDialog(BuildContext context) {
    return Container(
      width: AppDimens.item_size_290,
      color: AppColors.color_ffffff,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_40,
              right: AppDimens.margin_20,
              bottom: AppDimens.margin_40,
            ),
            child: Center(
              child: Text(
                InternationalLocalizations.energyNotEnoughTips(_time),
                style: AppStyles.text_style_a0a0a0_12,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Container(
                  height: AppDimens.item_size_40,
                  child: Material(
                    color: AppColors.color_3674ff,
                    child: MaterialButton(
                      child: Text(
                        InternationalLocalizations.confirm,
                        style: AppStyles.text_style_ffffff_14,
                      ),
                      onPressed: () {
                        Navigator.of(_context).pop();
                      },
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
