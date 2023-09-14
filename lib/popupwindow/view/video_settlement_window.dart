import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/video/bean/video_settlement_bean.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:flutter/material.dart';

class VideoSettlementWindow extends StatefulWidget {
  final VideoSettlementBean _bean;

  VideoSettlementWindow(this._bean);

  @override
  State<StatefulWidget> createState() {
    return VideoSettlementWindowState();
  }
}

class VideoSettlementWindowState extends State<VideoSettlementWindow> with WidgetsBindingObserver{
  late VideoSettlementBean _bean;

  @override
  void initState() {
    _bean = widget._bean;
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String time;
    if (_bean.getVestStatus == VideoInfoResponse.vestStatusFinish) {
      time =
      '${InternationalLocalizations.videoSettlementTime}：${_bean
          .getSettlementTime}';
    } else {
      time =
      '${_bean.getSettlementTime}${InternationalLocalizations
          .videoSettlementTimeFuture}';
    }
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(left: AppDimens.margin_162),
          child: Image.asset(AppThemeUtil.getSettlementTriangle()),
        ),
        Container(
          margin: EdgeInsets.only(top: AppThemeUtil.checkIsDarkMode() ? 0 : AppDimens.margin_3),
          child: Card(
            color: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_ffffff,
              darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
            ),
            elevation: AppDimens.item_size_10,
            child: Container(
              width: AppDimens.item_size_220,
              padding: EdgeInsets.only(
                  top: AppDimens.margin_10, bottom: AppDimens.margin_10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(
                        left: AppDimens.margin_10, right: AppDimens.margin_10),
                    child: Text(
                      '${InternationalLocalizations.videoRevenueTotal} ${_bean
                          .getMoneySymbol} ${_bean.getTotalRevenue}',
                      style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_333333,
                          darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                        ),
                        fontSize: AppDimens.text_size_13,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        left: AppDimens.margin_10, right: AppDimens.margin_10),
                    child: Text(
                      '${InternationalLocalizations
                          .videoRevenueTotalVest}：${_bean
                          .getTotalRevenueVest}${InternationalLocalizations
                          .videoVest}',
                      style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_333333,
                          darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                        ),
                        fontSize: AppDimens.text_size_13,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        top: AppDimens.margin_10,
                        bottom: AppDimens.margin_10),
                    height: AppDimens.item_line_height_0_5,
                    color: AppColors.color_e4e4e4,
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        left: AppDimens.margin_10, right: AppDimens.margin_10),
                    child: Text(
                      '${InternationalLocalizations.videoSettlementBonus}：${_bean
                          .getMoneySymbol} ${_bean
                          .getSettlementBonus}/${InternationalLocalizations
                          .videoAbout} ${_bean
                          .getSettlementBonusVest}${InternationalLocalizations
                          .videoVest}',
                      style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_333333,
                          darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                        ),
                        fontSize: AppDimens.text_size_13,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        left: AppDimens.margin_10, right: AppDimens.margin_10),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_333333,
                          darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                        ),
                        fontSize: AppDimens.text_size_13,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        left: AppDimens.margin_10, right: AppDimens.margin_10),
                    child: Text(
                      '${InternationalLocalizations.videoGiftRevenue}：${_bean
                          .getMoneySymbol} ${_bean
                          .getGiftRevenue}/${InternationalLocalizations
                          .videoAbout} ${_bean
                          .getGiftRevenueVest}${InternationalLocalizations
                          .videoVest}',
                      style: TextStyle(
                        color: AppThemeUtil.setDifferentModeColor(
                          lightColor: AppColors.color_333333,
                          darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
                        ),
                        fontSize: AppDimens.text_size_13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }


  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (!isSwitchedModeByUser) {
      setState(() {

      });
    }
  }
}

