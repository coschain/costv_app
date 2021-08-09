import 'package:cosdart/types.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';

class CommentChildrenListItemParameterBean {

  static const int showTypeVideoComment = 1;
  static const int showTypeCommentList = 2;

  int showType;
  Object commentChildrenListItemBean;
  ExchangeRateInfoData exchangeRateInfoData;
  ChainState chainStateBean;
  String creatorUid;
  int index;
  String vestStatus;

}
