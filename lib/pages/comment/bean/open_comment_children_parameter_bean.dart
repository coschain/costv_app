import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:cosdart/types.dart';

class OpenCommentChildrenParameterBean {

  bool isReply;
  String vid;
  String pid;
  String uid;
  Map<String, dynamic> mapRemoteResError;
  String vestStatus;
  AccountInfo cosInfoBean;
  ExchangeRateInfoData exchangeRateInfoData;
  ChainState chainStateBean;
  CommentListItemBean commentListItemBean;
  String creatorUid;
  String isCertification;
  int changeCommentTotal;

}
