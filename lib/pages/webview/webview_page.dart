import 'dart:async';
import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/web_page_api_data_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/db/login_info_db_bean.dart';
import 'package:costv_android/db/login_info_db_provider.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/login_status_event.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/video/bean/video_detail_page_params_bean.dart';
import 'package:costv_android/pages/video/video_details_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter_fix/webview_flutter.dart';
import 'package:costv_android/widget/app_bar_back_widget.dart';

const String kNavigationExamplePage = '''
<!DOCTYPE html><html>
<head><title>Navigation Delegate Example</title></head>
<body>
<p>
The navigation delegate is set to block navigation to the youtube website.
</p>
<ul>
<ul><a href="https://www.youtube.com/">https://www.youtube.com/</a></ul>
<ul><a href="https://www.google.com/">https://www.google.com/</a></ul>
</ul>
</body>
</html>
''';

class WebViewPage extends StatefulWidget {
  final String _url;
  final String title;

  WebViewPage(this._url, {this.title = "COS.TV"});

  @override
  _WebViewState createState() => _WebViewState();
}

class _WebViewState extends State<WebViewPage> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  WebViewController _webViewController;

  static const tag = '_WebViewState';
  GlobalObjectKey<WebViewProgressBarState> _progressKey;

  @override
  void initState() {
    super.initState();
    _progressKey = GlobalObjectKey<WebViewProgressBarState>(
        widget._url ?? "" + DateTime.now().toString());
  }

  @override
  void dispose() {
    super.dispose();
    RequestManager.instance.cancelAllNetworkRequest(tag);
    if (_webViewController != null) {
      _webViewController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    CosLogUtil.log("WebViewPage: url is ${widget._url}");
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
          actions: <Widget>[
            GestureDetector(
              child: Image.asset('assets/images/ic_close_black.png'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
//            NavigationControls(_controller.future),
          ],
          leading: AppBarBackWidget(),
          centerTitle: true,
          title: Text(
              widget.title ?? "",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15
              )
          ),
          backgroundColor: Common.getColorFromHexString("FFFFFF", 1.0),
          elevation: 0,
        ),
        body: Builder(builder: (BuildContext context) {
          return Column(
            children: <Widget>[
              //进度条
              WebViewProgressBar(
                key: _progressKey,
              ),
              //webView
              Expanded(
                child: WebView(
                  initialUrl: widget._url,
                  javascriptMode: JavascriptMode.unrestricted,
//          debuggingEnabled: true,
                  onWebViewCreated: (WebViewController webViewController) {
                    _webViewController = webViewController;
                    _controller.complete(webViewController);
                    CosLogUtil.log('$tag onWebViewCreated');
                  },
                  // TODO(iskakaushik): Remove this when collection literals makes it to stable.
                  // ignore: prefer_collection_literals
                  javascriptChannels: <JavascriptChannel>[
                    _toasterJavascriptChannel(context),
                    _clientJavascriptChannel(context),
                  ].toSet(),
                  navigationDelegate: (NavigationRequest request) {
                    if (request.url.startsWith(Constant.costvWebOrigin)) {
                      Uri uri;
                      try {
                        uri = Uri.parse(request.url);
                      } catch (error) {
                        CosLogUtil.log('$tag Parse web url error: $error');
                        return NavigationDecision.prevent;
                      }

                      if (uri != null &&
                          uri.path.startsWith(
                              Constant.webPageVideoPlayPathLeading) &&
                          uri.pathSegments.length ==
                              Constant.webPageVideoPlayPathSegmentsLength) {
                        String vid = uri.pathSegments[2];
                        if (!TextUtil.isEmpty(vid)) {
                          CosLogUtil.log(
                              '$tag blocking navigation to $request');
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) {
                            return VideoDetailsPage(
                                VideoDetailPageParamsBean.createInstance(
                                    vid: vid));
                          }));
                          return NavigationDecision.prevent;
                        }
                      }
                    }

                    CosLogUtil.log('$tag allowing navigation to $request');
                    return NavigationDecision.navigate;
                  },
                  onPageFinished: (String url) {
                    CosLogUtil.log('$tag Page finished loading: $url');
                  },
                  onProgressChanged: (int progress) {
                    CosLogUtil.log('$tag Page onProgressChanged: $progress');
                    if (_progressKey != null &&
                        _progressKey.currentState != null) {
                      _progressKey.currentState.updateProgress(progress);
                    }
                  },
                ),
              ),
            ],
          );
        }),
      ),
      onWillPop: () async {
        bool canGoBack = await _webViewController.canGoBack();
        if (canGoBack) {
          _webViewController.goBack();
        } else {
          Navigator.of(context).pop();
        }
        return;
      },
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  JavascriptChannel _clientJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'costvClient',
        onMessageReceived: (JavascriptMessage message) async {
          CosLogUtil.log('$tag _clientJavascriptChannel = ${message.message}');
          WebPageApiDataBean webPageApiBean =
              WebPageApiDataBean.fromJson(json.decode(message.message));
          String action = webPageApiBean.action;
          String data = webPageApiBean.data;
          switch (action) {
            case WebPageApiDataBean.actionAccessTokenInfo:
              WebPageApiAccessTokenInfoBean bean =
                  WebPageApiAccessTokenInfoBean.fromJson(json.decode(data));
              if (bean != null &&
                  bean.uid != null &&
                  !ObjectUtil.isEmptyString(bean.token) &&
                  !ObjectUtil.isEmptyString(bean.chainAccountName) &&
                  bean.expires != null) {
                Constant.uid = bean.uid;
                Constant.token = bean.token;
                Constant.accountName = bean.chainAccountName;
                LoginInfoDbBean loginInfoDbBean = LoginInfoDbBean(
                    bean.uid, bean.token, bean.chainAccountName, bean.expires);
                CosLogUtil.log(
                    '$tag _clientJavascriptChannel costvClient\nLoginInfoDbBean{ uid: ${bean.uid}, token: ${bean.token}, chainAccountName: ${bean.chainAccountName}, expires: ${bean.expires}');
                LoginInfoDbProvider loginInfoDbProvider = LoginInfoDbProvider();
                try {
                  await loginInfoDbProvider.open();
                  LoginInfoDbBean loginInfoDbOld =
                      await loginInfoDbProvider.getLoginInfoDbBean();
                  if (loginInfoDbOld == null) {
                    await loginInfoDbProvider.insert(loginInfoDbBean);
                  } else {
                    await loginInfoDbProvider.update(loginInfoDbBean);
                  }
                } catch (e) {
                  CosLogUtil.log("$tag: e = $e");
                } finally {
                  await loginInfoDbProvider.close();
                }
                LoginStatusEvent loginStatusEvent =
                    LoginStatusEvent(LoginStatusEvent.typeLoginSuccess);
                loginStatusEvent.uid = bean.uid;
                EventBusHelp.getInstance().fire(loginStatusEvent);
                Navigator.pop(context, true);
              }
              break;
            case WebPageApiDataBean.actionLogout:
              Constant.uid = null;
              Constant.token = null;
              Constant.accountName = null;
              LoginInfoDbProvider loginInfoDbProvider = LoginInfoDbProvider();
              try {
                await loginInfoDbProvider.open();
                await loginInfoDbProvider.deleteAll();
              } catch (e) {
                CosLogUtil.log("$tag: e = $e");
              } finally {
                await loginInfoDbProvider.close();
              }
              EventBusHelp.getInstance()
                  .fire(LoginStatusEvent(LoginStatusEvent.typeLogoutSuccess));
              Navigator.pop(context);
              break;
            case WebPageApiDataBean.actionOpenVideoPlayPage:
              WebPageApiVideoIdBean webPageApiVideoIdBean =
                  WebPageApiVideoIdBean.fromJson(json.decode(data));
              String vid = webPageApiVideoIdBean.vid;

              Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                return VideoDetailsPage(
                    VideoDetailPageParamsBean.createInstance(vid: vid));
              }));
              break;
            case WebPageApiDataBean.actionHideTextInput:
              SystemChannels.textInput.invokeMethod('TextInput.hide');
              break;
            default:
          }
        });
  }
}

