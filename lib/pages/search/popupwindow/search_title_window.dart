import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:costv_android/bean/search_do_suggest_bean.dart';
import 'package:costv_android/bean/search_get_history_list_by_uid_bean.dart';
import 'package:costv_android/bean/simple_bean.dart';
import 'package:costv_android/constant.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/pages/search/search_page.dart';
import 'package:costv_android/utils/toast_util.dart';
import 'package:costv_android/values/app_colors.dart';
import 'package:costv_android/values/app_dimens.dart';
import 'package:costv_android/values/app_styles.dart';
import 'package:costv_android/widget/search_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/data_report_util.dart';

typedef OnSearch(String str);

class SearchTitleWindow extends StatefulWidget {
  static const int fromHome = 1;
  static const int fromSearch = 2;

  final String _tag;
  final int _from;
  final OnSearch onSearch;
  final int selectType;
  final String searchStr;
  int searchType;

  SearchTitleWindow(this._tag, this._from,
      {this.onSearch,
      this.selectType = SearchPageState.selectTypeVideo,
      this.searchStr}) {
    if (_from == fromHome) {
      searchType = SearchRequest.searchTypeVideo;
    } else {
      if (selectType == SearchPageState.selectTypeVideo) {
        searchType = SearchRequest.searchTypeVideo;
      } else {
        searchType = SearchRequest.searchTypeUser;
      }
    }
  }

  @override
  _SearchTitleWindowState createState() => _SearchTitleWindowState();
}

class _SearchTitleWindowState extends State<SearchTitleWindow> {
  static const int pageSuggest = 1;
  static const int pageSizeSuggest = 6;
  List<SearchGetHistoryListByUidDataBean> _listHistory = [];
  List<SearchDoSuggestListBean> _listSuggest = [];
  bool _isShowHistory = true;
  bool _isDelHistoryIng = false;

  @override
  void initState() {
    super.initState();
    if (!ObjectUtil.isEmptyString(Constant.uid)) {
      _httpSearchGetHistoryListByUid();
    }
  }

  /// 获取用户搜索历史
  void _httpSearchGetHistoryListByUid() {
    RequestManager.instance
        .searchGetHistoryListByUid(widget._tag, Constant.uid, widget.searchType)
        .then((response) {
      if (response == null || !mounted) {
        _isDelHistoryIng = false;
        return;
      }
      SearchGetHistoryListByUidBean bean =
          SearchGetHistoryListByUidBean.fromJson(json.decode(response.data));
      if (bean != null &&
          bean.status == SimpleResponse.statusStrSuccess &&
          !ObjectUtil.isEmptyList(bean.data)) {
        setState(() {
          _listHistory.clear();
          _listHistory.add(null);
          _listHistory.addAll(bean.data);
        });
      }
    }).whenComplete(() {
      _isDelHistoryIng = false;
    });
  }

  /// 删除单条搜索历史
  void _httpSearchDelHistory(String id, int index) {
    if (_isDelHistoryIng) {
      return;
    }
    _isDelHistoryIng = true;

    //这一版先从列表删除,不管是否成功，否则点了感觉没有反应
    if (index < _listHistory.length) {
      _listHistory.removeAt(index);
      setState(() {

      });
    }

    RequestManager.instance
        .searchDelHistory(widget._tag, Constant.uid, id)
        .then((response) {
      if (response == null || !mounted) {
        _isDelHistoryIng = false;
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean != null && bean.status == SimpleResponse.statusStrSuccess) {
        _httpSearchGetHistoryListByUid();
      } else {
        ToastUtil.showToast(bean?.msg ?? '');
        _isDelHistoryIng = false;
      }
    });
  }

