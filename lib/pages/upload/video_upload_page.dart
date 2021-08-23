import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:costv_android/language/international_localizations.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/video_category_bean.dart';
import 'package:costv_android/bean/video_tags_bean.dart';
import 'package:costv_android/bean/video_upload_sign_bean.dart';
import 'package:costv_android/pages/upload/video_upload_form.dart';
import 'package:costv_android/pages/upload/video_upload_appbar.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/login_status_event.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/widget/page_remind_widget.dart';
import 'package:costv_android/utils/web_view_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


class VideoUploadPage extends StatefulWidget {
  final String uid;
  final String videoPath;

  VideoUploadPage({this.uid, this.videoPath, Key key})
      : super(key: key);

  @override
  _VideoUploadPageState createState() => _VideoUploadPageState(uid, videoPath);
}

enum VideoUploadPageContents {
  LoginTips,
  UploadInit,
  UploadInitFail,
  Upload,
  UploadOK,
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  static const String tag = '_VideoUploadPageState';

  StreamSubscription _eventSubscription;
  bool _uploadOK = false;
  String _uid;
  String _videoPath;
  List _sysTags = [];
  List _categories = [];
  String _tvcSignature;
  String _coverPath;
  bool _initOK = false;
  bool _showLoginLoading = false;

  _VideoUploadPageState(this._uid, this._videoPath);

