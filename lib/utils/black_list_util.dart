import 'package:costv_android/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlackListUtil {
  static BlackListUtil _instance;

  factory BlackListUtil() => _getInstance();

  static BlackListUtil get instance => _getInstance();

  BlackListUtil._();

  List<String> _blackUserIds = [];
  List<String> _blackVideoIds = [];

  static BlackListUtil _getInstance() {
    if (_instance == null) {
      _instance = BlackListUtil._();
      _instance._loadData();
    }
    return _instance;
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('black_list_vids:');
    print(_blackVideoIds);
    print('black_list_uids:');
    print(_blackUserIds);

    await prefs.setStringList("black_list_uids", _blackUserIds);
    await prefs.setStringList("black_list_vids", _blackVideoIds);
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _blackUserIds = prefs.getStringList("black_list_uids");
    _blackVideoIds = prefs.getStringList("black_list_vids");

    print('black_list_vids:');
    print(_blackVideoIds);
    print('black_list_uids:');
    print(_blackUserIds);

    if (_blackVideoIds == null)_blackVideoIds = [];
    if (_blackUserIds == null)_blackUserIds = [];
  }

  void AddVideoIdToBlackList(String video_id){
    print('AddVideoIdToBlackList:' + video_id);
    if (IsBlackVideo(video_id)){
      return;
    }
    print('AddVideoIdToBlackList2:' + video_id);
    _blackVideoIds.add(video_id);
    _saveData();
  }

  bool IsBlackVideo(String videoId){
    for (var vid in _blackVideoIds) {
      if ( vid.compareTo(videoId ) == 0 ){
        print('isBalck:' + videoId + '  ' + vid);
        return true;
      }
    }
    //print('is NOT Balck:' + videoId);
    return false;
  }

  void AddUserIdToBlackList(String userId){
    if ( IsBlackUser(userId))return;
    print('AddUserIdToBlackList:' + userId);
    _blackUserIds.add(userId);
    _saveData();
  }

  bool IsBlackUser(String userID){
    for (var uid in _blackUserIds) {
      if ( uid.compareTo(userID) == 0 )
        return true;
    }
    return false;
  }

  void ClearBlackLists(){
    _blackUserIds.clear();
    _blackVideoIds.clear();
    _saveData();
  }
}