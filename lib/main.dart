import 'package:costv_android/language/international_localizations_delegate.dart';
import 'package:costv_android/pages/splash_page.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language/international_localizations.dart';

void main(){
  // 限制竖屏
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
        runApp(CosTvApp());
      });
}

class CosTvApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: InternationalLocalizations?.title??'',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashPage(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        InternationalLocalizationsDelegate.delegate,
      ],
      supportedLocales: [
        const Locale(InternationalLocalizations.languageCodeEn),
        const Locale(InternationalLocalizations.languageCodeKo),
        const Locale(InternationalLocalizations.languageCodePt_Br),
        const Locale(InternationalLocalizations.languageCodeRu),
        const Locale(InternationalLocalizations.languageCodeVi),
        const Locale(InternationalLocalizations.languageCodeZh_Cn),
        const Locale(InternationalLocalizations.languageCodeZh),
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        curLanguage = deviceLocale.toString();
        _loadSavedLan();
        return;
      },
      navigatorObservers: [
        routeObserver,
      ],
    );
  }

  Future<String> _loadSavedLan() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String val = "";
    if (prefs.containsKey(savedLanKey)) {
      try {
        val = prefs.getString(savedLanKey);
        if (val != null && val != curLanguage) {
          curLanguage = val;
          Locale local = Locale(curLanguage);
          InternationalLocalizationsDelegate.delegate.load(local);
        }
      } catch(e) {

      }
    }
    return val;
  }
}

