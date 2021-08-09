import 'package:costv_android/constant.dart';
import 'package:costv_android/utils/cos_log_util.dart';
import 'package:cosdart/cosdart.dart';
import 'package:cosdart/types.dart';

typedef CosSDKFailCallBack = void Function(String error);
typedef LoadTimeCallBack = void Function(int milliseconds);

class CosSdkUtil {
  static CosSdkUtil _instance;

  CosChainClient _client;

  factory CosSdkUtil() => _getInstance();

  static CosSdkUtil get instance => _getInstance();

  CosSdkUtil._();

  static CosSdkUtil _getInstance() {
    if (_instance == null) {
      _instance = CosSdkUtil._();
      _instance._client = Constant.isDebug
          ? CosChainClient("dev", "34.199.54.140", 8888, false)   // dev
          : CosChainClient.of(Network.main);                      // main
    }
    return _instance;
  }

  Future<AccountResponse> getAccountChainInfo(String name) async {
    AccountResponse bean;
    try {
      bean = await _client.getAccountByName(name);
      CosLogUtil.log("CosSdkUtil getAccountChainInfo bean: " + bean.writeToJson());
    } catch(e) {
      CosLogUtil.log("CosSdkUtil getAccountChainInfo error: " + e.toString());
    }
    return bean;
  }

  Future<GetChainStateResponse> getChainState({CosSDKFailCallBack fallCallBack, LoadTimeCallBack loadTimeCallBack}) async {
    GetChainStateResponse bean;
    int sTime = DateTime.now().millisecondsSinceEpoch;
    try {
      bean = await _client.getChainState();
      CosLogUtil.log("CosSdkUtil getChainState bean: " + bean.writeToJson());
    } catch (e) {
      CosLogUtil.log("CosSdkUtil getChainState error: " + e.toString());
      if (fallCallBack != null) {
        fallCallBack("CosSdkUtil getChainState error: " + e.toString());
      }
    }
    int eTime = DateTime.now().millisecondsSinceEpoch;
    int loadTime = eTime - sTime;
    if (loadTimeCallBack != null) {
      loadTimeCallBack(loadTime);
    }
    return bean;
  }
}
