import 'package:cosdart/types.dart';
import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';

class CommentListItemParameterBean {

  static const int showTypeVideoComment = 1;
  static const int showTypeCommentList = 2;

  int showType = 0;
  late CommentListItemBean commentListItemBean;
  String total = "";
  int index = 0;
  int commentLength = 0;
  ExchangeRateInfoData? exchangeRateInfoData;
  ChainState? chainStateBean;
  String uid = "";
  bool isLoadMoreComment = false;
  int commentPage = 0;
}
