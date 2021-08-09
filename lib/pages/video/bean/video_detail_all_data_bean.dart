import 'package:costv_android/bean/cos_video_details_bean.dart';
import 'package:costv_android/bean/relate_list_bean.dart';
import 'package:costv_android/bean/comment_list_bean.dart';

class VideoDetailAllDataBean {
  CosVideoDetailsBean videoDetailsBean;
  CommentListBean commentListDataBean;
  RelateListBean      recommendListBean;
  VideoDetailAllDataBean(this.videoDetailsBean, this.commentListDataBean, this.recommendListBean);
}