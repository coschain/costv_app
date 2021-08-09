import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final Duration aniDuration = Duration(milliseconds: 300);
bool _isShow = false;

class AppModeSwitchToast {
  static AppModeSwitchToastView preToast;

  static show(BuildContext context, bool isDarkMode) {
    preToast?.remove();
    preToast = null;
    var overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(builder: (context) {
      return AppModeSwitchToastWidget(isDarkMode);
    });
    var toastView = AppModeSwitchToastView();
    toastView.overlayEntry = overlayEntry;
    toastView.overlayState = overlayState;
    preToast = toastView;
    toastView._show();
  }
}

class AppModeSwitchToastView {
  OverlayEntry overlayEntry;
  OverlayState overlayState;
  bool dismissed = false;

  _show() async {
    _isShow = true;
    overlayState.insert(overlayEntry);
    Future.delayed(Duration(seconds: 1), () {
      this.dismiss();
    });
  }

  dismiss() async {
    if (dismissed) {
      return;
    }
    this.dismissed = true;
    _isShow = false;
    overlayEntry.markNeedsBuild();
    await Future.delayed(aniDuration);
    overlayEntry?.remove();
  }

  remove() async {
    this.dismissed = true;
    overlayEntry?.remove();
    overlayEntry = null;
  }

}

class AppModeSwitchToastWidget extends StatelessWidget {
  final bool isDarkMode;
  AppModeSwitchToastWidget(this.isDarkMode);
  @override
  Widget build(BuildContext context) {
    String desc = InternationalLocalizations.lightModeDesc;
    String icnPath = "assets/images/light_mode_toast.png";
    if (isDarkMode) {
      desc = InternationalLocalizations.darkModeDesc;
      icnPath = "assets/images/dark_mode_toast.png";
    }
    return Align(
      alignment: FractionalOffset.center,
      child: AnimatedOpacity(
        opacity: _isShow ? 1.0 : 0.0,
        duration: aniDuration,
        child: Container(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width - 68*2,
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 15,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Common.getColorFromHexString("000000", 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                //图标
                Container(
                  child: Image.asset(
                    icnPath,
                    fit: BoxFit.contain,
                  ),
                ),
                //描述
                Container(
                  margin: EdgeInsets.only(top: 10),
                  child: Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Common.getColorFromHexString("FFFFFF", 1.0),
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}