  @override
  void initState() {
    super.initState();
    _listenEvent();
    if (!ObjectUtil.isEmptyString(_uid)) {
      _initData();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    var contentType = _contents();
    switch(contentType) {
      case VideoUploadPageContents.LoginTips:
        body = _getLoginTipsWidget();
        break;
      case VideoUploadPageContents.UploadInit:
        body = _getUploadInitWidget();
        break;
      case VideoUploadPageContents.UploadInitFail:
        body = _getInitFailWidget();
        break;
      case VideoUploadPageContents.Upload:
        body = _getUploadWidget();
        break;
      case VideoUploadPageContents.UploadOK:
        body = _getUploadOKWidget();
        break;
      default:
        body = Container();
        break;
    }
    return body;
  }

  Widget _getLoginTipsWidget() {
    return Scaffold(
      appBar: VideoUploadAppbar(
        title: InternationalLocalizations.uploadAppbarBack,
        onBack: (){
          Navigator.of(context).pop();
        },
        buttonText: "",
        buttonTextColor: Colors.transparent,
        onButtonTapped: () {
        },
      ),
      body: Stack(
        children: <Widget>[
          PageRemindWidget(
            clickCallBack: () {
              if (Platform.isAndroid) {
                WebViewUtil.instance.openWebView(Constant.logInWebViewUrl);
              } else {
                Navigator.of(context).push(SlideAnimationRoute(
                  builder: (_) {
                    return WebViewPage(
                      Constant.logInWebViewUrl,
                    );
                  },
                ));
              }
            },
            remindType: RemindType.VideoUploadPageLogIn,
          ),
          _showLoginLoading? _buildLoading(context) : Container(),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      color: Color(0x40000000),
      child: Align(
        alignment: FractionalOffset.center,
        child: new SizedBox(
          height: 70,
          width: 70,
          child: Container(
              color: AppColors.color_transparent,
              child: Padding(
                  padding: EdgeInsets.all(15),
                  child: CircularProgressIndicator())),
        ),
      ),
    );
  }

  Widget _getUploadOKWidget() {
    return Scaffold(
      body: Container(
        color: AppThemeUtil.setDifferentModeColor(
          lightColor: AppColors.color_f6f6f6,
          darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
        ),
        child: PageRemindWidget(
          clickCallBack: () {
            Navigator.of(context).pop();
          },
          remindType: RemindType.VideoUploadPageSuccess,
        ),
      ),
    );
  }

  Widget _getInitFailWidget() {
    return Scaffold(
      body: Container(
        color: AppThemeUtil.setDifferentModeColor(
          lightColor: AppColors.color_f6f6f6,
          darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
        ),
        child: PageRemindWidget(
          clickCallBack: () {
            _initData();
            setState(() {});
          },
          remindType: RemindType.NetRequestFail,
        ),
      ),
    );
  }

  Widget _getUploadInitWidget() {
    return VideoUploadForm(
      loading: true,
    );
  }

  Widget _getUploadWidget() {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: VideoUploadForm(
        videoPath: _videoPath,
        thumbnailPath: _coverPath,
        categories: _categories,
        sysTags: _sysTags,
        tvcSignature: _tvcSignature,
        onSuccess: (){
          setState(() {
            _uploadOK = true;
          });
        },
      ),
    );
  }

  VideoUploadPageContents _contents() {
    if (ObjectUtil.isEmptyString(_uid)) {
      return VideoUploadPageContents.LoginTips;
    }
    if (_uploadOK) {
      return VideoUploadPageContents.UploadOK;
    }
    if (_initOK == null) {
      return VideoUploadPageContents.UploadInit;
    }
    if (_initOK) {
      return VideoUploadPageContents.Upload;
    }
    return VideoUploadPageContents.UploadInitFail;
  }

  void _listenEvent () {
    if (_eventSubscription == null) {
      _eventSubscription = EventBusHelp.getInstance().on().listen((event) async {
        if (event == null) {
          return;
        }
        if (event is LoginStatusEvent) {
          if (event.type == LoginStatusEvent.typeLoginSuccess) {
            _onLogin();
          } else if (event.type == LoginStatusEvent.typeLogoutSuccess) {
            _onLogout();
          }
        }
      });
    }
  }

  void _onLogin() async {
    setState(() {
      _showLoginLoading = true;
    });
    var file = await ImagePicker.pickVideo(source: ImageSource.gallery);
    String videoPath = file?.path;
    if (ObjectUtil.isEmptyString(videoPath)) {
      Navigator.of(context).pop();
    }
    CosLogUtil.log("Video path: $videoPath");
    _uid = Constant.uid;
    _videoPath = videoPath;
    _initData();
  }

  void _onLogout() {
    setState(() {
      _uid = null;
      _videoPath = null;
    });
  }

  void _initData() {
    _initOK = null;
    _tvcSignature = null;
    _categories = [];
    _sysTags = [];
    _coverPath = null;

    List<Future<Null>> tasks = [
      RequestManager.instance.getUploadSign(tag).then((response){
        if (response == null || response.statusCode != 200) {
          return;
        }
        VideoUploadSignBean bean = VideoUploadSignBean.fromJson(json.decode(response.data));
        if (bean != null) {
          _tvcSignature = bean.data.signature;
        }
      }),
      RequestManager.instance.getVideoCategoryList(tag).then((response){
        if (response == null || response.statusCode != 200) {
          return;
        }
        VideoCategoryBean bean = VideoCategoryBean.fromJson(json.decode(response.data));
        if (bean != null && bean.data.list.length > 0) {
          bean.data.list.forEach((c){
            List children = [];
            c.childrenList.forEach((child){
              children.add([child.id, child.cate_name, []]);
            });
            if (children.length == 0) {
              children.add([c.id, c.cate_name, []]);
            }
            _categories.add([c.id, c.cate_name, children]);
          });
        }
      }),
      RequestManager.instance.getRecommendTagList(tag).then((response){
        if (response == null || response.statusCode != 200) {
          return;
        }
        VideoTagsBean bean = VideoTagsBean.fromJson(json.decode(response.data));
        if (bean != null && bean.data.length > 0) {
          bean.data.forEach((t){
            _sysTags.add([t.id, t.content]);
          });
        }
      }),
      _getVideoCover(),
    ];
    Future.wait(tasks).then((_){
      _initOK = !ObjectUtil.isEmptyString(_tvcSignature)
          && _categories != null && _categories.length > 0
          && _sysTags != null && _sysTags.length > 0
          && !ObjectUtil.isEmptyString(_coverPath);

      setState(() {
        _showLoginLoading = false;
      });
    });
  }
  
  Future<Null> _getVideoCover() async {
    Directory tempDir = await getTemporaryDirectory();
    String coverFilePath = p.join(tempDir.path, "${p.basenameWithoutExtension(_videoPath)}_${DateTime.now().millisecondsSinceEpoch}.jpg");
    return VideoThumbnail.thumbnailFile(
      video: _videoPath,
      thumbnailPath: coverFilePath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 512,
      quality: 75,
    ).then((_) async{
      if (await File(coverFilePath).exists()) {
        _coverPath = coverFilePath;
        CosLogUtil.log("Video cover: $_coverPath");
      }
    });
  }

  Future<bool> _onWillPop() async {
    FocusScope.of(context).unfocus();
    var dialog = AlertDialog(
      title: Text(InternationalLocalizations.uploadExitAlertTitle),
      content: Text(InternationalLocalizations.uploadExitAlertContent),
      actions: <Widget>[
        new FlatButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: new Text(InternationalLocalizations.confirm),
        ),
        new FlatButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: new Text(InternationalLocalizations.cancel),
        ),
      ],
    );
    return showDialog(
        context: context,
        builder: (context) {
          return dialog;
        });
  }
}