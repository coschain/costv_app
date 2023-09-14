import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'
    as webview_flutter_android;
import 'package:path_provider/path_provider.dart';

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

  late WebViewController _webViewController;

  static const tag = '_WebViewState';
  late GlobalObjectKey<WebViewProgressBarState> _progressKey;

  @override
  void initState() {
    super.initState();
    _progressKey = GlobalObjectKey<WebViewProgressBarState>(
        widget._url ?? "" + DateTime.now().toString());
    late final PlatformWebViewControllerCreationParams params;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Toaster',
          onMessageReceived: (JavaScriptMessage message) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text(message.message)),
        );
      })
      ..addJavaScriptChannel('costvClient',
          onMessageReceived: (JavaScriptMessage message) async {
        CosLogUtil.log('$tag _clientJavascriptChannel = ${message.message}');
        WebPageApiDataBean webPageApiBean =
            WebPageApiDataBean.fromJson(json.decode(message.message));
        String action = webPageApiBean.action;
        String data = webPageApiBean.data;
        switch (action) {
          case WebPageApiDataBean.actionAccessTokenInfo:
            WebPageApiAccessTokenInfoBean bean =
                WebPageApiAccessTokenInfoBean.fromJson(json.decode(data));
            if (!ObjectUtil.isEmptyString(bean.token) &&
                !ObjectUtil.isEmptyString(bean.chainAccountName)) {
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
                LoginInfoDbBean? loginInfoDbOld =
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
              LoginStatusEvent? loginStatusEvent =
                  LoginStatusEvent(LoginStatusEvent.typeLoginSuccess);
              loginStatusEvent.uid = bean.uid;
              EventBusHelp.getInstance().fire(loginStatusEvent);
              Navigator.pop(this.context, true);
            }
            break;
          case WebPageApiDataBean.actionLogout:
            Constant.uid = "";
            Constant.token = "";
            Constant.accountName = "";
            LoginInfoDbProvider loginInfoDbProvider = LoginInfoDbProvider();
            try {
              await loginInfoDbProvider.open();
              await loginInfoDbProvider.deleteAll();
            } catch (e) {
              CosLogUtil.log("$tag: e = $e");
            } finally {
              await loginInfoDbProvider.close();
            }

            usrAutoPlaySetting = false;

            EventBusHelp.getInstance()
                .fire(LoginStatusEvent(LoginStatusEvent.typeLogoutSuccess));
            Navigator.pop(this.context);
            break;
          case WebPageApiDataBean.actionOpenVideoPlayPage:
            WebPageApiVideoIdBean webPageApiVideoIdBean =
                WebPageApiVideoIdBean.fromJson(json.decode(data));
            Navigator.of(this.context).push(SlideAnimationRoute(
              builder: (_) {
                return VideoDetailsPage(
                    VideoDetailPageParamsBean.createInstance(
                  vid: webPageApiVideoIdBean.vid ?? '',
                  uid: webPageApiVideoIdBean.fuid ?? '',
                  enterSource: VideoDetailsEnterSource
                      .VideoDetailsEnterSourceH5WorksOrDynamic,
                ));
              },
              settings: RouteSettings(name: videoDetailPageRouteName),
              isCheckAnimation: true,
            ));
            break;
          case WebPageApiDataBean.actionHideTextInput:
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            break;
          default:
        }
      })
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            CosLogUtil.log('$tag Page onProgressChanged: $progress');
            if (_progressKey.currentState != null) {
              _progressKey.currentState?.updateProgress(progress);
            }
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            CosLogUtil.log('$tag Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(Constant.costvWebOrigin)) {
              Uri uri;
              try {
                uri = Uri.parse(request.url);
              } catch (error) {
                CosLogUtil.log('$tag Parse web url error: $error');
                return NavigationDecision.prevent;
              }

              if (uri.path.startsWith(Constant.webPageVideoPlayPathLeading) &&
                  uri.pathSegments.length ==
                      Constant.webPageVideoPlayPathSegmentsLength) {
                String vid = uri.pathSegments[2];
                if (!TextUtil.isEmpty(vid)) {
                  CosLogUtil.log('$tag blocking navigation to $request');
                  Navigator.of(this.context).push(SlideAnimationRoute(
                    builder: (_) {
                      return VideoDetailsPage(
                          VideoDetailPageParamsBean.createInstance(
                        vid: vid,
                        enterSource: VideoDetailsEnterSource
                            .VideoDetailsEnterSourceH5LikeRewardVideo,
                      ));
                    },
                    settings: RouteSettings(name: videoDetailPageRouteName),
                    isCheckAnimation: true,
                  ));
                  return NavigationDecision.prevent;
                }
              }
            }

            CosLogUtil.log('$tag allowing navigation to $request');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget._url));
    handleAndroidMediaUpload();
  }

  void handleAndroidMediaUpload() async {
    final controller = (_webViewController.platform
        as webview_flutter_android.AndroidWebViewController);
    await controller.setOnShowFileSelector(_androidFilePicker);
  }

  Future<List<String>> _androidFilePicker(
      webview_flutter_android.FileSelectorParams params) async {
    final media = await ImagePicker().pickMedia();

    if (media == null) {
      return [];
    }

    final filePath = (await getTemporaryDirectory()).uri.resolve(
          './media_${DateTime.now().microsecondsSinceEpoch}${extension(media.path)}',
        );

    final file = await File.fromUri(filePath).create(recursive: true);

    await file.writeAsBytes(await media.readAsBytes(), flush: true);

    return [file.uri.toString()];
  }

  @override
  void dispose() {
    super.dispose();
    RequestManager.instance.cancelAllNetworkRequest(tag);
  }

  @override
  Widget build(BuildContext context) {
    CosLogUtil.log("WebViewPage: url is ${widget._url}");
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
              actions: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Image.asset('assets/images/ic_close_black.png'),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
              leading: Material(
                child: Ink(
                  color: Common.getColorFromHexString("FFFFFFFF", 1.0),
                  child: InkWell(
                    onTap: () async {
                      bool canGoBack = await _webViewController.canGoBack();
                      if (canGoBack) {
                        _webViewController.goBack();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(left: 16),
                            child: GestureDetector(
                              child: Image.asset(
                                'assets/images/ic_back.png',
                                width: 7,
                                height: 14,
                                fit: BoxFit.cover,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              centerTitle: true,
              title: Text(widget.title ?? "",
                  style: TextStyle(color: Colors.black, fontSize: 15)),
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
                    child: WebViewWidget(
                      controller: _webViewController,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
      onWillPop: () async {
        bool canGoBack = await _webViewController.canGoBack();
        if (canGoBack) {
          _webViewController.goBack();
          return false;
        } else {
          return true;
        }
      },
    );
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
  final WebViewCookieManager cookieManager = WebViewCookieManager();

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
                // _onNavigationDelegateExample(controller.data, context);
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
      WebViewController? controller, BuildContext context) async {
    // Send a message with the user agent string to the Toaster JavaScript channel we registered
    // with the WebView.
    controller?.runJavaScript(
        'Toaster.postMessage("User Agent: " + navigator.userAgent);');
  }

  void _onListCookies(
      WebViewController? controller, BuildContext context) async {
    final String cookies = await controller
        ?.runJavaScriptReturningResult('document.cookie') as String;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
  }

  void _onAddToCache(
      WebViewController? controller, BuildContext context) async {
    await controller?.runJavaScript(
        'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Added a test entry to cache.'),
    ));
  }

  void _onListCache(WebViewController? controller, BuildContext context) async {
    await controller?.runJavaScript('caches.keys()'
        '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
        '.then((caches) => Toaster.postMessage(caches))');
  }

  void _onClearCache(
      WebViewController? controller, BuildContext context) async {
    await controller?.clearCache();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Cache cleared."),
    ));
  }

  void _onClearCookies(BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, they are gone!';
    if (!hadCookies) {
      message = 'There are no cookies.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

// Future<void> _onNavigationDelegateExample( WebViewController controller, BuildContext context) async {
//   final String contentBase64 = base64Encode(
//     const Utf8Encoder().convert(kNavigationExamplePage),
//   );
//   return controller.loadRequest(
//     LoadRequestParams(
//       uri: Uri.parse('data:text/html;base64,$contentBase64'),
//     ),
//   );
}

Widget _getCookieList(String cookies) {
  if (cookies == '""') {
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

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController? controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                      if (await controller?.canGoBack() ?? false) {
                        controller?.goBack();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
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
                      if (await controller?.canGoForward() ?? false) {
                        controller?.goForward();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
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
                      controller?.reload();
                    },
            ),
          ],
        );
      },
    );
  }
}

class WebViewProgressBar extends StatefulWidget {
  WebViewProgressBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return WebViewProgressBarState();
  }
}

class WebViewProgressBarState extends State<WebViewProgressBar>
    with SingleTickerProviderStateMixin {
  bool isAnimating = false;
  int curProgress = 0;
  late AnimationController _controller;
  late Animation<double> _widthAni;
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
    _controller.stop(canceled: true);
    _controller.dispose();
    _widthAni.removeListener(updateState);
    _widthAni.removeStatusListener(listenAnimationStatus);
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
        double screenWidth = MediaQuery.of(this.context).size.width;
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
