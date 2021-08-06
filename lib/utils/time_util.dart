class TimeUtil {
  static const int php_time_stamp_length = 10;

  TimeUtil._();

  static String secondToYYYYMMddHHmmss(int second) {
    return millisToYYYYMMddHHmmss(second * 1000);
  }

  static String millisToYYYYMMddHHmmss(int millis) {
    if (millis.toString().length == php_time_stamp_length) {
      millis *= 1000;
    }
    DateTime time = DateTime.fromMillisecondsSinceEpoch(millis);

    return _fourDigits(time.year) +
        '.' +
        twoDigits(time.month) +
        '.' +
        twoDigits(time.day) +
        ' ' +
        twoDigits(time.hour) +
        ':' +
        twoDigits(time.minute) +
        ':' +
        twoDigits(time.second);
  }

  static String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  static String _fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }

  ///根据数字返回英文月份
  static String getEnMonthForNumber(String number) {
    if (number == '1') {
      return 'January';
    } else if (number == '2') {
      return 'February';
    } else if (number == '3') {
      return 'March';
    } else if (number == '4') {
      return 'April';
    } else if (number == '5') {
      return 'May';
    } else if (number == '6') {
      return 'June';
    } else if (number == '7') {
      return 'July';
    } else if (number == '8') {
      return 'August';
    } else if (number == '9') {
      return 'September';
    } else if (number == '10') {
      return 'October';
    } else if (number == '11') {
      return 'November';
    } else if (number == '12') {
      return 'December';
    }
    return '';
  }
}
