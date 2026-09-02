import 'package:sqflite/sqflite.dart';
import '../../../../core/db/app_database.dart';

class HabitLocalDataSource {
  Future<Database> get _db async => AppDatabase.instance;

  Future<String> getHabitName() async {
    final db = await _db;
    final rows = await db.query('config', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return 'Mi Objetivo';
    return rows.first['nombre_habito'] as String;
  }

  Future<void> setHabitName(String name) async {
    final db = await _db;
    await db.update('config', {'nombre_habito': name}, where: 'id = 1');
  }

  Future<Map<String, int>> getAllRegistros() async {
    final db = await _db;
    final rows = await db.query('registros');
    return {for (var r in rows) r['fecha'] as String: r['estado'] as int};
  }

  Future<Map<String, int>> getRegistrosForMonth(int year, int month) async {
    final db = await _db;
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final rows = await db.query('registros', where: 'fecha LIKE ?', whereArgs: ['$prefix-%']);
    return {for (var r in rows) r['fecha'] as String: r['estado'] as int};
  }

  Future<void> upsertRegistro(String fecha, int estado) async {
    final db = await _db;
    await db.insert('registros', {'fecha': fecha, 'estado': estado},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRegistro(String fecha) async {
    final db = await _db;
    await db.delete('registros', where: 'fecha = ?', whereArgs: [fecha]);
  }
}