enum MenuOptions {
  showUserAgent,
  listCookies,
  clearCookies,
  addToCache,
  listCache,
  clearCache,
  navigationDelegate,
}

class SampleMenu extends StatelessWidget {
  SampleMenu(this.controller);

  final Future<WebViewController> controller;
  final CookieManager cookieManager = CookieManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        return PopupMenuButton<MenuOptions>(
          onSelected: (MenuOptions value) {
            switch (value) {
              case MenuOptions.showUserAgent:
                _onShowUserAgent(controller.data, context);
                break;
              case MenuOptions.listCookies:
                _onListCookies(controller.data, context);
                break;
              case MenuOptions.clearCookies:
                _onClearCookies(context);
                break;
              case MenuOptions.addToCache:
                _onAddToCache(controller.data, context);
                break;
              case MenuOptions.listCache:
                _onListCache(controller.data, context);
                break;
              case MenuOptions.clearCache:
                _onClearCache(controller.data, context);
                break;
              case MenuOptions.navigationDelegate:
                _onNavigationDelegateExample(controller.data, context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.showUserAgent,
              child: const Text('Show user agent'),
              enabled: controller.hasData,
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCookies,
              child: Text('List cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCookies,
              child: Text('Clear cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.addToCache,
              child: Text('Add to cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCache,
              child: Text('List cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCache,
              child: Text('Clear cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.navigationDelegate,
              child: Text('Navigation Delegate example'),
            ),
          ],
        );
      },
    );
  }

  void _onShowUserAgent(
      WebViewController controller, BuildContext context) async {
    // Send a message with the user agent string to the Toaster JavaScript channel we registered
    // with the WebView.
    controller.evaluateJavascript(
        'Toaster.postMessage("User Agent: " + navigator.userAgent);');
  }

  void _onListCookies(
      WebViewController controller, BuildContext context) async {
    final String cookies =
        await controller.evaluateJavascript('document.cookie');
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Cookies:'),
          _getCookieList(cookies),
        ],
      ),
    ));
  }

  void _onAddToCache(WebViewController controller, BuildContext context) async {
    await controller.evaluateJavascript(
        'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Added a test entry to cache.'),
    ));
  }

  void _onListCache(WebViewController controller, BuildContext context) async {
    await controller.evaluateJavascript('caches.keys()'
        '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
        '.then((caches) => Toaster.postMessage(caches))');
  }

  void _onClearCache(WebViewController controller, BuildContext context) async {
    await controller.clearCache();
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text("Cache cleared."),
    ));
  }

  void _onClearCookies(BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, they are gone!';
    if (!hadCookies) {
      message = 'There are no cookies.';
    }
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  void _onNavigationDelegateExample(
      WebViewController controller, BuildContext context) async {
    final String contentBase64 =
        base64Encode(const Utf8Encoder().convert(kNavigationExamplePage));
    controller.loadUrl('data:text/html;base64,$contentBase64');
  }

  Widget _getCookieList(String cookies) {
    if (cookies == null || cookies == '""') {
      return Container();
    }
    final List<String> cookieList = cookies.split(';');
    final Iterable<Text> cookieWidgets =
        cookieList.map((String cookie) => Text(cookie));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: cookieWidgets.toList(),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture)
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                      if (await controller.canGoBack()) {
                        controller.goBack();
                      } else {
                        Scaffold.of(context).showSnackBar(
                          const SnackBar(content: Text("No back history item")),
                        );
                        return;
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                      if (await controller.canGoForward()) {
                        controller.goForward();
                      } else {
                        Scaffold.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("No forward history item")),
                        );
                        return;
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: !webViewReady
                  ? null
                  : () {
                      controller.reload();
                    },
            ),
          ],
        );
      },
    );
  }
}

