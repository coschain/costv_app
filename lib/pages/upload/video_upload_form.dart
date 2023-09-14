import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:costv_android/constant.dart';
import 'package:costv_android/bean/upload_image_bean.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:common_utils/common_utils.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/upload/video_tags_container.dart';
import 'package:costv_android/pages/upload/video_upload_sheet_age.dart';
import 'package:costv_android/pages/upload/video_upload_sheet_category.dart';
import 'package:costv_android/pages/upload/video_upload_sheet_lang.dart';
import 'package:costv_android/pages/upload/video_upload_sheet_tag.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/pages/upload/video_upload_appbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:tvc_upload/tvc_upload.dart';
import 'package:costv_android/utils/data_report_util.dart';

const int MaxVideoTitleSize = 100;
const int MaxVideoDescSize = 500;
const VideoLanguages = [
  ["cn", "简体中文"],
  ["tw", "繁體中文"],
  ["en", "English"],
  ["vi", "Tiếng việt"],
  ["jp", "日本語"],
  ["ko", "한국어"],
  ["pt-br", "Português"],
  ["ru", "Pусский"],
  ["tr", "Türkçe"],
  ["es-mx", "Español"],
  ["other", "Other"],
];

typedef VideoUploadCallback = void Function();

class VideoUploadForm extends StatefulWidget {
  bool loading;
  String videoPath;
  String thumbnailPath;
  List? categories;
  List? sysTags;
  final String tvcSignature;
  final VideoUploadCallback? onCancel;
  final VideoUploadCallback? onSuccess;

  VideoUploadForm({
    this.loading = false,
    this.videoPath = "",
    this.thumbnailPath = "",
    this.categories,
    this.sysTags,
    this.tvcSignature = "",
    this.onCancel,
    this.onSuccess,
  });

  @override
  _VideoUploadFormState createState() => _VideoUploadFormState();
}

class _VideoUploadFormState extends State<VideoUploadForm> {
  static const tag = "_VideoUploadFormState";

  bool _showAllItems = false;

  String _video = "";
  String _videoFileId = "";
  String _videoUrl = "";
  String _cover = "";
  String _title = "";
  int _category1st = 0;
  int _category2nd = 0;
  bool _adult = false;
  List<int>? _sysTags = [];
  List<String>? _userTags = [];
  String _desc = "";
  String _lang = RequestManager.instance.apiLanguageParam();
  bool _privacy = false;
  String _progressTitle = InternationalLocalizations.uploadProgressUploading;
  String _progressDetails = "";
  double _progressValue = 0;
  StreamSubscription? _tvcEventsSubscription;
  bool _publishing = false;
  bool _success = false;

  static bool _emptyValue(dynamic value) {
    if (value == null) {
      return true;
    } else if (value is String) {
      return ObjectUtil.isEmptyString(value);
    } else if (value is int) {
      return value < 0;
    } else if (value is List) {
      return value.length == 0;
    }
    return false;
  }

  static Color _captionColor(dynamic value) {
    bool empty = _emptyValue(value);
    if (AppThemeUtil.checkIsDarkMode()) {
      return empty ? Color(0xFFD6D6D6) : Color(0x9AD6D6D6);
    } else {
      return empty ? Color(0xFF333333) : Color(0x9A333333);
    }
  }

