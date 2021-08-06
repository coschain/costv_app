import 'package:costv_android/language/international_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class InternationalLocalizationsDelegate
    extends LocalizationsDelegate<InternationalLocalizations> {
  const InternationalLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return [
      InternationalLocalizations.languageCodeEn,
      InternationalLocalizations.languageCodeKo,
      InternationalLocalizations.languageCodePt_Br,
      InternationalLocalizations.languageCodeRu,
      InternationalLocalizations.languageCodeVi,
      InternationalLocalizations.languageCodeZh_Cn,
      InternationalLocalizations.languageCodeZh
    ].contains(locale.languageCode);
  }

  @override
  Future<InternationalLocalizations> load(Locale locale) {
    InternationalLocalizations internationalLocalizations =
        InternationalLocalizations(locale);
    internationalLocalizations.initData();
    return SynchronousFuture<InternationalLocalizations>(
        internationalLocalizations);
  }

  @override
  bool shouldReload(LocalizationsDelegate<InternationalLocalizations> old) {
    return false;
  }

  static InternationalLocalizationsDelegate delegate =
      const InternationalLocalizationsDelegate();
}
