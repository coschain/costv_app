import 'package:costv_android/db/login_info_db_provider.dart';

class LoginInfoDbBean {
  String _uid;
  String _token;
  String _chainAccountName;
  int _expires;

  LoginInfoDbBean(
      this._uid, this._token, this._chainAccountName, this._expires);

  String get getUid => _uid;

  set setUid(String value) {
    _uid = value;
  }

  String get getToken => _token;

  set setToken(String value) {
    _token = value;
  }

  String get getChainAccountName => _chainAccountName;

  set setChainAccountName(String value) {
    _chainAccountName = value;
  }

  int get getExpires => _expires;

  set setExpires(int value) {
    _expires = value;
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      LoginInfoDbProvider.columnUid: _uid,
      LoginInfoDbProvider.columnToken: _token,
      LoginInfoDbProvider.columnChainAccountName: _chainAccountName,
      LoginInfoDbProvider.columnExpires: _expires,
    };
    return map;
  }

  LoginInfoDbBean.fromMap(Map<String, dynamic> map) {
    _uid = map[LoginInfoDbProvider.columnUid];
    _token = map[LoginInfoDbProvider.columnToken];
    _chainAccountName = map[LoginInfoDbProvider.columnChainAccountName];
    _expires = map[LoginInfoDbProvider.columnExpires];
  }
}