  static Color _contentColor() {
    return AppThemeUtil.setDifferentModeColor(
      lightColor: Colors.black,
      darkColorStr: DarkModelTextColorUtil.firstLevelBrightnessColorStr,
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (_tvcEventsSubscription != null) {
      _tvcEventsSubscription?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loading && !ObjectUtil.isEmptyString(widget.videoPath) && ObjectUtil.isEmptyString(_video)) {
      _video = widget.videoPath;
      _uploadVideo();
    }
    return Scaffold(
      appBar: VideoUploadAppbar(
        title: InternationalLocalizations.uploadAppbarBack,
        onBack: _onBackPressed,
        buttonText: InternationalLocalizations.uploadAppbarPublish,
        buttonTextColor: _readyToPublish ? Color(0xFF357CFF) : AppThemeUtil.getButtonDisabledColor(),
        onButtonTapped: () {
          if (_readyToPublish) {
            _publish();
          }
        },
      ),
      body: Stack(
        children: <Widget>[
          _buildBody(context),
          widget.loading || _publishing ? _buildLoading(context) : Container(),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      color: AppThemeUtil.setDifferentModeColor(
        lightColor: AppColors.color_f6f6f6,
        darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
      ),
      child: ListView.builder(
        itemCount: 9,
        itemBuilder: (BuildContext context, int index) {
          switch (index) {
            case 0:
              return _itemUploadProgress(context);
            case 1:
              return _itemVideoCover(context);
            case 2:
              return _itemVideoTitle(context);
            case 3:
              return _itemVideoCategory(context);
            case 4:
              return _itemVideoAgeLimit(context);
            case 5:
              return _itemVideoTags(context);
            case 6:
              return _showAllItems ? _itemVideoDesc(context) : _itemVideoShowMore(context);
            case 7:
              return _showAllItems ? _itemVideoLanguage(context) : Container();
            case 8:
              return _showAllItems ? _itemVideoPrivacy(context) : Container();
            default:
              return Container();
          }
        },
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
          child: Container(color: AppColors.color_transparent, child: Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator())),
        ),
      ),
    );
  }

  Widget _itemUploadProgress(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
          child: Row(
            children: <Widget>[
              Text(
                _progressTitle,
                style: TextStyle(
                  color: _contentColor(),
                ),
              ),
              Container(
                width: 10,
              ),
              Text(
                _progressDetails,
                style: TextStyle(
                  color: Common.getColorFromHexString("A0A0A0", 1.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemVideoCover(BuildContext context) {
    if (ObjectUtil.isEmptyString(_cover)) {
      _cover = widget.thumbnailPath;
    }
    double width = MediaQuery.of(context).size.width;
    double height = width * 9 / 16;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF545454), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ObjectUtil.isEmptyString(_cover)
              ? Image.asset("assets/images/img_default_video_cover.png", fit: BoxFit.fill)
              : Image.file(File(_cover), fit: BoxFit.contain),
          Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: width,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x00000000), Color(0x80000000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Container(),
              )),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              child: Text(InternationalLocalizations.uploadCoverChange),
              onPressed: () {
                _changeCover();
              },
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: width,
              height: 4,
              child: Row(
                children: <Widget>[
                  Container(
                    width: (_progressValue ?? 0) * width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF66ACFF), Color(0xFF3674FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Container(),
                  ),
                  Expanded(child: Container()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeCover() async {
    XFile? cover = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (cover != null) {
      CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: cover.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: InternationalLocalizations.uploadCoverCrop,
              toolbarColor: AppThemeUtil.setDifferentModeColor(
                lightColor: Colors.white,
                darkColor: Color(0xFF2A2A2A),
              ),
              toolbarWidgetColor: AppThemeUtil.setDifferentModeColor(
                lightColor: Colors.black,
                darkColor: Colors.white,
              ),
              initAspectRatio: CropAspectRatioPreset.ratio16x9,
              lockAspectRatio: false),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        ],
      );
      if (cropped != null) {
        setState(() {
          _cover = cropped.path;
        });
      }
    }
  }

  Widget _itemVideoTitle(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                InternationalLocalizations.uploadTitleCaption,
                style: TextStyle(color: _captionColor(_title)),
              ),
              Text("*", style: TextStyle(color: Colors.red)),
              Expanded(child: Container()),
              (_emptyValue(_title)
                  ? Container()
                  : Row(
                      children: <Widget>[
                        Text("${_title.length}", style: TextStyle(color: _title.length <= MaxVideoTitleSize ? _captionColor(_title) : Colors.red)),
                        Text("/$MaxVideoTitleSize", style: TextStyle(color: _captionColor(_title)))
                      ],
                    )),
            ],
          ),
          TextField(
            style: TextStyle(
              fontSize: 15,
              color: _contentColor(),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: InternationalLocalizations.uploadTitleHint,
              hintStyle: TextStyle(color: AppThemeUtil.getUploadHintTextColor()),
            ),
            onChanged: (s) {
              setState(() {
                _title = s;
              });
            },
          ),
          Container(
            color: _title.length <= MaxVideoTitleSize ? AppThemeUtil.getListSeparatorColor() : Colors.red,
            height: _title.length <= MaxVideoTitleSize ? 0.5 : 1,
          ),
        ],
      ),
    );
  }

  Widget _itemVideoCategory(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          FocusScope.of(context).unfocus();
          List r = await showDialog(
              context: context,
              builder: (ctx) => VideoCategorySheet(
                    categories: widget.categories ?? [],
                    firstCategory: _category1st,
                    secondCategory: _category2nd,
                  ));
          setState(() {
            _category1st = r[0];
            _category2nd = r[3];
          });
        },
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(InternationalLocalizations.uploadCategoryCaption, style: TextStyle(color: _captionColor(_category))),
                Text(
                  "*",
                  style: TextStyle(color: Colors.red),
                )
              ],
            ),
            Container(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text(
                  _category ?? InternationalLocalizations.uploadCategoryHint,
                  style: TextStyle(
                    color: _emptyValue(_category) ? AppThemeUtil.getUploadHintTextColor() : _contentColor(),
                  ),
                ),
                Expanded(
                  child: Container(),
                ),
                Image.asset(AppThemeUtil.getIcnDownTitle()),
              ],
            ),
            Container(
              height: 10,
            ),
            Container(
              color: AppThemeUtil.getListSeparatorColor(),
              height: 0.5,
            )
          ],
        ),
      ),
    );
  }

  String get _category {
    if (_category1st < 0 || _category1st >= (widget.categories?.length ?? 0)) {
      return "";
    }
    List c1 = widget.categories?[_category1st];
    if (_category2nd < 0 || _category2nd >= c1[2].length) {
      return "";
    }
    List c2 = c1[2][_category2nd];
    String s = c1[1];
    if (c1[0] != c2[0]) {
      s += " - " + c2[1];
    }
    return s;
  }

  Widget _itemVideoAgeLimit(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          FocusScope.of(context).unfocus();
          List r = await showDialog(context: context, builder: (ctx) => VideoAgeLimitSheet(adultOnly: _adult));
          setState(() {
            _adult = r[0];
          });
        },
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(InternationalLocalizations.uploadAdultCaption, style: TextStyle(color: _captionColor(_adult))),
                Text(
                  "*",
                  style: TextStyle(color: Colors.red),
                )
              ],
            ),
            Container(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text(
                  _ageLimit ?? InternationalLocalizations.uploadAdultHint,
                  style: TextStyle(
                    color: _emptyValue(_ageLimit) ? AppThemeUtil.getUploadHintTextColor() : _contentColor(),
                  ),
                ),
                Expanded(
                  child: Container(),
                ),
                Image.asset(AppThemeUtil.getIcnDownTitle()),
              ],
            ),
            Container(
              height: 10,
            ),
            Container(
              color: AppThemeUtil.getListSeparatorColor(),
              height: 0.5,
            )
          ],
        ),
      ),
    );
  }

  String get _ageLimit {
    return _adult ? InternationalLocalizations.uploadAdultOptionForAdults : InternationalLocalizations.uploadAdultOptionForAll;
  }

  Widget _itemVideoTags(BuildContext context) {
    List<String> currentTags = _tags;
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          FocusScope.of(context).unfocus();
          List r = await showDialog(
              context: context,
              builder: (ctx) => VideoTagsSheet(
                    sysTags: widget.sysTags,
                    selectedSysTags: _sysTags,
                    userTags: _userTags,
                  ));
          setState(() {
            _sysTags = [];
            _userTags = [];
            _sysTags?.addAll(r[0]);
            _userTags?.addAll(r[1]);
          });
        },
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(InternationalLocalizations.uploadTagCaption, style: TextStyle(color: _captionColor(currentTags))),
                Text("*", style: TextStyle(color: Colors.red)),
                Expanded(child: Container()),
                (_emptyValue(currentTags) ? Container() : Image.asset(AppThemeUtil.getIcnDownTitle())),
              ],
            ),
            Container(
              height: 10,
            ),
            (_emptyValue(currentTags)
                ? Row(
                    children: <Widget>[
                      Text(
                        InternationalLocalizations.uploadTagHint,
                        style: TextStyle(
                          color: AppThemeUtil.getUploadHintTextColor(),
                        ),
                      ),
                      Expanded(
                        child: Container(),
                      ),
                      Image.asset(AppThemeUtil.getIcnDownTitle()),
                    ],
                  )
                : Align(
                    alignment: Alignment.topLeft,
                    child: VideoTagsContainer(tags: currentTags),
                  )),
            Container(
              height: 10,
            ),
            Container(
              color: AppThemeUtil.getListSeparatorColor(),
              height: 0.5,
            )
          ],
        ),
      ),
    );
  }

  List<String> get _tags {
    List<String> r = [];
    _sysTags?.forEach((index) {
      r.add(widget.sysTags?[index][1]);
    });
    r.addAll(_userTags ?? []);
    return r;
  }

  Widget _itemVideoShowMore(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _showAllItems = true;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(InternationalLocalizations.uploadMoreOptions, style: TextStyle(color: Color(0xFF858585))),
            Container(
              width: 5,
            ),
            Image.asset(AppThemeUtil.getMoreIcn()),
          ],
        ),
      ),
    );
  }

  Widget _itemVideoDesc(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                InternationalLocalizations.uploadDescCaption,
                style: TextStyle(color: _captionColor(_desc)),
              ),
              Expanded(child: Container()),
              (_emptyValue(_desc)
                  ? Container()
                  : Row(
                      children: <Widget>[
                        Text("${_desc.length}", style: TextStyle(color: _desc.length <= MaxVideoDescSize ? _captionColor(_desc) : Colors.red)),
                        Text("/$MaxVideoDescSize", style: TextStyle(color: _captionColor(_desc)))
                      ],
                    )),
            ],
          ),
          TextField(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            maxLines: null,
            style: TextStyle(
              fontSize: 15,
              color: _contentColor(),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: InternationalLocalizations.uploadDescHint,
              hintStyle: TextStyle(
                color: AppThemeUtil.getUploadHintTextColor(),
              ),
            ),
            onChanged: (s) {
              setState(() {
                _desc = s;
              });
            },
          ),
          Container(
            color: _desc.length <= MaxVideoDescSize ? AppThemeUtil.getListSeparatorColor() : Colors.red,
            height: _desc.length <= MaxVideoDescSize ? 0.5 : 1,
          )
        ],
      ),
    );
  }

  Widget _itemVideoLanguage(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          FocusScope.of(context).unfocus();
          int r = await showDialog(context: context, builder: (ctx) => VideoLanguageSheet(langCode: _lang, languageList: VideoLanguages));
          setState(() {
            _lang = VideoLanguages[r][0];
          });
        },
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(InternationalLocalizations.uploadLanguageCaption, style: TextStyle(color: _captionColor(_langName))),
              ],
            ),
            Container(
              height: 10,
            ),
            Row(
              children: <Widget>[
                Text(
                  _langName ?? "",
                  style: TextStyle(
                    color: _emptyValue(_langName) ? AppThemeUtil.getUploadHintTextColor() : _contentColor(),
                  ),
                ),
                Expanded(
                  child: Container(),
                ),
                Image.asset(AppThemeUtil.getIcnDownTitle()),
              ],
            ),
            Container(
              height: 10,
            ),
            Container(
              color: AppThemeUtil.getListSeparatorColor(),
              height: 0.5,
            )
          ],
        ),
      ),
    );
  }

  String get _langName {
    if (ObjectUtil.isEmptyString(_lang)) {
      return "";
    }
    for (int i = 0; i < VideoLanguages.length; i++) {
      if (VideoLanguages[i][0] == _lang) {
        return VideoLanguages[i][1];
      }
    }
    return "";
  }

  Widget _itemVideoPrivacy(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: Row(
        children: <Widget>[
          Text(InternationalLocalizations.uploadPrivacyCaption,
              style: TextStyle(
                color: _captionColor(null),
              )),
          Expanded(
            child: Container(),
          ),
          Radio<bool>(
            value: false,
            groupValue: _privacy,
            onChanged: (v) {
              setState(() {
                _privacy = v ?? false;
              });
            },
            activeColor: Color(0xFF357CFF),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(InternationalLocalizations.uploadPrivacyOptionPublic),
          Container(
            width: 8,
          ),
          Radio<bool>(
            value: true,
            groupValue: _privacy,
            onChanged: (v) {
              setState(() {
                _privacy = v ?? false;
              });
            },
            activeColor: Color(0xFF357CFF),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(InternationalLocalizations.uploadPrivacyOptionPrivate),
        ],
      ),
    );
  }

  bool get _readyToPublish {
    return !ObjectUtil.isEmptyString(_videoUrl) &&
        !ObjectUtil.isEmptyString(_videoFileId) &&
        !ObjectUtil.isEmptyString(_title) &&
        _title.length <= MaxVideoTitleSize &&
        (_sysTags?.length ?? 0) + (_userTags?.length ?? 0) > 0 &&
        !_emptyValue(_adult) &&
        !_emptyValue(_category1st) &&
        !_emptyValue(_category2nd);
  }

  void _onBackPressed() {
    FocusScope.of(context).unfocus();
    if (widget.onCancel != null) {
      widget.onCancel?.call();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _publish() async {
    setState(() {
      _publishing = true;
    });

    _reportClickedPublishVideo();

    var result = await _publishVideo();
    setState(() {
      _publishing = false;
    });
    if (result is bool) {
      if (result) {
        _success = true;
        if (widget.onSuccess != null) {
          widget.onSuccess?.call();
        }
      } else {
        _success = false;
        ToastUtil.showToast(InternationalLocalizations.uploadPublishFailedTips);
      }
    }
  }

  Future _publishVideo() {
    return RequestManager.instance.uploadImage(tag, _cover).then((response) {
      if (response == null || response.statusCode != 200) {
        return false;
      }
      UploadImageBean coverBean = UploadImageBean.fromJson(json.decode(response.data));
      if (coverBean == null) {
        return false;
      }
      String categoryId1st = widget.categories?[_category1st][0];
      String categoryId2nd = widget.categories?[_category1st][2][_category2nd][0];
      if (categoryId2nd == categoryId1st) {
        categoryId2nd = "";
      }
      List<String> systags = [];
      _sysTags?.forEach((index) {
        systags.add(widget.sysTags?[index][0]);
      });
      return RequestManager.instance
          .postVideo(tag, Constant.uid ?? "", _title ?? "", _videoUrl, _videoFileId, coverBean.data.url, _desc ?? "", categoryId1st, categoryId2nd,
              systags, _userTags ?? [], _lang, !_privacy, _adult)
          .then((response) {
        if (response == null || response.statusCode != 200) {
          return false;
        }
        var r = json.decode(response.data);
        return r != null && r["status"] == "200";
      });
    });
  }

  void _uploadVideo() async {
    String? taskId = await TvcUpload.uploadVideo(widget.tvcSignature, _video);
    CosLogUtil.log("uploadVideo: taskId=$taskId. sig=${widget.tvcSignature}, file=$_video");
    if (!ObjectUtil.isEmptyString(taskId)) {
      if (_tvcEventsSubscription != null) {
        _tvcEventsSubscription?.cancel();
      }
      _tvcEventsSubscription = TvcUpload.eventChannel.receiveBroadcastStream(taskId).listen((e) {
        CosLogUtil.log("uploadVideo: event: ${e.toString()}");
        if (e is Map) {
          if (e["type"] == "progress") {
            _uploadProgress(int.parse(e["upload"]), int.parse(e["total"]));
          } else if (e["type"] == "result") {
            _uploadResult(e["success"] == "1", e["video_file_id"], e["video_url"]);
          }
        }
      });
    }
  }

  void _uploadProgress(int uploaded, int total) {
    if (uploaded >= 0 && total > 0) {
      int percent = (uploaded * 100 / total).round();
      setState(() {
        _progressTitle = InternationalLocalizations.uploadProgressUploading;
        _progressDetails = "$percent% (${formatBytes(uploaded)}/${formatBytes(total)})";
        _progressValue = uploaded / total;
      });
    }
  }

  void _uploadResult(bool success, String fileId, String url) {
    if (success) {
      _videoFileId = fileId;
      _videoUrl = url;
      setState(() {
        _progressTitle = InternationalLocalizations.uploadProgressUploadOK;
        _progressDetails = "";
        _progressValue = 1;
      });
    } else {
      _videoFileId = "";
      _videoUrl = "";
      setState(() {
        _progressTitle = InternationalLocalizations.uploadProgressUploadFailed;
        _progressDetails = "";
        _progressValue = 0;
      });
    }
  }

  void _reportClickedPublishVideo() {
    DataReportUtil.instance.reportData(
      eventName: "Click_Upload",
      params: {"Click_Upload": "1"},
    );
  }

  static String formatBytes(int n) {
    double k = n / 1024.0;
    double m = k / 1024.0;
    double g = m / 1024.0;
    double t = g / 1024.0;
    if (t >= 1) {
      return t.toStringAsFixed(1) + "TB";
    } else if (g >= 1) {
      return g.toStringAsFixed(1) + "GB";
    } else if (m >= 1) {
      return m.toStringAsFixed(1) + "MB";
    } else if (k >= 1) {
      return k.toStringAsFixed(1) + "KB";
    } else {
      return n.toStringAsFixed(0) + "B";
    }
  }
}
