import 'dart:async';

import 'package:costv_android/language/international_localizations.dart';
import 'package:costv_android/pages/main_page.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/widget/route/slide_animation_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashTermsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SplashTermsPageState();
  }

  static Future<bool> getAcceptTerms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool val = prefs.getBool('accept_terms');
    if (val == null) {
      return false;
    }
    return val;
  }

  static Future<bool> setAcceptTerms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Future<bool> val = prefs.setBool('accept_terms', true);
    return val;
  }
}

class SplashTermsPageState extends State<SplashTermsPage> {
  static const tag = 'SplashTermsPageState';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    brightnessModel = MediaQuery.of(context).platformBrightness;
    double statusHeight = MediaQuery.of(context).padding.top;
    return Material(
      color: Colors.white,
      child: Container(
        margin: EdgeInsets.only(top: statusHeight+50, left: 25, right: 25, bottom: 0),
        child: Column (
          children: [
            Text(InternationalLocalizations.termsWelCome,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Container(
              margin: EdgeInsets.only(top: 15),
              child: Image.asset(
                'assets/images/terms_note.png',
                fit: BoxFit.fitWidth,
                //width: MediaQuery.of(context).size.width,
                //height: MediaQuery.of(context).size.height - statusHeight,
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 15, left: 5, right: 5),
              child: Text(InternationalLocalizations.termsWelComeDesc,
                style: TextStyle(fontSize: 12, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            
            Container(
              margin: EdgeInsets.only(top: 35, left: 5, right: 5),
              alignment: Alignment.center,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 12),
                  children: <InlineSpan>[
                    TextSpan(text: InternationalLocalizations.termsContinueDesc ,style: TextStyle(color: Colors.black)),
                    TextSpan(text: InternationalLocalizations.termsContinueLink ,
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline,),
                      recognizer: TapGestureRecognizer()..onTap = () async {
                        CosLogUtil.log("Press Link");
                        var urlTerms = 'https://cos.tv/docs/terms-of-service';
                        if (await canLaunch(urlTerms) != null ) {
                              await launch(urlTerms);
                        }
                      },
                    ),
                  ]),
              ),
            ),
            Container(
                margin: EdgeInsets.only(top: 20, left: 5, right: 5),
                child: SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: MaterialButton(
                      child: new Text(InternationalLocalizations.carryOn),
                      color: Colors.blue,
                      textColor: Colors.white,
                      onPressed: () async {
                        CosLogUtil.log("Press Continue");
                        await SplashTermsPage.setAcceptTerms();
                        Navigator.pushAndRemoveUntil(
                          context,
                          SlideAnimationRoute(
                            builder: (_) {
                              return MainPage();
                            },
                          ),
                          (route) => route == null,
                        );
                      },
                      shape: RoundedRectangleBorder(
                        side: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(17))
                      ),
                  )
                )
              ),
        ],)
      )
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
