import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../habit/presentation/providers/habit_providers.dart';
import '../../data/datasources/hito_local_ds.dart';
import '../../data/repositories/hito_repository_impl.dart';
import '../../domain/entities/hito.dart';
import '../../domain/repositories/hito_repository.dart';

final hitoLocalDsProvider = Provider<HitoLocalDataSource>((ref) => HitoLocalDataSource());

final hitoRepositoryProvider = Provider<HitoRepository>((ref) {
  return HitoRepositoryImpl(ref.watch(hitoLocalDsProvider));
});

/// Día seleccionado en la agenda (normalizado).
final agendaDayProvider = StateProvider<DateTime>(
    (ref) => AppDateUtils.normalize(DateTime.now()));

final _hitoRefreshProvider = StateProvider<int>((ref) => 0);

void _bumpHitos(Ref ref) => ref.read(_hitoRefreshProvider.notifier).state++;

/// Agenda del día seleccionado, ordenada por hora.
final agendaDiaProvider = FutureProvider<List<HitoAgendaItem>>((ref) async {
  ref.watch(_hitoRefreshProvider);
  final dia = ref.watch(agendaDayProvider);
  return ref.watch(hitoRepositoryProvider).agendaPorDia(dia);
});

/// Agenda del mes enfocado (habit focusedMonth reutilizado).
final agendaMesProvider =
    FutureProvider<Map<String, List<HitoAgendaItem>>>((ref) async {
  ref.watch(_hitoRefreshProvider);
  final month = ref.watch(focusedMonthProvider);
  return ref.watch(hitoRepositoryProvider).agendaPorMes(month.year, month.month);
});

final allHitosProvider = FutureProvider<List<Hito>>((ref) async {
  ref.watch(_hitoRefreshProvider);
  return ref.watch(hitoRepositoryProvider).getAll();
});

/// Agenda de hoy: para el botón "Realizado" de la vista mensual.
final agendaHoyProvider = FutureProvider<List<HitoAgendaItem>>((ref) async {
  ref.watch(_hitoRefreshProvider);
  return ref
      .watch(hitoRepositoryProvider)
      .agendaPorDia(AppDateUtils.normalize(DateTime.now()));
});

/// Agenda de una fecha concreta (pantalla "Misiones del día").
final agendaPorFechaProvider =
    FutureProvider.family<List<HitoAgendaItem>, DateTime>((ref, dia) async {
  ref.watch(_hitoRefreshProvider);
  return ref
      .watch(hitoRepositoryProvider)
      .agendaPorDia(AppDateUtils.normalize(dia));
});

/// Rango del historial de realizados (por defecto solo hoy).
final rangoHistorialProvider =
    StateProvider<({DateTime ini, DateTime fin})>((ref) {
  final hoy = AppDateUtils.normalize(DateTime.now());
  return (ini: hoy, fin: hoy);
});

/// Hitos realizados en el rango, agrupados por fecha iso.
final realizadosRangoProvider =
    FutureProvider<Map<String, List<Hito>>>((ref) async {
  ref.watch(_hitoRefreshProvider);
  final rango = ref.watch(rangoHistorialProvider);
  return ref
      .watch(hitoRepositoryProvider)
      .realizadosRango(rango.ini, rango.fin);
});

/// Progresos de hitos mensuales en el mes enfocado (en lote: 2 queries).
final progresosMensualesProvider =
    FutureProvider<List<({Hito hito, HitoProgreso progreso})>>((ref) async {
  ref.watch(_hitoRefreshProvider);
  final month = ref.watch(focusedMonthProvider);
  return ref
      .watch(hitoRepositoryProvider)
      .progresosMensuales(month.year, month.month);
});

class HitoActions {
  final Ref ref;
  HitoActions(this.ref);

  Future<int> crear(Hito hito) async {
    final id = await ref.read(hitoRepositoryProvider).crear(hito);
    _bumpHitos(ref);
    return id;
  }

  Future<void> actualizar(Hito hito) async {
    await ref.read(hitoRepositoryProvider).actualizar(hito);
    _bumpHitos(ref);
  }

  Future<void> eliminar(int id) async {
    await ref.read(hitoRepositoryProvider).eliminar(id);
    _bumpHitos(ref);
  }

  Future<void> toggle(DateTime fecha, HitoAgendaItem item) async {
    final iso = AppDateUtils.toIso(fecha);
    await ref
        .read(hitoRepositoryProvider)
        .toggleCompletadoPorFecha(item.hito.id!, iso);
    _bumpHitos(ref);
  }

  void setDay(DateTime d) {
    ref.read(agendaDayProvider.notifier).state =
        AppDateUtils.normalize(d);
  }

  /// Al fallar el día: pasa los diarios pendientes a mañana.
  /// Retorna cuántos se movieron.
  Future<int> reprogramarPendientes(DateTime hoy) async {
    final n = await ref
        .read(hitoRepositoryProvider)
        .reprogramarDiarios(AppDateUtils.normalize(hoy));
    if (n > 0) _bumpHitos(ref);
    return n;
  }

  void refresh() => _bumpHitos(ref);
}final hitoActionsProvider = Provider<HitoActions>((ref) => HitoActions(ref));

const hitoCategorias = ['Trabajo', 'Salud', 'Personal', 'Estudio', 'Otro'];

const hitoColores = [0xFF1A237E, 0xFF1B6D24, 0xFFB26A00, 0xFF93000E, 0xFF4C56AF, 0xFF00696B];

const hitoRecordatorios = <int?>[null, 5, 15, 30, 60];

String recordatorioLabel(int? min) {
  if (min == null) return 'Sin recordatorio';
  if (min < 60) return '$min min antes';
  return '1 h antes';
}
