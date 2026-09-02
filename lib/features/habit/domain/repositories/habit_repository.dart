import '../entities/registro.dart';

abstract class HabitRepository {
  Future<String> getHabitName();
  Future<void> setHabitName(String name);
  Future<Map<String, int>> getAllRegistros(); 
  Future<Map<String, int>> getRegistrosForMonth(int year, int month);
  Future<void> upsertRegistro(String fecha, int estado);
  Future<void> deleteRegistro(String fecha);
  Future<ResumenMensual> getResumenMensual(int year, int month);
  Future<RachaInfo> getRacha({required int year, required int month});
}
