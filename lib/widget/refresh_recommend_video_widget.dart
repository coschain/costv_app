import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef RefreshRecommendVideoCallBack = Function();
class RefreshRecommendVideoWidget extends StatelessWidget {
  final bool isPortrait;
  final double maxWidth;
  final RefreshRecommendVideoCallBack refreshRecommendVideoCallBack;
  RefreshRecommendVideoWidget({
    this.isPortrait = true,
    this.refreshRecommendVideoCallBack,
    this.maxWidth = 200,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: this.maxWidth - 20,
      ),
      padding: isPortrait ? EdgeInsets.fromLTRB(26, 5, 26, 5) : EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: isPortrait ? Common.getColorFromHexString("3674FF", 1.0) : Colors.transparent,
        borderRadius: isPortrait ? BorderRadius.all(Radius.circular(15)) : BorderRadius.zero,
        ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (this.refreshRecommendVideoCallBack != null) {
            this.refreshRecommendVideoCallBack();
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildRefreshIcon(),
            _buildDesc(),
          ],
        ),
      ),

    );
  }

  ///刷新icon
  Widget _buildRefreshIcon() {
    return Container(
      child: Image.asset(
        "assets/images/icn_refresh.png",
      ),
    );
  }

  ///刷新列表的文字描述
  Widget _buildDesc() {
    double leftMargin = isPortrait ? 6.0 : 5.6;
    return Container(
      margin: EdgeInsets.only(left: leftMargin),
      child: Text(
        InternationalLocalizations.refreshList ?? '',
        style: TextStyle(
          fontSize: 14,
          color: Common.getColorFromHexString("FFFFFF", 1.0),
        ),
        maxLines: 1,
        textAlign: TextAlign.start,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

}