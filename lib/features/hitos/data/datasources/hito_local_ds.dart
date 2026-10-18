import 'package:sqflite/sqflite.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/hito.dart';
import '../models/hito_model.dart';

/// Endpoints locales de hitos (CRUD + completado por fecha + agenda día/mes).
class HitoLocalDataSource {
  Future<Database> get _db async => AppDatabase.instance;

  // ---------- Validaciones ----------

  static final _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  void validar(Hito h) {
    if (h.titulo.trim().length < 2) {
      throw ArgumentError('El título necesita al menos 2 caracteres.');
    }
    if (h.titulo.trim().length > 80) {
      throw ArgumentError('El título no puede superar 80 caracteres.');
    }
    final ini = DateTime(h.fechaInicio.year, h.fechaInicio.month, h.fechaInicio.day);
    final fin = DateTime(h.fechaFin.year, h.fechaFin.month, h.fechaFin.day);
    if (fin.isBefore(ini)) {
      throw ArgumentError('La fecha de fin no puede ser anterior al inicio.');
    }

    if (h.horaInicio != null && h.horaInicio!.isNotEmpty && !_hhmm.hasMatch(h.horaInicio!)) {
      throw ArgumentError('Hora de inicio inválida (usa HH:mm).');
    }
    if (h.horaFin != null && h.horaFin!.isNotEmpty && !_hhmm.hasMatch(h.horaFin!)) {
      throw ArgumentError('Hora de fin inválida (usa HH:mm).');
    }
    final hasIni = h.horaInicio != null && h.horaInicio!.isNotEmpty;
    final hasFin = h.horaFin != null && h.horaFin!.isNotEmpty;
    if (hasIni != hasFin) {
      // Permitimos solo hora inicio sin fin para diario/mensual, pero no a medias en puntual.
      if (h.tipo == HitoTipo.puntual) {
        throw ArgumentError('Un hito puntual necesita hora de inicio y fin.');
      }
    }
    if (hasIni && hasFin && h.horaInicio!.compareTo(h.horaFin!) >= 0) {
      throw ArgumentError('La hora de fin debe ser posterior al inicio.');
    }

    switch (h.tipo) {
      case HitoTipo.diario:
        if (!_isSameDay(ini, fin)) {
          throw ArgumentError('Un hito diario ocurre en un solo día.');
        }
        break;
      case HitoTipo.puntual:
        if (!_isSameDay(ini, fin)) {
          throw ArgumentError('Un hito puntual bloquea un solo día.');
        }
        if (!hasIni || !hasFin) {
          throw ArgumentError('Un hito puntual necesita hora de inicio y fin.');
        }
        break;
      case HitoTipo.mensual:
        if (h.diasSemana.isEmpty) {
          throw ArgumentError('Elige al menos un día de la semana.');
        }
        if (fin.difference(ini).inDays < 0) {
          throw ArgumentError('Rango de fechas inválido.');
        }
        break;
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------- CRUD ----------

  Future<List<Hito>> getAllHitos() async {
    final db = await _db;
    final rows = await db.query('hitos', orderBy: 'fecha_inicio ASC, hora_inicio ASC');
    return rows.map(HitoModel.fromMap).toList();
  }

  Future<Hito?> getHitoById(int id) async {
    final db = await _db;
    final rows = await db.query('hitos', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return HitoModel.fromMap(rows.first);
  }

  Future<int> createHito(Hito hito) async {
    validar(hito);
    if (_tieneHorario(hito)) {
      final conflictos =
          await buscarConflictosHito(hito, excluirId: hito.id);
      if (conflictos.isNotEmpty) {
        throw StateError(
            'El horario choca con "${conflictos.first.titulo}" (${conflictos.first.horaInicio}-${conflictos.first.horaFin}). Ningún horario puede solaparse con otro.');
      }
    }
    final db = await _db;
    final now = DateTime.now();
    final model = HitoModel.fromEntity(hito.copyWith(
      createdAt: now,
      updatedAt: now,
    ));
    return db.insert('hitos', model.toMap());
  }

  Future<void> updateHito(Hito hito) async {
    if (hito.id == null) throw ArgumentError('Falta id para actualizar.');
    validar(hito);
    if (_tieneHorario(hito)) {
      final conflictos =
          await buscarConflictosHito(hito, excluirId: hito.id);
      if (conflictos.isNotEmpty) {
        throw StateError(
            'El horario choca con "${conflictos.first.titulo}" (${conflictos.first.horaInicio}-${conflictos.first.horaFin}). Ningún horario puede solaparse con otro.');
      }
    }
    final db = await _db;
    final model = HitoModel.fromEntity(
        hito.copyWith(updatedAt: DateTime.now()));
    await db.update('hitos', model.toMap(),
        where: 'id = ?', whereArgs: [hito.id]);
  }

  Future<void> deleteHito(int id) async {
    final db = await _db;
    await db.delete('hito_completions', where: 'hito_id = ?', whereArgs: [id]);
    await db.delete('hitos', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Completado por fecha ----------

  Future<bool> isCompletadoEn(int hitoId, String fechaIso) async {
    final db = await _db;
    final hito = await getHitoById(hitoId);
    if (hito == null) return false;
    if (hito.tipo == HitoTipo.mensual) {
      final rows = await db.query('hito_completions',
          where: 'hito_id = ? AND fecha = ?',
          whereArgs: [hitoId, fechaIso],
          limit: 1);
      return rows.isNotEmpty;
    }
    return hito.completado;
  }

  /// Marca/desmarca un hito en una fecha concreta.
  /// - mensual: inserta/borra fila en hito_completions.
  /// - diario/puntual: actualiza hitos.completado + fecha_completado.
  /// Retorna el nuevo estado (true = completado).
  Future<bool> toggleCompletadoPorFecha(int hitoId, String fechaIso) async {
    final db = await _db;
    final hito = await getHitoById(hitoId);
    if (hito == null) throw StateError('Hito no encontrado.');

    final fecha = HitoModel.dayFromIso(fechaIso);
    final hoy = DateTime.now();
    final h = DateTime(hoy.year, hoy.month, hoy.day);
    if (fecha.isAfter(h)) {
      throw StateError('No puedes completar días futuros.');
    }

    if (hito.tipo == HitoTipo.mensual) {
      final done = await isCompletadoEn(hitoId, fechaIso);
      if (done) {
        await db.delete('hito_completions',
            where: 'hito_id = ? AND fecha = ?', whereArgs: [hitoId, fechaIso]);
        return false;
      } else {
        await db.insert(
            'hito_completions',
            {
              'hito_id': hitoId,
              'fecha': fechaIso,
              'completado_en': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore);
        return true;
      }
    } else {
      final nuevo = !hito.completado;
      await db.update(
          'hitos',
          {
            'completado': nuevo ? 1 : 0,
            'fecha_completado':
                nuevo ? DateTime.now().toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [hitoId]);
      return nuevo;
    }
  }

  // ---------- Reprogramación al fallar el día ----------

  static int _hhmmToMin(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static String _minToHhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  /// Pasa los hitos diarios pendientes de [hoy] a mañana (misma hora).
  /// Si choca con la agenda de mañana, se coloca antes del bloque que choca
  /// según su duración; si no cabe antes, después del último bloque.
  /// Solo aplica a diarios (el mensual ya cubre todo el mes).
  /// Retorna cuántos se movieron.
  Future<int> reprogramarDiariosPendientes(DateTime hoy) async {
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    final manana = dia.add(const Duration(days: 1));
    final mananaIso = HitoModel.dayToIso(manana);
    final todos = await getAllHitos();
    final pendientes = todos
        .where((h) =>
            h.tipo == HitoTipo.diario &&
            _isSameDay(
                DateTime(h.fechaInicio.year, h.fechaInicio.month,
                    h.fechaInicio.day),
                dia) &&
            !h.completado)
        .toList();
    var movidos = 0;
    for (final h in pendientes) {
      var hi = h.horaInicio ?? '';
      var hf = h.horaFin ?? '';
      if (hi.isNotEmpty && hf.isNotEmpty) {
        final slot = await _huecoAntesDeAgenda(h.id, manana, hi, hf);
        if (slot == null) continue;
        hi = slot.$1;
        hf = slot.$2;
      }
      final db = await _db;
      await db.update(
        'hitos',
        {
          'fecha_inicio': mananaIso,
          'fecha_fin': mananaIso,
          'hora_inicio': hi.isEmpty ? null : hi,
          'hora_fin': hf.isEmpty ? null : hf,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [h.id],
      );
      movidos++;
    }
    return movidos;
  }

  /// Hueco para un bloque de duración (hf-hi) que idealmente empieza en [hi]
  /// el día [dia], evitando los hitos con horario de ese día (sin [excluirId]).
  /// Retorna null si no cabe ni antes ni después.
  Future<(String, String)?> _huecoAntesDeAgenda(
      int? excluirId, DateTime dia, String hi, String hf) async {
    final dur = _hhmmToMin(hf) - _hhmmToMin(hi);
    if (dur <= 0) return null;
    final agenda = await getAgendaPorDia(dia);
    final bloques = <(int, int)>[];
    for (final item in agenda) {
      if (excluirId != null && item.hito.id == excluirId) continue;
      final a = item.hito.horaInicio ?? '';
      final b = item.hito.horaFin ?? '';
      if (a.isEmpty || b.isEmpty) continue;
      final s = _hhmmToMin(a);
      final e = _hhmmToMin(b);
      if (e > s) bloques.add((s, e));
    }
    bloques.sort((x, y) => x.$1.compareTo(y.$1));

    bool choca(int ini) {
      final fin = ini + dur;
      for (final bl in bloques) {
        if (ini < bl.$2 && bl.$1 < fin) return true;
      }
      return false;
    }

    (int, int)? primeroQueChoca(int ini) {
      final fin = ini + dur;
      for (final bl in bloques) {
        if (ini < bl.$2 && bl.$1 < fin) return bl;
      }
      return null;
    }

    var inicio = _hhmmToMin(hi);
    var guard = 0;
    while (choca(inicio) && guard < 48) {
      guard++;
      final bl = primeroQueChoca(inicio);
      if (bl == null) break;
      inicio = bl.$1 - dur;
      if (inicio < 0) {
        // No cabe antes: después del último bloque del día.
        final ultimoFin =
            bloques.map((b) => b.$2).reduce((a, b) => a > b ? a : b);
        if (ultimoFin + dur > 24 * 60) return null;
        return (_minToHhmm(ultimoFin), _minToHhmm(ultimoFin + dur));
      }
    }
    if (inicio < 0 || inicio + dur > 24 * 60) return null;
    return (_minToHhmm(inicio), _minToHhmm(inicio + dur));
  }

  // ---------- Agenda ----------

  /// Hitos que ocurren el día [fecha] ordenados por hora (sin hora al final).
  Future<List<HitoAgendaItem>> getAgendaPorDia(DateTime fecha) async {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final iso = HitoModel.dayToIso(dia);
    final todos = await getAllHitos();
    final items = <HitoAgendaItem>[];
    for (final h in todos) {
      if (!h.ocurreEl(dia)) continue;
      final done = h.tipo == HitoTipo.mensual
          ? await isCompletadoEn(h.id!, iso)
          : h.completado;
      items.add(HitoAgendaItem(hito: h, fecha: dia, completadoDia: done));
    }
    items.sort((a, b) {
      final c = a.ordenHora.compareTo(b.ordenHora);
      if (c != 0) return c;
      return a.hito.titulo.compareTo(b.hito.titulo);
    });
    return items;
  }

  /// Agenda de todo un mes: isoFecha -> items del día.
  Future<Map<String, List<HitoAgendaItem>>> getAgendaPorMes(
      int year, int month) async {
    final todos = await getAllHitos();
    final db = await _db;
    // Traer completions del mes de una vez para no hacer N queries.
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final compRows = await db.query('hito_completions',
        where: 'fecha LIKE ?', whereArgs: ['$prefix-%']);
    final doneSet = compRows
        .map((r) => '${r['hito_id']}|${r['fecha']}')
        .toSet();

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final result = <String, List<HitoAgendaItem>>{};
    for (var d = 1; d <= daysInMonth; d++) {
      final dia = DateTime(year, month, d);
      final iso = HitoModel.dayToIso(dia);
      final items = <HitoAgendaItem>[];
      for (final h in todos) {
        if (!h.ocurreEl(dia)) continue;
        final done = h.tipo == HitoTipo.mensual
            ? doneSet.contains('${h.id}|$iso')
            : h.completado;
        items.add(HitoAgendaItem(hito: h, fecha: dia, completadoDia: done));
      }
      items.sort((a, b) => a.ordenHora.compareTo(b.ordenHora));
      if (items.isNotEmpty) result[iso] = items;
    }
    return result;
  }

  /// Progreso mensual de un hito: sesiones esperadas vs completadas en [year/month].
  Future<HitoProgreso> getProgresoMensual(
      int hitoId, int year, int month) async {
    final hito = await getHitoById(hitoId);
    if (hito == null) throw StateError('Hito no encontrado.');
    final daysInMonth = DateTime(year, month + 1, 0).day;
    var total = 0;
    final ocurrences = <String>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final dia = DateTime(year, month, d);
      if (hito.ocurreEl(dia)) {
        total++;
        ocurrences.add(HitoModel.dayToIso(dia));
      }
    }
    var done = 0;
    if (total > 0) {
      if (hito.tipo == HitoTipo.mensual) {
        for (final iso in ocurrences) {
          if (await isCompletadoEn(hitoId, iso)) done++;
        }
      } else {
        if (hito.completado) {
          // Cuenta 1 si su fecha cae en este mes.
          final ini = hito.fechaInicio;
          if (ini.year == year && ini.month == month) done = 1;
        }
      }
    }
    return HitoProgreso(hitoId: hitoId, totalSesiones: total, completadas: done);
  }

  // ---------- Historial por rango ----------

  /// Hitos realizados entre [ini] y [fin] (ambos incluidos),
  /// agrupados por fecha iso (solo días con al menos uno).
  /// - mensual: filas de hito_completions en el rango.
  /// - diario/puntual: hitos con completado=1 y fecha_completado en el rango.
  /// Todo en 3 queries (sin N+1) para no bloquear el hilo principal.
  Future<Map<String, List<Hito>>> getRealizadosRango(
      DateTime ini, DateTime fin) async {
    final db = await _db;
    final a = HitoModel.dayToIso(DateTime(ini.year, ini.month, ini.day));
    final b = HitoModel.dayToIso(DateTime(fin.year, fin.month, fin.day));
    final result = <String, List<Hito>>{};
    void add(String iso, Hito h) {
      if (iso.compareTo(a) < 0 || iso.compareTo(b) > 0) return;
      (result[iso] ??= []).add(h);
    }

    final todos = await getAllHitos();
    final porId = <int, Hito>{};
    for (final h in todos) {
      if (h.id != null) porId[h.id!] = h;
    }

    final compRows = await db.query(
      'hito_completions',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [a, b],
      orderBy: 'fecha ASC',
    );
    for (final r in compRows) {
      final h = porId[r['hito_id'] as int];
      if (h == null) continue;
      add(r['fecha'] as String, h);
    }

    for (final h in todos) {
      if (h.tipo == HitoTipo.mensual || !h.completado) continue;
      final fc = h.fechaCompletado;
      if (fc == null) continue;
      add(HitoModel.dayToIso(fc), h);
    }
    for (final list in result.values) {
      list.sort((x, y) => x.titulo.compareTo(y.titulo));
    }
    return result;
  }

  /// Progresos de los hitos mensuales con sesiones en [year/month].
  /// Todo en 2 queries (sin N+1 por hito y día).
  Future<List<({Hito hito, HitoProgreso progreso})>> getProgresosMensuales(
      int year, int month) async {
    final db = await _db;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final compRows = await db.query('hito_completions',
        where: 'fecha LIKE ?', whereArgs: ['$prefix-%']);
    final doneSet = compRows
        .map((r) => '${r['hito_id']}|${r['fecha']}')
        .toSet();

    final todos = await getAllHitos();
    final out = <({Hito hito, HitoProgreso progreso})>[];
    for (final h in todos) {
      if (h.tipo != HitoTipo.mensual || h.id == null) continue;
      var total = 0;
      var hechas = 0;
      for (var d = 1; d <= daysInMonth; d++) {
        final dia = DateTime(year, month, d);
        if (!h.ocurreEl(dia)) continue;
        total++;
        if (doneSet.contains('${h.id}|${HitoModel.dayToIso(dia)}')) {
          hechas++;
        }
      }
      if (total > 0) {
        out.add((
          hito: h,
          progreso: HitoProgreso(
              hitoId: h.id!, totalSesiones: total, completadas: hechas)
        ));
      }
    }
    return out;
  }

  // ---------- Solapamientos (puntuales) ----------

  static bool _tieneHorario(Hito h) =>
      (h.horaInicio ?? '').isNotEmpty && (h.horaFin ?? '').isNotEmpty;

  /// Hitos con horario (de cualquier tipo) que se solapan con [candidato]:
  /// comparten al menos un día en que ambos ocurren y sus rangos de hora
  /// se cruzan. Sin horario en el candidato no hay choques.
  Future<List<Hito>> buscarConflictosHito(Hito candidato,
      {int? excluirId}) async {
    final hi = candidato.horaInicio ?? '';
    final hf = candidato.horaFin ?? '';
    if (hi.isEmpty || hf.isEmpty) return [];
    final db = await _db;
    final rows = await db.query('hitos');
    final out = <Hito>[];
    for (final r in rows) {
      final h = HitoModel.fromMap(r);
      if (excluirId != null && h.id == excluirId) continue;
      if (candidato.id != null && h.id == candidato.id) continue;
      final aIni = h.horaInicio ?? '';
      final aFin = h.horaFin ?? '';
      if (aIni.isEmpty || aFin.isEmpty) continue;
      // Solapa si inicio < otroFin && otroInicio < fin (HH:mm comparable).
      if (!(hi.compareTo(aFin) < 0 && aIni.compareTo(hf) < 0)) continue;
      if (_compartenDia(candidato, h)) out.add(h);
    }
    return out;
  }

  /// ¿Ambos hitos ocurren al menos un mismo día? Se recorre el rango
  /// común de fechas y basta un día donde ambos ocurran.
  bool _compartenDia(Hito a, Hito b) {
    final aIni =
        DateTime(a.fechaInicio.year, a.fechaInicio.month, a.fechaInicio.day);
    final aFin =
        DateTime(a.fechaFin.year, a.fechaFin.month, a.fechaFin.day);
    final bIni =
        DateTime(b.fechaInicio.year, b.fechaInicio.month, b.fechaInicio.day);
    final bFin =
        DateTime(b.fechaFin.year, b.fechaFin.month, b.fechaFin.day);
    final ini = aIni.isAfter(bIni) ? aIni : bIni;
    final fin = aFin.isBefore(bFin) ? aFin : bFin;
    if (fin.isBefore(ini)) return false;
    for (var d = ini; !d.isAfter(fin); d = d.add(const Duration(days: 1))) {
      if (a.ocurreEl(d) && b.ocurreEl(d)) return true;
    }
    return false;
  }

  /// Puntuales que se solapan con [horaInicio,horaFin] en [fecha].
  Future<List<Hito>> buscarConflictos({
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    int? excluirId,
  }) async {
    final db = await _db;
    final iso = HitoModel.dayToIso(fecha);
    final rows = await db.query(
      'hitos',
      where: 'tipo = ? AND fecha_inicio = ?',
      whereArgs: ['puntual', iso],
    );
    final out = <Hito>[];
    for (final r in rows) {
      final h = HitoModel.fromMap(r);
      if (excluirId != null && h.id == excluirId) continue;
      final aIni = h.horaInicio ?? '';
      final aFin = h.horaFin ?? '';
      if (aIni.isEmpty || aFin.isEmpty) continue;
      // Solapa si inicio < otroFin && otroInicio < fin (HH:mm comparable).
      if (horaInicio.compareTo(aFin) < 0 && aIni.compareTo(horaFin) < 0) {
        out.add(h);
      }
    }
    return out;
  }
}
