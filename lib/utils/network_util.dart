import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:costv_android/utils/cos_log_util.dart';

class NetWorkUtil {
  static NetWorkUtil? _instance;

  static NetWorkUtil get instance => _getInstance();
  late Connectivity _connectivity;
  ConnectivityResult? _connectivityResult;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isChecking = false;
  String _tag = "connectivity";

  NetWorkUtil._();

  static NetWorkUtil _getInstance() {
    if (_instance == null) {
      _instance = NetWorkUtil._();
      _instance?._connectivity = Connectivity();
      _instance?.initConnectivity();
      _instance?._listenStatusChange();
    }
    return _instance!;
  }

  Future<void> initConnectivity() async {
    if (_connectivityResult != null) {
      return;
    }
    if (_isChecking) {
      return;
    }
    _isChecking = true;
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
      _connectivityResult = result;
    } catch (e) {
      CosLogUtil.log("$_tag: fail to init connectivity");
      //初始化失败,3s后尝试重新初始化
      Future.delayed(Duration(seconds: 3), () {
        initConnectivity();
      });
    }
    _isChecking = false;
  }

  void _listenStatusChange() {
    if (_connectivitySubscription == null) {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    }
  }

  void cancelListen() {
    if (_connectivitySubscription == null) {
      _connectivitySubscription?.cancel();
    }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    _connectivityResult = result;
  }

  bool checkHasNetWork() {
    if (_connectivityResult != null) {
      if (_connectivityResult == ConnectivityResult.mobile ||
          _connectivityResult == ConnectivityResult.wifi) {
        return true;
      }
    }
    return false;
  }

  bool checkIsWifi() {
    if (_connectivityResult != null) {
      if (_connectivityResult == ConnectivityResult.wifi) {
        return true;
      }
    }
    return false;
  }

  bool checkIsMobileNet() {
    if (_connectivityResult != null) {
      if (_connectivityResult == ConnectivityResult.mobile) {
        return true;
      }
    }
    return false;
  }
}