import 'package:common_utils/common_utils.dart';
import 'package:costv_android/language/international_localizations.dart';

class TimeFormatUtil {
  TimeFormatUtil() {
    setLocaleInfo('zh', ZHTimelineFullInfo());
  }

  final DayFormat _dayFormat = DayFormat.Common;

  String formatTime(int timeMillis, {int locTimeMillis}) {
    return TimelineUtil.format(timeMillis,
        locTimeMs: locTimeMillis, dayFormat: _dayFormat);
  }
}

class ZHTimelineFullInfo implements TimelineInfo {
  String suffixAgo() => '';

  String suffixAfter() => '';

  String lessThanOneMinute() => InternationalLocalizations.justNow;

  String customYesterday() => InternationalLocalizations.yesterday;

  bool keepOneDay() => false;

  bool keepTwoDays() => true;

  String oneMinute(int minutes) => InternationalLocalizations.minutes(minutes);

  String minutes(int minutes) => InternationalLocalizations.minutes(minutes);

  String anHour(int hours) => InternationalLocalizations.hours(hours);

  String hours(int hours) => InternationalLocalizations.hours(hours);

  String oneDay(int days) => InternationalLocalizations.days(days);

  String days(int days) => InternationalLocalizations.days(days);

  DayFormat dayFormat() => DayFormat.Simple;

  int maxJustNowSecond() => 30;

  String weeks(int week) => '';

}