class WebViewProgressBar extends StatefulWidget {
  WebViewProgressBar({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return WebViewProgressBarState();
  }
}

class WebViewProgressBarState extends State<WebViewProgressBar>
    with SingleTickerProviderStateMixin {
  bool isAnimating = false;
  int curProgress = 0;
  AnimationController _controller;
  Animation<double> _widthAni;
  double barOpacity = 1.0, progressWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _widthAni = Tween<double>(begin: 0.0, end: 0.0).animate(_controller)
      ..addListener(updateState)
      ..addStatusListener(listenAnimationStatus);
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller.stop(canceled: true);
      _controller.dispose();
    }
    if (_widthAni != null) {
      _widthAni.removeListener(updateState);
      _widthAni.removeStatusListener(listenAnimationStatus);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: <Widget>[
        Container(
          height: 2,
          width: screenWidth,
          color: Common.getColorFromHexString("E9E9EA ", 1),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Opacity(
            opacity: barOpacity,
            child: Container(
              color: Common.getColorFromHexString("3674FF", 1.0),
              height: 2,
              width: _widthAni.value,
            ),
          ),
        ),
      ],
    );
  }

  void updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  void updateProgress(int progress) {
    if (progress > curProgress && mounted) {
      if (!isAnimating) {
        isAnimating = true;
        if (_controller == null) {
          _controller = AnimationController(
              duration: const Duration(milliseconds: 100), vsync: this);
        }
        double screenWidth = MediaQuery.of(context).size.width;
        double oldWidth = screenWidth * (curProgress / 100);
        double newWidth = screenWidth * (progress / 100);
        _controller.reset();
        _widthAni =
            Tween<double>(begin: oldWidth, end: newWidth).animate(_controller);

        try {
          _controller.forward();
        } on TickerCanceled {}
      }
      curProgress = progress;
    }
  }

  void listenAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
    } else if (status == AnimationStatus.reverse) {
    } else if (status == AnimationStatus.completed) {
      isAnimating = false;
      if (curProgress == 100 && mounted) {
        //加载完成,隐藏进度条
        barOpacity = 0;
        setState(() {});
      }
    } else if (status == AnimationStatus.dismissed) {
      isAnimating = false;
    }
  }
}
