import 'package:flutter/material.dart';

class TrianglePainter extends CustomPainter{

  Color color; //填充颜色
  Paint _paint;//画笔
  Path _path;  //绘制路径
  double angle;//角度

  TrianglePainter(this.color){
    _paint = Paint()
      ..strokeWidth = 1.0 //线宽
      ..color = color
      ..isAntiAlias = true;
    _path = Path();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final baseX = size.width * 0.5;
    final baseY = size.height * 0.5;
    //起点
    _path.moveTo(baseX - 0.86 * baseX, 0.5 * baseY);
    _path.lineTo(baseY, 1.5 * baseY);
    _path.lineTo(baseX + 0.86 *baseX, 0.5*baseY);
    canvas.drawPath(_path,_paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

}