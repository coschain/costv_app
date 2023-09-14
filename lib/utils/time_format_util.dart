import 'package:common_utils/common_utils.dart';
import 'package:costv_android/language/international_localizations.dart';

class TimeFormatUtil {
  TimeFormatUtil() {
    setLocaleInfo('zh', ZHTimelineFullInfo());
  }

  final DayFormat _dayFormat = DayFormat.Common;

  String formatTime(
    int timeMillis,
  ) {
    return TimelineUtil.format(timeMillis, dayFormat: _dayFormat);
  }
}

class ZHTimelineFullInfo implements TimelineInfo {
  String suffixAgo() => '';

  String suffixAfter() => '';

  String lessThanTenSecond() => InternationalLocalizations.justNow;

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

  @override
  String lessThanOneMinute() {
    // TODO: implement lessThanOneMinute
    throw UnimplementedError();
  }

  @override
  int maxJustNowSecond() {
    // TODO: implement maxJustNowSecond
    throw UnimplementedError();
  }

  @override
  String weeks(int week) {
    // TODO: implement weeks
    throw UnimplementedError();
  }
}
