import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/simple_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/video/bean/report_radio_bean.dart';
import 'package:costv_android/pages/webview/webview_page.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VideoReportDialog {
  static const int showTypeOne = 1;
  static const int showTypeTwo = 2;
  static const int showTypeThree = 3;

  final String _tag;
  final GlobalKey<ScaffoldState> _dialogSKey;
  final GlobalKey<ScaffoldState> _pageKey;
  String _vid;
  String _duration;
  List<ReportRadioBean> _listReport = [];
  StateSetter _stateSetter;
  int _showType;
  String _selectCode;
  bool _isAbleCarryOn = false;
  TextEditingController textController;
  String _time;
  ReportRadioBean _selectBean;
  DateTime _dateTime;
  BuildContext _context;

  VideoReportDialog(this._tag, this._pageKey, this._dialogSKey) {
    for (int i = 0; i < InternationalLocalizations.reportTypeCodeList.length; i++) {
      _listReport.add(ReportRadioBean(
          InternationalLocalizations.reportTypeCodeList[i], InternationalLocalizations.reportTypeNameList[i]));
    }
  }

  /// 初始化数据
  void initData(String vid, String duration) {
    _vid = vid;
    _duration = duration;
    _showType = showTypeOne;
    _selectCode = null;
    _isAbleCarryOn = false;
    textController = TextEditingController();
    _time = null;
    _selectBean = null;
    _dateTime = DateTime(0, 0, 0);
  }

  void showVideoReportDialog() {
    showDialog<int>(
      context: _pageKey.currentState.context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, state) {
          _context = context;
          _stateSetter = state;
          return Scaffold(
            key: _dialogSKey,
            resizeToAvoidBottomPadding: false,
            backgroundColor: Colors.transparent,
            body: SimpleDialog(
              titlePadding: EdgeInsets.all(0.0),
              contentPadding: EdgeInsets.all(0.0),
              children: <Widget>[_buildReport(context)],
            ),
          );
        });
      },
    );
  }

  Widget _buildReport(BuildContext context) {
    if (_showType == showTypeOne) {
      return _buildReportOne();
    } else if (_showType == showTypeTwo) {
      return _buildReportTwo(context);
    } else {
      return _buildReportThree();
    }
  }

  /// 构建举报1弹出框界面
  Widget _buildReportOne() {
    return Container(
      width: AppDimens.item_size_290,
      height: AppDimens.item_size_470,
      color: AppColors.color_ffffff,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_15,
              right: AppDimens.margin_20,
            ),
            child: _buildCommonTop(),
          ),
          Expanded(
              child: Container(
            margin: EdgeInsets.only(top: AppDimens.margin_12_5),
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                ReportRadioBean bean = _listReport[index];
                return RadioListTile<String>(
                  title:
                      Text(bean.getName, style: AppStyles.text_style_333333_12),
                  value: bean.getCode,
                  groupValue: _selectCode,
                  onChanged: (value) {
                    _stateSetter(() {
                      _selectCode = value;
                      _selectBean = bean;
                      _isAbleCarryOn = true;
                    });
                  },
                );
              },
              itemCount: _listReport.length,
            ),
          )),
          _buildCommonBottom()
        ],
      ),
    );
  }

  /// 构建举报2弹出框界面
  Widget _buildReportTwo(BuildContext context) {
    return Container(
      width: AppDimens.item_size_290,
      height: AppDimens.item_size_425,
      color: AppColors.color_ffffff,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_15,
              right: AppDimens.margin_20,
            ),
            child: _buildCommonTop(),
          ),
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_15,
              right: AppDimens.margin_20,
            ),
            child: Text(
              '${InternationalLocalizations.reportTime}*',
              style: AppStyles.text_style_333333_12,
            ),
          ),
          InkWell(
            child: Container(
              margin: EdgeInsets.only(
                left: AppDimens.margin_20,
                top: AppDimens.margin_7_5,
                right: AppDimens.margin_20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: AppDimens.item_size_30,
                    child: Column(
                      children: <Widget>[
                        Text(
                          '${(_dateTime.hour).toString().padLeft(2, '0')}',
                          style: AppStyles.text_style_333333_20,
                        ),
                        Divider(
                          height: AppDimens.item_line_height_1,
                          color: AppColors.color_a0a0a0,
                        )
                      ],
                    ),
                  ),
                  Text(
                    ':',
                    style: AppStyles.text_style_333333_20,
                  ),
                  SizedBox(
                    width: AppDimens.item_size_30,
                    child: Column(
                      children: <Widget>[
                        Text(
                          '${(_dateTime.minute % 60).toString().padLeft(2, '0')}',
                          style: AppStyles.text_style_333333_20,
                        ),
                        Divider(
                          height: AppDimens.item_line_height_1,
                          color: AppColors.color_a0a0a0,
                        )
                      ],
                    ),
                  ),
                  Text(
                    ':',
                    style: AppStyles.text_style_333333_20,
                  ),
                  SizedBox(
                    width: AppDimens.item_size_30,
                    child: Column(
                      children: <Widget>[
                        Text(
                          '${(_dateTime.second % 60).toString().padLeft(2, '0')}',
                          style: AppStyles.text_style_333333_20,
                        ),
                        Divider(
                          height: AppDimens.item_line_height_1,
                          color: AppColors.color_a0a0a0,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              DatePicker.showTimePicker(context,
                  showTitleActions: true,
                  locale: Common.getTimeShowByLanguage(), onConfirm: (date) {
                _stateSetter(() {
                  _dateTime = date;
                });
              }, currentTime: _dateTime);
            },
          ),
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_20,
              right: AppDimens.margin_20,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.color_a0a0a0,
                  width: AppDimens.item_line_height_0_5),
            ),
            child: SizedBox(
              width: AppDimens.item_size_250,
              height: AppDimens.item_size_140,
              child: TextField(
                onChanged: (str) {
                  if (str != null && str.trim().isNotEmpty) {
                    if (!_isAbleCarryOn) {
                      _stateSetter(() {
                        _isAbleCarryOn = true;
                      });
                    }
                  } else {
                    if (_isAbleCarryOn) {
                      _stateSetter(() {
                        _isAbleCarryOn = false;
                      });
                    }
                  }
                },
                controller: textController,
                style: AppStyles.text_style_333333_12,
                decoration: InputDecoration(
                  hintStyle: AppStyles.text_style_a0a0a0_12,
                  hintText: InternationalLocalizations.reportInputMsgHint,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          _buildCommonBottom()
        ],
      ),
    );
  }

  /// 构建举报3弹出框界面
  Widget _buildReportThree() {
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
                top: AppDimens.margin_15,
                right: AppDimens.margin_20),
            child: Text(
              InternationalLocalizations.reportThanksToShare,
              style: AppStyles.text_style_333333_16,
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_15,
              right: AppDimens.margin_20,
            ),
            child: Text(
              InternationalLocalizations.reportProblem,
              style: AppStyles.text_style_a0a0a0_12,
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_5,
              right: AppDimens.margin_20,
            ),
            child: Text(
              _selectBean?.getName ?? '',
              style: AppStyles.text_style_333333_12,
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_15,
              right: AppDimens.margin_20,
            ),
            child: Text(
              InternationalLocalizations.reportTime,
              style: AppStyles.text_style_a0a0a0_12,
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_5,
              right: AppDimens.margin_20,
            ),
            child: Text(
              _time ?? '',
              style: AppStyles.text_style_333333_12,
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              left: AppDimens.margin_20,
              top: AppDimens.margin_15,
              right: AppDimens.margin_20,
            ),
            child: Text(
              InternationalLocalizations.reportTipsTwo,
              style: AppStyles.text_style_a0a0a0_12,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: AppDimens.margin_25),
                  height: AppDimens.item_size_40,
                  child: Material(
                    color: AppColors.color_3674ff,
                    child: MaterialButton(
                      child: Text(
                        InternationalLocalizations.close,
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

  void _checkAbleVideoReportAdd() {
    if (!ObjectUtil.isEmptyString(Constant.uid)) {
      _httpGetVideoInfo();
    } else {
      Navigator.of(_context).push(MaterialPageRoute(builder: (_) {
        return WebViewPage(Constant.logInWebViewUrl);
      })).then((isSuccess) {
        if (isSuccess != null && isSuccess) {
          _checkAbleVideoReportAdd();
        }
      });
    }
  }

  /// 通用底部
  Widget _buildCommonBottom() {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(
            left: AppDimens.margin_20,
            top: AppDimens.margin_12_5,
            right: AppDimens.margin_20,
          ),
          child: Text(
            InternationalLocalizations.reportTipsOne,
            style: AppStyles.text_style_333333_11,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: AppDimens.margin_25),
          height: AppDimens.item_size_40,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Material(
                    color: AppColors.color_d6d6d6,
                    child: MaterialButton(
                      child: Text(
                        InternationalLocalizations.cancel,
                        style: AppStyles.text_style_ffffff_14,
                      ),
                      onPressed: () {
                        Navigator.of(_context).pop();
                      },
                    ),
                  )),
              Expanded(
                  flex: 1,
                  child: Material(
                    color: _isAbleCarryOn
                        ? AppColors.color_3674ff
                        : AppColors.color_d6d6d6,
                    child: MaterialButton(
                      child: Text(
                        InternationalLocalizations.carryOn,
                        style: AppStyles.text_style_ffffff_14,
                      ),
                      onPressed: () {
                        if (_isAbleCarryOn) {
                          if (_showType == showTypeOne) {
                            _stateSetter(() {
                              _isAbleCarryOn = false;
                              _showType = showTypeTwo;
                            });
                          } else {
                            int hours = _dateTime.hour;
                            int minutes = _dateTime.minute % 60;
                            int seconds = _dateTime.second % 60;
                            String time = '$hours.$minutes.$seconds';
                            if (Common.isTimeCompareMoreThan(time, _duration)) {
                              ToastUtil.showToast(InternationalLocalizations.reportTimeTips,
                                  toast: Toast.LENGTH_LONG);
                            } else {
                              _time =
                                  '${(hours).toString().padLeft(2, '0')}:${(minutes).toString().padLeft(2, '0')}:${(seconds).toString().padLeft(2, '0')}';
                              _checkAbleVideoReportAdd();
                            }
                          }
                        }
                      },
                    ),
                  )),
            ],
          ),
        )
      ],
    );
  }

  /// 通用顶部
  Widget _buildCommonTop() {
    return Text(
      InternationalLocalizations.reportInformVideo,
      style: AppStyles.text_style_333333_16,
    );
  }

  /// 视频举报
  void _httpGetVideoInfo() {
    RequestManager.instance
        .videoReportAdd(_tag, Constant.uid ?? '', _vid, _time,
            _selectBean?.getCode, textController.text.trim())
        .then((response) {
      if (response == null) {
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean.status == SimpleResponse.statusStrSuccess) {
        _stateSetter(() {
          _showType = showTypeThree;
        });
      } else {
        ToastUtil.showToast(bean?.msg ?? '');
      }
    });
  }
}
