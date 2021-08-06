
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/common_util.dart';

typedef AppBarBackCallBack = void Function();

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final double bgHeight;
  final String title;
  final AppBarBackCallBack backCallBack;
  CustomAppBar({this.bgHeight = kToolbarHeight, this.title, this.backCallBack});
  @override
  State<StatefulWidget> createState() {
    return CustomAppBarState();
  }

  Size get preferredSize => Size.fromHeight(this.bgHeight);
}

class CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width, leftWidth = 40;
    return PreferredSize(
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        width: screenWidth,
        height: widget.bgHeight,
        color: Common.getColorFromHexString("FFFFFFFF", 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            //返回按钮
            Material(
              child: Ink(
                color: Common.getColorFromHexString("FFFFFFFF", 1.0),
                child: InkWell(
                  onTap: () {
                    if (widget.backCallBack != null) {
                      widget.backCallBack();
                    }
                    Navigator.of(context).pop();
                  },
                  child: Container(
                          width: leftWidth,
                          padding: EdgeInsets.fromLTRB(16,12,16,10),
                          child: GestureDetector(
                            child:Image.asset(
                              'assets/images/ic_back.png',
//                              width: 7,
//                              height: 14,
                              fit: BoxFit.cover,
                            ),
                          )

                      ),

                  ),
                ),
              ),
            //标题
            Container(
              margin: EdgeInsets.only(left: 5),
              width: screenWidth - leftWidth - 10,
              child: Text(
                  widget.title ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 15
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }
}