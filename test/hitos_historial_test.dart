import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:appmejordia/core/db/app_database.dart';

import 'package:appmejordia/features/habit/data/datasources/habit_local_ds.dart';
import 'package:appmejordia/features/habit/data/repositories/habit_repository_impl.dart';
import 'package:appmejordia/features/hitos/data/repositories/hito_repository_impl.dart';
import 'package:appmejordia/features/hitos/data/datasources/hito_local_ds.dart';
import 'package:appmejordia/features/hitos/domain/entities/hito.dart';
import 'package:appmejordia/features/hitos/presentation/providers/hito_providers.dart';

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _day(DateTime base, int offset) {
  final t = base.add(Duration(days: offset));
  return DateTime(t.year, t.month, t.day);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String dbDir;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('mejordia_test');
    dbDir = dir.path;
    // La factoría FFI decide la ruta (ignora el channel mock):
    // se fija al temp dir para aislar cada corrida.
    await databaseFactoryFfi.setDatabasesPath(dbDir);
  });

  // BD fresca por test para que no se contaminen entre sí.
  setUp(() async {
    await AppDatabase.close();
    final f = File(p.join(dbDir, 'mejordia.db'));
    if (await f.exists()) await f.delete();
  });

  test('historial: realizados por rango terminan y agrupan por día',
      () async {
    final repo = HitoRepositoryImpl(HitoLocalDataSource());
    final hoy = DateTime.now();

    final mensualId = await repo.crear(Hito(
      titulo: 'Mensual test',
      tipo: HitoTipo.mensual,
      fechaInicio: DateTime(hoy.year, hoy.month, 1),
      fechaFin: DateTime(hoy.year, hoy.month + 1, 0),
      horaInicio: '10:00',
      horaFin: '11:00',
      diasSemana: const {1, 2, 3, 4, 5, 6, 7},
      createdAt: hoy,
      updatedAt: hoy,
    ));
    for (final off in [3, 2, 1]) {
      await repo.toggleCompletadoPorFecha(mensualId, _iso(_day(hoy, -off)));
    }

    final diarioId = await repo.crear(Hito(
      titulo: 'Diario test',
      tipo: HitoTipo.diario,
      fechaInicio: _day(hoy, 0),
      fechaFin: _day(hoy, 0),
      horaInicio: '08:00',
      horaFin: '09:00',
      createdAt: hoy,
      updatedAt: hoy,
    ));
    await repo.toggleCompletadoPorFecha(diarioId, _iso(_day(hoy, 0)));

    final res = await repo
        .realizadosRango(_day(hoy, -6), _day(hoy, 0))
        .timeout(const Duration(seconds: 15));

    expect(res.isNotEmpty, isTrue);
    // Hoy: solo el diario (el mensual no se marcó hoy).
    expect(res[_iso(_day(hoy, 0))]?.length ?? 0, 1);
    // Días -1..-3: solo el mensual.
    for (final off in [3, 2, 1]) {
      expect(res[_iso(_day(hoy, -off))]?.length ?? 0, 1);
    }
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('historial: provider de realizados completa (ruta exacta de la UI)',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final map = await container.read(realizadosRangoProvider.future).timeout(
          const Duration(seconds: 15),
        );
    expect(map, isA<Map<String, List<Hito>>>());
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('racha con historial largo termina y calcula bien', () async {
    final habDs = HabitLocalDataSource();
    final habRepo = HabitRepositoryImpl(habDs);
    final hoy = DateTime.now();
    for (var i = 0; i < 400; i++) {
      final dt = hoy.subtract(Duration(days: i));
      await habDs.upsertRegistro(
          _iso(DateTime(dt.year, dt.month, dt.day)), 1);
    }
    final racha = await habRepo
        .getRacha(year: hoy.year, month: hoy.month)
        .timeout(const Duration(seconds: 15));
    expect(racha.actual, 400);
    expect(racha.mejorHistorica >= 400, isTrue);
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('conflictos con rangos amplios terminan y bloquean', () async {
    final repo = HitoRepositoryImpl(HitoLocalDataSource());
    final hoy = DateTime.now();
    await repo.crear(Hito(
      titulo: 'Base amplia',
      tipo: HitoTipo.mensual,
      fechaInicio: DateTime(2020, 1, 1),
      fechaFin: DateTime(2035, 12, 31),
      horaInicio: '11:00',
      horaFin: '12:00',
      diasSemana: const {1, 2, 3, 4, 5, 6, 7},
      createdAt: hoy,
      updatedAt: hoy,
    ));

    final candidato = Hito(
      titulo: 'Candidato',
      tipo: HitoTipo.puntual,
      fechaInicio: _day(hoy, 0),
      fechaFin: _day(hoy, 0),
      horaInicio: '11:30',
      horaFin: '12:30',
      createdAt: hoy,
      updatedAt: hoy,
    );
    final choques = await repo
        .conflictosHito(candidato)
        .timeout(const Duration(seconds: 15));
    expect(choques.isNotEmpty, isTrue);

    // Crear con choque debe lanzar StateError (bloqueo en datos).
    await expectLater(
      repo.crear(candidato),
      throwsA(isA<StateError>()),
    );
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('agenda del mes y progresos terminan', () async {
    final repo = HitoRepositoryImpl(HitoLocalDataSource());
    final hoy = DateTime.now();
    final agenda = await repo
        .agendaPorMes(hoy.year, hoy.month)
        .timeout(const Duration(seconds: 15));
    expect(agenda, isA<Map<String, List<HitoAgendaItem>>>());

    final todos = await repo.getAll();
    for (final h in todos.where((e) => e.tipo == HitoTipo.mensual)) {
      final p = await repo
          .progresoMensual(h.id!, hoy.year, hoy.month)
          .timeout(const Duration(seconds: 15));
      expect(p.totalSesiones >= 0, isTrue);
    }
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('reprogramar diarios pendientes mueve a mañana', () async {
    final repo = HitoRepositoryImpl(HitoLocalDataSource());
    final hoy = DateTime.now();
    final manana = _day(hoy, 1);

    // Agenda de mañana 11:00-12:00 (el ejemplo del usuario).
    await repo.crear(Hito(
      titulo: 'Reunión mañana',
      tipo: HitoTipo.puntual,
      fechaInicio: manana,
      fechaFin: manana,
      horaInicio: '11:00',
      horaFin: '12:00',
      createdAt: hoy,
      updatedAt: hoy,
    ));
    // Diario pendiente de hoy 11:30-12:30 (chocaría mañana).
    await repo.crear(Hito(
      titulo: 'Diario que falla',
      tipo: HitoTipo.diario,
      fechaInicio: _day(hoy, 0),
      fechaFin: _day(hoy, 0),
      horaInicio: '11:30',
      horaFin: '12:30',
      createdAt: hoy,
      updatedAt: hoy,
    ));

    final movidos = await repo
        .reprogramarDiarios(_day(hoy, 0))
        .timeout(const Duration(seconds: 15));
    expect(movidos >= 1, isTrue);

    final agendaManana = await repo.agendaPorDia(manana);
    final movido = agendaManana.firstWhere(
        (e) => e.hito.titulo == 'Diario que falla');
    // Duración 1h y antes de las 11:00.
    expect(movido.hito.horaFin, '11:00');
    expect(movido.hito.horaInicio, '10:00');
  }, timeout: const Timeout(Duration(seconds: 90)));
}
