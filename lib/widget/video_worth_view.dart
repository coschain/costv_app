import 'package:flutter/material.dart';
import 'package:costv_android/utils/common_util.dart';

class VideoWorthWidget extends StatelessWidget {

  final String _symbol,_amount;

  VideoWorthWidget(this._symbol, this._amount);

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.fromLTRB(6, 1, 6, 1),
      constraints: BoxConstraints(
        maxWidth: screenSize.width,
        maxHeight: screenSize.height,
      ),
      decoration: BoxDecoration(
        color: Common.getColorFromHexString("FAF1D4", 1.0),
        borderRadius: BorderRadius.all(
          Radius.circular(22.0),
        ),
      ),
      child: DefaultTextStyle(
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Common.getColorFromHexString("D19900", 1.0),
          fontSize: 12.5,
        ),
        child: Text(
          _getDesc(),
        ),
      ),

    );
  }

  String _getDesc() {
    String desc = "";
    if (_symbol != null && _symbol.length > 0) {
      desc += _symbol + " ";
    }
    if (_amount != null && _amount.length > 0) {
      desc += _amount;
    }
    return desc;
  }

}