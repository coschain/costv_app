import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constant.dart';
import '../pages/webview/webview_page.dart';
import '../widget/route/slide_animation_route.dart';

class WebViewUtil {
  static WebViewUtil? _instance;

  factory WebViewUtil() => _getInstance();

  static WebViewUtil get instance => _getInstance();

  WebViewUtil._();

  static WebViewUtil _getInstance() {
    if (_instance == null) {
      _instance = WebViewUtil._();
    }
    return _instance!;
  }

  static const String CHANNEL_WEB_VIEW = "com.contentos.plugin/web_view";
  static const String WEB_VIEW_OPEN_WEB_VIEW = "open_web_view";
  static const String ARGUMENT_KEY_TITLE = "title";
  static const String ARGUMENT_KEY_URL = "url";
  static const String ARGUMENT_KEY_IS_DARK = "is_dark";
  static const _methodChannelWebView = const MethodChannel(CHANNEL_WEB_VIEW);

  openWebView(String url, BuildContext context, {String title = Constant.title}) {
    // _methodChannelWebView.invokeMethod(WEB_VIEW_OPEN_WEB_VIEW, {
    //   ARGUMENT_KEY_TITLE: title,
    //   ARGUMENT_KEY_URL: url,
    //   ARGUMENT_KEY_IS_DARK: AppThemeUtil.checkIsDarkMode(),
    // });
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return WebViewPage(url, title: title);
      },
    ));
  }

  Future<bool> openWebViewResult(String url, BuildContext context, {String title = Constant.title}) async{
    Navigator.of(context).push(SlideAnimationRoute(
      builder: (_) {
        return WebViewPage(url, title: title);
      },
    ));
    return false;
  }
}
