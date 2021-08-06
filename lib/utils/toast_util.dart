import 'package:common_utils/common_utils.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtil {
  static void showToast(String msg,
      {ToastGravity gravity = ToastGravity.BOTTOM,
      Toast toast = Toast.LENGTH_SHORT}) {
    if (TextUtil.isEmpty(msg)) {
      return;
    }
    Fluttertoast.showToast(
      msg: msg,
      toastLength: toast,
      gravity: gravity,
    );
  }
}
