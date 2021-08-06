import 'package:flutter/material.dart';

typedef OnCloseListener();

class PopupWindow extends StatefulWidget {
  final Widget child;
  final Function onClick; //点击child事件
  final double left; //距离左边位置
  final double top; //距离上面位置
  final Color backgroundColor;
  final OnCloseListener onCloseListener;
  final bool isClickBgClose;

  PopupWindow(this.child, {
    this.onClick,
    this.left,
    this.top,
    this.backgroundColor = Colors.transparent,
    this.onCloseListener,
    this.isClickBgClose = true,
  }) {
    assert(this.child != null);
  }

  @override
  _PopupWindowState createState() => _PopupWindowState();
}

class _PopupWindowState extends State<PopupWindow> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.backgroundColor,
      child: GestureDetector(
        child: Stack(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.transparent,
            ),
            Positioned(
              child: GestureDetector(
                  child: widget.child,
                  onTap: () {
                    //点击子child
                    if (widget.onClick != null) {
                      Navigator.of(context).pop();
                      widget.onClick();
                    }
                  }),
              left: widget.left,
              top: widget.top,
            ),
          ],
        ),
        onTap: () {
          //点击空白处
          if(widget.onCloseListener != null){
            widget.onCloseListener();
          }
          if(widget.isClickBgClose){
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
