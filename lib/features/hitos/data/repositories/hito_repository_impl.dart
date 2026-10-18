import '../../domain/entities/hito.dart';
import '../../domain/repositories/hito_repository.dart';
import '../datasources/hito_local_ds.dart';

class HitoRepositoryImpl implements HitoRepository {
  final HitoLocalDataSource ds;
  HitoRepositoryImpl(this.ds);

  @override
  Future<List<Hito>> getAll() => ds.getAllHitos();

  @override
  Future<Hito?> getById(int id) => ds.getHitoById(id);

  @override
  Future<int> crear(Hito hito) => ds.createHito(hito);

  @override
  Future<void> actualizar(Hito hito) => ds.updateHito(hito);

  @override
  Future<void> eliminar(int id) => ds.deleteHito(id);

  @override
  Future<bool> toggleCompletadoPorFecha(int hitoId, String fechaIso) =>
      ds.toggleCompletadoPorFecha(hitoId, fechaIso);

  @override
  Future<bool> isCompletadoEn(int hitoId, String fechaIso) =>
      ds.isCompletadoEn(hitoId, fechaIso);

  @override
  Future<List<HitoAgendaItem>> agendaPorDia(DateTime fecha) =>
      ds.getAgendaPorDia(fecha);

  @override
  Future<Map<String, List<HitoAgendaItem>>> agendaPorMes(int year, int month) =>
      ds.getAgendaPorMes(year, month);

  @override
  Future<HitoProgreso> progresoMensual(int hitoId, int year, int month) =>
      ds.getProgresoMensual(hitoId, year, month);

  @override
  Future<List<Hito>> conflictos({
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    int? excluirId,
  }) =>
      ds.buscarConflictos(
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        excluirId: excluirId,
      );

  @override
  Future<List<Hito>> conflictosHito(Hito hito, {int? excluirId}) =>
      ds.buscarConflictosHito(hito, excluirId: excluirId);

  @override
  Future<Map<String, List<Hito>>> realizadosRango(
          DateTime ini, DateTime fin) =>
      ds.getRealizadosRango(ini, fin);

  @override
  Future<List<({Hito hito, HitoProgreso progreso})>> progresosMensuales(
          int year, int month) =>
      ds.getProgresosMensuales(year, month);

  @override
  Future<int> reprogramarDiarios(DateTime hoy) =>
      ds.reprogramarDiariosPendientes(hoy);
}
