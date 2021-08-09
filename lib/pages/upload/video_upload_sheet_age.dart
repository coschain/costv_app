import 'package:costv_android/language/international_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:costv_android/utils/cos_theme_util.dart';
import 'package:costv_android/values/app_colors.dart';

class VideoAgeLimitSheet extends StatefulWidget {
  final bool adultOnly;

  VideoAgeLimitSheet({this.adultOnly});

  @override
  _VideoAgeLimitSheetState createState() => _VideoAgeLimitSheetState(adultOnly);
}

class _VideoAgeLimitSheetState extends State<VideoAgeLimitSheet> {
  bool adultOnly;

  _VideoAgeLimitSheetState(this.adultOnly);

  bool get _ageLimited => adultOnly != null && adultOnly;
  bool get _ageUnlimited => adultOnly != null && !adultOnly;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          bottom: 0,
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: Material(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              color: AppThemeUtil.setDifferentModeColor(
              lightColor: AppColors.color_f6f6f6,
              darkColorStr: DarkModelBgColorUtil.pageBgColorStr,
              ),
              child: Column(
                children: <Widget>[
                  Container(height: 15),
                  ListTileTheme(
                    selectedColor: Color(0xFF357CFF),
                    child: ListTile(
                      title: Text(
                        InternationalLocalizations.uploadAdultOptionForAdults,
                        style: _ageLimited? TextStyle(fontWeight: FontWeight.bold) : null,
                      ),
                      selected: _ageLimited,
                      trailing: _ageLimited? Icon(Icons.check):null,
                      onTap: (){
                        setState(() {
                          adultOnly = true;
                        });
                        Navigator.of(context).pop([true, InternationalLocalizations.uploadAdultOptionForAdults]);
                      },
                    ),
                  ),
                  ListTileTheme(
                    selectedColor: Color(0xFF357CFF),
                    child: ListTile(
                      title: Text(
                        InternationalLocalizations.uploadAdultOptionForAll,
                        style: _ageUnlimited? TextStyle(fontWeight: FontWeight.bold) : null,
                      ),
                      selected: _ageUnlimited,
                      trailing: _ageUnlimited? Icon(Icons.check):null,
                      onTap: (){
                        setState(() {
                          adultOnly = false;
                        });
                        Navigator.of(context).pop([false, InternationalLocalizations.uploadAdultOptionForAll]);
                      },
                    ),
                  ),
                  Container(height: 15),
                  Container(
                    height: 0.5,
                    color: AppThemeUtil.getListSeparatorColor(),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FlatButton(
                          child: Text(InternationalLocalizations.cancel, style: TextStyle(fontSize: 15)),
                          onPressed: (){
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
