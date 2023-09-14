import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:cosdart/types.dart';

class OpenCommentChildrenParameterBean {
  bool isReply = false;
  String vid = "";
  String pid = "";
  String uid = "";
  late Map<String, dynamic> mapRemoteResError;
  String vestStatus = "";
  AccountInfo? cosInfoBean;
  ExchangeRateInfoData? exchangeRateInfoData;
  ChainState? chainStateBean;
  late CommentListItemBean commentListItemBean;
  String creatorUid = "";
  String isCertification = "";
  int changeCommentTotal = 0;
}
