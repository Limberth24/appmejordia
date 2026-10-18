import '../entities/hito.dart';

abstract class HitoRepository {
  Future<List<Hito>> getAll();
  Future<Hito?> getById(int id);
  Future<int> crear(Hito hito);
  Future<void> actualizar(Hito hito);
  Future<void> eliminar(int id);
  Future<bool> toggleCompletadoPorFecha(int hitoId, String fechaIso);
  Future<bool> isCompletadoEn(int hitoId, String fechaIso);
  Future<List<HitoAgendaItem>> agendaPorDia(DateTime fecha);
  Future<Map<String, List<HitoAgendaItem>>> agendaPorMes(int year, int month);
  Future<HitoProgreso> progresoMensual(int hitoId, int year, int month);
  Future<List<Hito>> conflictos({
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    int? excluirId,
  });

  /// Hitos con horario que chocan con [hito] (cualquier tipo).
  Future<List<Hito>> conflictosHito(Hito hito, {int? excluirId});

  /// Hitos realizados en el rango [ini..fin], agrupados por fecha iso.
  Future<Map<String, List<Hito>>> realizadosRango(
      DateTime ini, DateTime fin);

  /// Progresos mensuales con sesiones en [year/month] (en lote).
  Future<List<({Hito hito, HitoProgreso progreso})>> progresosMensuales(
      int year, int month);

  /// Pasa los diarios pendientes de [hoy] a mañana. Retorna cuántos movió.
  Future<int> reprogramarDiarios(DateTime hoy);
}
