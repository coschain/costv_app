import 'dart:ui';

import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/app_update_version_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/platform_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateDialog {
  bool _isForceUpdate = true;
  String _title, _message = '';
  String _downloadUrl;
  String _googlePlayUrl;

  Future<void> initData(AppUpdateVersionDataBean bean) async {
    _googlePlayUrl =
        'market://details?id=${await PlatformUtil.getPackageName()}';
    if (bean != null) {
      if (bean.type != AppUpdateVersionDataBean.typeForceUpdate) {
        _isForceUpdate = false;
      }
      if (!ObjectUtil.isEmptyString(bean.vercode)) {
        _title = InternationalLocalizations.updateTitle(bean.vercode);
      } else {
        _title = InternationalLocalizations.updateTitle(
            await PlatformUtil.getVersion());
      }
      if (!ObjectUtil.isEmptyString(bean.updateInfo)) {
        _message = bean.updateInfo;
      }
      _downloadUrl = bean.downloadUrl;
    } else {
      _title = InternationalLocalizations.updateTitle(
          await PlatformUtil.getVersion());
    }
  }

  Widget _buildAppUpdateBody(BuildContext context) {
    Widget body = Align(
      alignment: Alignment.topCenter,
      child: Container(
        color: AppColors.color_transparent,
        width: MediaQuery.of(context).size.width - AppDimens.margin_20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Image.asset(
                    'assets/images/ic_update_app_top_bg.png',
                    fit: BoxFit.fitWidth,
                  ),
                )
              ],
            ),
            Container(
                color: AppColors.color_ffffff,
                padding: EdgeInsets.all(AppDimens.margin_16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _title ?? '',
                      style: AppStyles.text_style_000000_bold_15,
                    ),
                    Container(
                      padding: EdgeInsets.only(
                          top: AppDimens.margin_10, bottom: AppDimens.margin_10),
                      child: Text(
                        _message ?? '',
                        style: AppStyles.text_style_666666_14,
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: MaterialButton(
                            height: AppDimens.item_size_40,
                            color: AppColors.color_3ac1e9,
                            child: Text(
                              InternationalLocalizations.updateConfirm,
                              style: AppStyles.text_style_ffffff_15,
                            ),
                            onPressed: () async {
                              if (!ObjectUtil.isEmptyString(_downloadUrl)) {
                                if (await canLaunch(_downloadUrl)) {
                                  await launch(_downloadUrl);
                                } else {
                                  if (await canLaunch(_googlePlayUrl)) {
                                    await launch(_googlePlayUrl);
                                  }
                                }
                              } else {
                                if (await canLaunch(_googlePlayUrl)) {
                                  await launch(_googlePlayUrl);
                                }
                              }
                            },
                          ),
                        )
                      ],
                    )
                  ],
                )),
          ],
        ),
      ),
    );
    if (_isForceUpdate) {
      return WillPopScope(
        child: body,
        onWillPop: () async {
          return Future.value(false);
        },
      );
    } else {
      return body;
    }
  }

  void showAppUpdateDialog(BuildContext context) {
    Widget widget = SimpleDialog(
      titlePadding: EdgeInsets.all(0.0),
      contentPadding: EdgeInsets.all(0.0),
      backgroundColor: AppColors.color_transparent,
      children: <Widget>[_buildAppUpdateBody(context)],
    );
    Widget body;
    if (!_isForceUpdate) {
      body = Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.color_transparent,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: widget,
          onTap: () {
            Navigator.pop(context);
          },
        ),
      );
    } else {
      body = Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.color_transparent,
        body: widget,
      );
    }
    showDialog<int>(
      context: context,
      barrierDismissible: !_isForceUpdate,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, state) {
          return body;
        });
      },
    );
  }
}
