import 'package:costv_android/bean/comment_list_item_bean.dart';

class CommentListParameterBean {

  static const int showTypeVideoComment = 1;
  static const int showTypeCommentList = 2;

  int showType = 0;

  bool isReply = false;
  String videoId = "";
  String vid = "";
  String creatorUid = "";
  String cid = "";
  String nickName = "";
  String pid = "";
  String videoSource = "";
  CommentListItemBean? parentBean;
  String videoTitle = "";
  String videoImage = "";
  String uid = "";
}