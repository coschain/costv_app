import 'package:costv_android/utils/common_util.dart';
import 'package:flutter/material.dart';

class AppBarBackWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Ink(
        color: Common.getColorFromHexString("FFFFFFFF", 1.0),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(left: 16),
                  child: GestureDetector(
                    child:Image.asset(
                      'assets/images/ic_back.png',
                      width: 7,
                      height: 14,
                      fit: BoxFit.cover,
                    ),
                  )

              ),

//              Container(
//                margin: EdgeInsets.only(left: 8),
//                constraints: BoxConstraints(
//                  maxWidth: 35,
//                ),
//                child: Text(
//                  InternationalLocalizations.back,
//                  overflow: TextOverflow.ellipsis,
//                  style: TextStyle(
//                    color: Colors.black,
//                    fontSize: 15,
//                  ),
//                ),
//              )
            ],
          ),
        ),
      ),
    );
  }
}