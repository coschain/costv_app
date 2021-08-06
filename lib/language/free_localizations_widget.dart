
import 'package:flutter/material.dart';

class FreeLocalizationsWidget extends StatefulWidget{

  final Widget child;

  FreeLocalizationsWidget({Key key,this.child}):super(key:key);

  @override
  State<FreeLocalizationsWidget> createState() {
    return FreeLocalizationsState();
  }
}

class FreeLocalizationsState extends State<FreeLocalizationsWidget>{

  Locale _locale = const Locale('zh','CH');

  changeLocale(Locale locale){
    setState((){
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: _locale,
      child: widget.child,
    );
  }
}