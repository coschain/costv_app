import 'package:costv_android/language/free_localizations_widget.dart';
import 'package:costv_android/language/international_localizations.dart';
import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  final GlobalKey<FreeLocalizationsState> _freeLocalizationStateKey;

  LanguagePage(this._freeLocalizationStateKey);

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  bool flag = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(InternationalLocalizations.title),
      ),
      body: Column(
        children: <Widget>[
          Text(InternationalLocalizations.title),
          RaisedButton(
            child: Text('切换语言'),
            onPressed: changeLocale,
          )
        ],
      ),
    );
  }

  void changeLocale() {
    if (flag) {
      widget._freeLocalizationStateKey.currentState
          .changeLocale(const Locale('zh', "CH"));
    } else {
      widget._freeLocalizationStateKey.currentState
          .changeLocale(const Locale('en', "US"));
    }
    flag = !flag;
  }
}
