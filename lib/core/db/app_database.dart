import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static Database? _db;
  static const _name = 'mejordia.db';
  static const _version = 2;

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
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createV1(db);
        await _createV2(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migración sin romper: solo añade, nunca borra config/registros.
        if (oldVersion < 2) {
          await _createV2(db);
        }
      },
      onOpen: (db) async {
        final rows = await db.query('config', where: 'id = 1');
        if (rows.isEmpty) {
          await db.insert('config', {'id': 1, 'nombre_habito': 'Mi Objetivo'});
        }
      },
    );
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS config(
        id INTEGER PRIMARY KEY CHECK(id=1),
        nombre_habito TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS registros(
        fecha TEXT PRIMARY KEY,
        estado INTEGER NOT NULL CHECK(estado IN(0,1))
      )
    ''');
    final rows = await db.query('config', where: 'id = 1');
    if (rows.isEmpty) {
      await db.insert('config', {'id': 1, 'nombre_habito': 'Mi Objetivo'});
    }
  }

  /// Tablas de agenda de hitos (v2). No toca config/registros.
  static Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hitos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        tipo TEXT NOT NULL CHECK(tipo IN ('diario','mensual','puntual')),
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        hora_inicio TEXT,
        hora_fin TEXT,
        dias_semana TEXT,
        completado INTEGER NOT NULL DEFAULT 0 CHECK(completado IN (0,1)),
        fecha_completado TEXT,
        categoria TEXT,
        color INTEGER,
        recordatorio_min INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_hitos_tipo ON hitos(tipo)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_hitos_fechas ON hitos(fecha_inicio, fecha_fin)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hito_completions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hito_id INTEGER NOT NULL REFERENCES hitos(id) ON DELETE CASCADE,
        fecha TEXT NOT NULL,
        completado_en TEXT NOT NULL,
        UNIQUE(hito_id, fecha)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_completions_hito_fecha ON hito_completions(hito_id, fecha)');
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
