import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/habit_local_ds.dart';
import '../../data/repositories/habit_repository_impl.dart';
import '../../domain/entities/registro.dart';
import '../../domain/repositories/habit_repository.dart';

final habitLocalDsProvider = Provider<HabitLocalDataSource>((ref) => HabitLocalDataSource());

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepositoryImpl(ref.watch(habitLocalDsProvider));
});

final habitNameProvider = FutureProvider<String>((ref) async {
  return ref.watch(habitRepositoryProvider).getHabitName();
});

final focusedMonthProvider = StateProvider<DateTime>((ref) => DateTime(DateTime.now().year, DateTime.now().month, 1));

final _refreshCounterProvider = StateProvider<int>((ref) => 0);

final registrosMesProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(_refreshCounterProvider);
  final month = ref.watch(focusedMonthProvider);
  return ref.watch(habitRepositoryProvider).getRegistrosForMonth(month.year, month.month);
});

final allRegistrosProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(_refreshCounterProvider);
  return ref.watch(habitRepositoryProvider).getAllRegistros();
});

final resumenMensualProvider = FutureProvider<ResumenMensual>((ref) async {
  ref.watch(_refreshCounterProvider);
  final month = ref.watch(focusedMonthProvider);
  return ref.watch(habitRepositoryProvider).getResumenMensual(month.year, month.month);
});

final rachaProvider = FutureProvider<RachaInfo>((ref) async {
  ref.watch(_refreshCounterProvider);
  final month = ref.watch(focusedMonthProvider);
  return ref.watch(habitRepositoryProvider).getRacha(year: month.year, month: month.month);
});

class HabitActions {
  final Ref ref;
  HabitActions(this.ref);

  Future<void> upsert(String fecha, int estado) async {
    await ref.read(habitRepositoryProvider).upsertRegistro(fecha, estado);
    ref.read(_refreshCounterProvider.notifier).state++;
  }

  Future<void> delete(String fecha) async {
    await ref.read(habitRepositoryProvider).deleteRegistro(fecha);
    ref.read(_refreshCounterProvider.notifier).state++;
  }

  Future<void> setHabitName(String name) async {
    await ref.read(habitRepositoryProvider).setHabitName(name);
    ref.invalidate(habitNameProvider);
  }

  void setMonth(DateTime month) {
    ref.read(focusedMonthProvider.notifier).state = DateTime(month.year, month.month, 1);
  }

  void nextMonth() {
    final cur = ref.read(focusedMonthProvider);
    final next = DateTime(cur.year, cur.month + 1, 1);
    ref.read(focusedMonthProvider.notifier).state = next;
  }

  void prevMonth() {
    final cur = ref.read(focusedMonthProvider);
    final prev = DateTime(cur.year, cur.month - 1, 1);
    ref.read(focusedMonthProvider.notifier).state = prev;
  }

  void goToday() {
    final now = DateTime.now();
    ref.read(focusedMonthProvider.notifier).state = DateTime(now.year, now.month, 1);
  }
}

final habitActionsProvider = Provider<HabitActions>((ref) => HabitActions(ref));