  /// 清空搜索历史
  void _httpSearchDelAllHistory() {
    if (_isDelHistoryIng) {
      return;
    }
    _isDelHistoryIng = true;
    //视觉上先清空列表，避免点了看起来之后没有反应
    if (_listHistory != null && _listHistory.isNotEmpty) {
      _listHistory.clear();
      setState(() {

      });
    }
    RequestManager.instance
        .searchDelAllHistory(widget._tag, Constant.uid, widget.searchType)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SimpleBean bean = SimpleBean.fromJson(json.decode(response.data));
      if (bean != null && bean.status == SimpleResponse.statusStrSuccess) {
        setState(() {
          _listHistory.clear();
        });
      } else {
        ToastUtil.showToast(bean?.msg ?? '');
      }
    }).whenComplete(() {
      _isDelHistoryIng = false;
    });
  }

  /// 用户搜索联想词
  void _httpSearchDoSuggest(String keyword) {
    RequestManager.instance
        .searchDoSuggest(widget._tag, keyword, widget.searchType,
            page: pageSuggest, pageSize: pageSizeSuggest)
        .then((response) {
      if (response == null || !mounted) {
        return;
      }
      SearchDoSuggestBean bean =
          SearchDoSuggestBean.fromJson(json.decode(response.data));
      if (bean != null &&
          bean.status == SimpleResponse.statusStrSuccess &&
          bean.data != null &&
          !ObjectUtil.isEmptyList(bean.data.list)) {
        setState(() {
          _listSuggest.clear();
          _listSuggest.addAll(bean.data.list);
        });
      }
    });
  }

  Widget _buildSearchHistoryItem(int index) {
    SearchGetHistoryListByUidDataBean bean = _listHistory[index];
    if (bean == null) {
      return Container(
        color: AppColors.color_ffffff,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(
                  left: AppDimens.margin_15,
                  top: AppDimens.margin_13_5,
                  bottom: AppDimens.margin_13_5),
              child: Text(
                InternationalLocalizations.searchHistory,
                style: AppStyles.text_style_a0a0a0_13,
              ),
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.all(AppDimens.margin_10),
                margin: EdgeInsets.only(right: AppDimens.margin_5),
                child: Image.asset(
                  'assets/images/ic_search_history_delete.png',
                  width: AppDimens.item_size_20,
                  height: AppDimens.item_size_20,
                ),
              ),
              onTap: () {
                _httpSearchDelAllHistory();
              },
            )
          ],
        ),
      );
    } else {
      return InkWell(
        child: Container(
          color: AppColors.color_ffffff,
          child: Column(
            children: <Widget>[
              Divider(
                height: AppDimens.item_line_height_0_5,
                color: AppColors.color_e4e4e4,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                          left: AppDimens.margin_15,
                          top: AppDimens.margin_13_5,
                          bottom: AppDimens.margin_13_5),
                      child: Text(
                        bean?.search ?? '',
                        style: AppStyles.text_style_333333_14,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  InkWell(
                    child: Container(
                      padding: EdgeInsets.all(AppDimens.margin_10),
                      margin: EdgeInsets.only(right: AppDimens.margin_5),
                      child: Image.asset(
                        'assets/images/ic_input_close.png',
                        width: AppDimens.item_size_20,
                        height: AppDimens.item_size_20,
                      ),
                    ),
                    onTap: () {
                      if (!ObjectUtil.isEmptyString(bean?.id)) {
                        _httpSearchDelHistory(bean?.id, index);
                      }
                    },
                  )
                ],
              )
            ],
          ),
        ),
        onTap: () {
          if (widget._from == SearchTitleWindow.fromHome) {
            _reportSearchContent(bean?.content);
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) {
              return SearchPage(bean?.search ?? '');
            }));
          } else {
            Navigator.of(context).pop();
            if (widget.onSearch != null) {
              widget.onSearch(bean?.search ?? '');
            }
          }
        },
      );
    }
  }

  Widget _buildSuggestItem(int index) {
    SearchDoSuggestListBean bean = _listSuggest[index];
    String showMsg;
    if (widget.selectType == SearchPageState.selectTypeVideo) {
      showMsg = bean?.title ?? '';
    } else {
      showMsg = bean?.nickname ?? '';
    }
    return InkWell(
      child: Container(
        color: AppColors.color_ffffff,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Divider(
              height: AppDimens.item_line_height_0_5,
              color: AppColors.color_e4e4e4,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        left: AppDimens.margin_15,
                        top: AppDimens.margin_12_5,
                        bottom: AppDimens.margin_12_5),
                    child: Text(
                      showMsg,
                      style: AppStyles.text_style_151515_15,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
      onTap: () {
        if (widget._from == SearchTitleWindow.fromHome) {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) {
            return SearchPage(showMsg);
          }));
        } else {
          Navigator.of(context).pop();
          if (widget.onSearch != null) {
            widget.onSearch(showMsg);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      width: MediaQuery.of(context).size.width,
      color: AppColors.color_ffffff,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SearchTitleWidget(
            searchStr: widget.searchStr,
            onTextChanged: (str) {
              if (str != null && str.trim().isNotEmpty) {
                if (_isShowHistory) {
                  _isShowHistory = false;
                }
                _httpSearchDoSuggest(str.trim());
              } else {
                if (!_isShowHistory) {
                  _isShowHistory = true;
                  if (!ObjectUtil.isEmptyList(_listSuggest)) {
                    _listSuggest.clear();
                  }
                  if (!ObjectUtil.isEmptyString(Constant.uid) &&
                      ObjectUtil.isEmptyList(_listHistory)) {
                    _httpSearchGetHistoryListByUid();
                  }
                }
              }
            },
            onClickSearch: (str) {
              if (widget._from == SearchTitleWindow.fromHome) {
                _reportSearchContent(str);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                  return SearchPage(str ?? '');
                }));
              } else {
                if (widget.onSearch != null) {
                  widget.onSearch(str);
                }
              }
            },
          ),
          Column(
            children: List.generate(
                _isShowHistory ? _listHistory.length : _listSuggest.length,
                (int index) {
              return _isShowHistory
                  ? _buildSearchHistoryItem(index)
                  : _buildSuggestItem(index);
            }),
          )
        ],
      ),
    );
  }

  void _reportSearchContent(String content) {
    if (content != null) {
      print("search content is $content");
      DataReportUtil.instance.reportData(
          eventName: "search_go",
          params: {"search_go": content},
      );
    }
  }
}
