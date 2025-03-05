import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, 'requests.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            work_order_code TEXT,
            work_order_status TEXT,
            description TEXT,
            asset TEXT,
            asset_code TEXT,
            images TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertRequest(Map<String, dynamic> request) async {
    final db = await database;
    return await db.insert('requests', request);
  }

  Future<List<Map<String, dynamic>>> getRequests() async {
    final db = await database;
    return await db.query('requests');
  }

  Future<void> deleteAllRequests() async {
    final db = await database;
    await db.delete('requests');
  }
  Future<void> clearRequests() async {
    final db = await database;
    await db.delete('requests'); // Hapus semua data di tabel
  }
  Future<void> deleteRequest(int id) async {
    final db = await database;
    await db.delete('requests', where: 'id = ?', whereArgs: [id]);
  }

}
