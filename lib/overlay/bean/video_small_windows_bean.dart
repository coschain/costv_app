
import 'package:costv_android/bean/bank_property_bean.dart';
import 'package:costv_android/bean/comment_list_bean.dart';
import 'package:costv_android/bean/comment_list_item_bean.dart';
import 'package:costv_android/bean/exchange_rate_info.dart';
import 'package:costv_android/bean/exclusive_relation_bean.dart';
import 'package:costv_android/bean/get_video_info_bean.dart';
import 'package:costv_android/bean/integral_user_info_bean.dart';
import 'package:costv_android/bean/relate_list_bean.dart';
import 'package:costv_android/bean/video_gift_info_bean.dart';
import 'package:video_player/video_player.dart';

class VideoSmallWindowsBean {

  bool isVideoDetailsInit;
  List<Object> listDataItem = [];
  Duration startAt;
  String vid;
  String uid;
  String videoSource;
  GetVideoInfoDataBean getVideoInfoDataBean;
  int linkCount;
  int popReward;
  VideoGiftInfoDataBean videoGiftInfoDataBean;
  IntegralUserInfoDataBean integralUserInfoDataBean;
  BankPropertyDataBean bankPropertyDataBean;
  ExchangeRateInfoData exchangeRateInfoData;
  bool isVideoLike;
  bool isFollow;
  List<RelateListItemBean> listRelate;
  List<RelateListItemBean> listData;
  int videoPage;
  bool isHaveMoreData;
  CommentListDataBean commentListDataBean;
  List<CommentListItemBean> listComment;
  int commentPage;
  VideoPlayerController videoPlayerController;
  ExclusiveRelationItemBean exclusiveRelationItemBean;

}
