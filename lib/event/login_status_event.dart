class LoginStatusEvent {

  static const int typeLoginSuccess = 1;
  static const int typeLogoutSuccess = 2;
  static const int typeTokenInvalid = 3;

  int type;
  String? uid;

  LoginStatusEvent(this.type);
}
