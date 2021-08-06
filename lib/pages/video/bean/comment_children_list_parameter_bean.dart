import 'package:costv_android/bean/comment_list_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:cosdart/types.dart';

class CommentChildrenListParameterBean {
  double width;
  double height;
  String vid;
  String pid;
  String uid;
  Map<String, dynamic> mapRemoteResError;
  String vestStatus;
  AccountInfo cosInfoBean;
  ExchangeRateInfoData exchangeRateInfoData;
  ChainState chainStateBean;
  CommentListTopBean commentListTopBean;
  CommentListDataListBean commentListDataListBean;

}
