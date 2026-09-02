import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static Database? _db;
  static const _name = 'mejordia.db';
  static const _version = 1;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _name);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE config(
            id INTEGER PRIMARY KEY CHECK(id=1),
            nombre_habito TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE registros(
            fecha TEXT PRIMARY KEY,
            estado INTEGER NOT NULL CHECK(estado IN(0,1))
          )
        ''');
        await db.insert('config', {'id': 1, 'nombre_habito': 'Mi Objetivo'});
      },
      onOpen: (db) async {
        final rows = await db.query('config', where: 'id = 1');
        if (rows.isEmpty) {
          await db.insert('config', {'id': 1, 'nombre_habito': 'Mi Objetivo'});
        }
      },
    );
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
