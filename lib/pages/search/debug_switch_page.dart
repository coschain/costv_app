

import 'package:costv_android/constant.dart';
import 'package:costv_android/db/login_info_db_provider.dart';
import 'package:costv_android/event/base/event_bus_help.dart';
import 'package:costv_android/event/setting_switch_event.dart';
import 'package:costv_android/language/international_localizations_delegate.dart';
import 'package:costv_android/net/request_manager.dart';
import 'package:costv_android/utils/common_util.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/utils/global_util.dart';
import 'package:costv_android/widget/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DebugSwitchPage extends StatefulWidget {

  DebugSwitchPage() : super();

  @override
  DebugSwitchState createState() => DebugSwitchState();
}

class DebugSwitchState extends State<DebugSwitchPage> with RouteAware {

  bool useDebugEnv = Constant.isDebug;
  String curLanCode = curLanguage;
  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void didPop() {
    super.didPop();
    if (curLanCode != curLanguage || this.useDebugEnv != Constant.isDebug) {
      SettingModel model = SettingModel(false,curLanguage,curLanCode);
      if (this.useDebugEnv != Constant.isDebug) {
        Constant.isDebug = this.useDebugEnv;
        RequestManager.resetForQaTest();
        model.isEnvSwitched = true;
        _deleteUserInfo();
      }
      if (curLanCode != curLanguage) {
        curLanguage = curLanCode;
        Locale local = Locale(curLanCode);
        InternationalLocalizationsDelegate.delegate.load(local);
        _saveLanCode(curLanCode);
      }
      EventBusHelp.getInstance().fire(SettingSwitchEvent(model));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: CustomAppBar(
          backCallBack: () {
          },
        ),
        body: Container(
          margin: EdgeInsets.only(top: 10),
          child: Column(
            children: <Widget>[
              Container(
//                padding: EdgeInsets.symmetric(vertical: 5),
                width: screenWidth,
                decoration: BoxDecoration(
                    color: AppThemeUtil.setDifferentModeColor(
                      lightColor: Colors.white,
                      darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
                    ),
                    border: Border(
                        bottom: BorderSide(
                            width: 0.5,
                            color: Common.getColorFromHexString("D6D6D6", 1.0)
                        )
                    )
                ),
                child: CheckboxListTile(
                    value: this.useDebugEnv,
                    title: Text("Debug QA Env"),
                    activeColor: Colors.blue,
                    onChanged: (bool val) {
                      // val 是布尔值
                      this.setState(() {
                        this.useDebugEnv = !this.useDebugEnv;
//                        Constant.isDebug = this.useDebugEnv;
//                        RequestManager.resetForQaTest();
                      });
                    }

                ),
              ),
              Container(
                  padding: EdgeInsets.fromLTRB(15,5,0,5),
                  width: screenWidth,
                  decoration: BoxDecoration(
                      color: AppThemeUtil.setDifferentModeColor(
                        lightColor: Colors.white,
                        darkColorStr: DarkModelBgColorUtil.secondaryPageColorStr,
                      ),
                      border: Border(
                          bottom: BorderSide(
                              width: 0.5,
                              color: Common.getColorFromHexString("D6D6D6", 1.0)
                          )
                      )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Change Language",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 18,
                        ),
//                  )
                      ),
                      DropdownButton(
                        items: <DropdownMenuItem<String>>[
                          DropdownMenuItem(child: Text("繁體中文",style: TextStyle(color: Common.checkIsTraditionalChinese(curLanCode) ?Colors.blue:Colors.grey),),value: "zh_Hant",),
                          DropdownMenuItem(child: Text("简体中文",style: TextStyle(color: Common.checkIsSimplifiedChinese(curLanCode)?Colors.blue:Colors.grey),),value: "zh_CN",),
                          DropdownMenuItem(child: Text("English",style: TextStyle(color: curLanCode.startsWith("en")?Colors.blue:Colors.grey),),value: "en",),
                          DropdownMenuItem(child: Text("Türkçe",style: TextStyle(color: curLanCode.startsWith("tr")?Colors.blue:Colors.grey),),value: "tr",),
                          DropdownMenuItem(child: Text("한국어",style: TextStyle(color:curLanCode.startsWith("ko")?Colors.blue:Colors.grey),),value: "ko",),
                          DropdownMenuItem(child: Text("Tiếng việt",style: TextStyle(color: curLanCode.startsWith("vi")?Colors.blue:Colors.grey),),value: "vi",),
                          DropdownMenuItem(child: Text("Português",style: TextStyle(color: curLanCode.startsWith("pt")?Colors.blue:Colors.grey),),value: "pt",),
                          DropdownMenuItem(child: Text("Русский",style: TextStyle(color:curLanCode.startsWith("ru")?Colors.blue:Colors.grey),),value: "ru",),
                        ],
                        hint:new Text(_getLanDescByCode(curLanCode)),
                        onChanged: (selectValue){
                          setState(() {
                            curLanCode = selectValue;
                          });
                        },
                        style: new TextStyle(
                            //设置下拉文本框里面文字的样式
                            color: Colors.blue,
                            fontSize: 18
                        ),
                        iconSize: 30,//三角标icon的大小
                      ),
                    ],
                  ),
          ),
            ]),
        ),
      );
  }

  String _getLanDescByCode(String lan) {
    if (lan != null) {
      if (lan.startsWith("en")) {
        return "English";
      } else if (lan.startsWith("tr")) {
        return "Türkçe";
      } else if (lan.startsWith("ko")) {
        return "한국어";
      } else if (lan.startsWith("vi")) {
        return "Tiếng việt";
      } else if (lan.startsWith("pt")) {
        return "Português";
      } else if (lan.startsWith("ru")) {
        return "Русский";
      } else if (lan.startsWith("zh")) {
        //简体
        if (lan.startsWith("zh_Hans") || lan.startsWith("zh_CN")) {
          return "简体中文";
        }
        //繁体
        return "繁體中文";
      }
    }
    return "";
  }

  Future<void> _deleteUserInfo() async{
    Constant.uid = null;
    Constant.token = null;
    Constant.accountName = null;
    LoginInfoDbProvider loginInfoDbProvider = LoginInfoDbProvider();
    try {
      await loginInfoDbProvider.open();
      await loginInfoDbProvider.deleteAll();
    } catch (e) {
      CosLogUtil.log("DebugSwitchPage: e = $e");
    } finally {
      await loginInfoDbProvider.close();
    }
  }

  Future<void> _saveLanCode(String lan) async{
    if (!Common.checkIsNotEmptyStr(lan)) {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(savedLanKey, lan);
  }

}
