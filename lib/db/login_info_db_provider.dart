import 'package:costv_android/db/login_info_db_bean.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LoginInfoDbProvider {
  static const String dbName = 'costv';
  static const String tableName = 'login_info';
  static const int dbVersion = 1;
  static const String columnUid = 'uid';
  static const String columnToken = 'token';
  static const String columnChainAccountName = 'chain_account_name';
  static const String columnExpires = 'expires';

  Database _db;

  Future<Database> open() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, '$dbName.db');
    if (_db == null || !_db.isOpen) {
      _db = await openDatabase(path, version: dbVersion,
          onCreate: (Database db, int version) async {
        await db.execute('''
          create table $tableName (
          $columnUid text primary key,
          $columnToken text not null,
          $columnChainAccountName text not null,
          $columnExpires integer not null)
      ''');
      });
    }
    return _db;
  }

  Future<int> insert(LoginInfoDbBean loginInfoDbBean) async {
    assert(_db != null);
    return await _db.insert(tableName, loginInfoDbBean.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<LoginInfoDbBean> getLoginInfoDbBean() async {
    assert(_db != null);
    List<Map> maps = await _db.query(tableName);
    if (maps.length > 0) {
      return LoginInfoDbBean.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteAll() async {
    assert(_db != null);
    return await _db.delete(tableName);
  }

  Future<int> update(LoginInfoDbBean loginInfoDbBean) async {
    assert(_db != null);
    return await _db.update(tableName, loginInfoDbBean.toMap(),
        where: '$columnUid = ?',
        whereArgs: [loginInfoDbBean.getUid]);
  }

  Future close() async {
    if (_db != null && _db.isOpen) {
      _db.close();
    }
  }
}
