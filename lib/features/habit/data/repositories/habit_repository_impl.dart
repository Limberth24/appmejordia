import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/registro.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_local_ds.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitLocalDataSource ds;
  HabitRepositoryImpl(this.ds);

  @override
  Future<String> getHabitName() => ds.getHabitName();

  @override
  Future<void> setHabitName(String name) => ds.setHabitName(name);

  @override
  Future<Map<String, int>> getAllRegistros() => ds.getAllRegistros();

  @override
  Future<Map<String, int>> getRegistrosForMonth(int year, int month) => ds.getRegistrosForMonth(year, month);

  @override
  Future<void> upsertRegistro(String fecha, int estado) => ds.upsertRegistro(fecha, estado);

  @override
  Future<void> deleteRegistro(String fecha) => ds.deleteRegistro(fecha);

  @override
  Future<ResumenMensual> getResumenMensual(int year, int month) async {
    final m = await ds.getRegistrosForMonth(year, month);
    int exitos = 0, fracasos = 0;
    for (var v in m.values) {
      if (v == 1) {
        exitos++;
      } else {
        fracasos++;
      }
    }
    return ResumenMensual(exitos: exitos, fracasos: fracasos);
  }

  @override
  Future<RachaInfo> getRacha({required int year, required int month}) async {
    final all = await ds.getAllRegistros();
    int actual = 0;
    DateTime cur = AppDateUtils.normalize(DateTime.now());
    while (true) {
      final key = AppDateUtils.toIso(cur);
      final val = all[key];
      if (val == 1) {
        actual++;
        cur = cur.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    final daysInMonth = AppDateUtils.daysInMonth(year, month);
    int bestMonth = 0, curStreak = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final dt = DateTime(year, month, d);
   
      if (AppDateUtils.isFuture(dt)) {
        curStreak = 0;
        continue;
      }
      final key = AppDateUtils.toIso(dt);
      final v = all[key];
      if (v == 1) {
        curStreak++;
        if (curStreak > bestMonth) bestMonth = curStreak;
      } else {
        curStreak = 0;
      }
    }

    int bestHist = 0;
    curStreak = 0;
    final sortedKeys = all.keys.toList()..sort();
    DateTime? prev;
    for (var k in sortedKeys) {
      final dt = DateTime.parse(k);
      if (AppDateUtils.isFuture(dt)) continue;
      final v = all[k]!;
      if (v == 1) {
        if (prev != null && dt.difference(prev).inDays == 1 && all[AppDateUtils.toIso(prev)] == 1) {
          curStreak++;
        } else if (v == 1 && curStreak == 0) {
          curStreak = 1;
        } else if (v == 1) {
          if (prev != null && dt.difference(prev).inDays != 1) {
            curStreak = 1;
          } else {
            curStreak++;
          }
        }
        if (curStreak > bestHist) bestHist = curStreak;
      } else {
        curStreak = 0;
      }
      prev = dt;
    }
    if (bestHist < bestMonth) bestHist = bestMonth;

    return RachaInfo(actual: actual, mejorDelMes: bestMonth, mejorHistorica: bestHist);
  }
}
