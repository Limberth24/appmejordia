import 'package:flutter/material.dart';

/// Tipos de hito:
/// - diario: planifica un día concreto (una sola fecha).
/// - mensual: recurrente, se repite según [diasSemana] dentro de [fechaInicio..fechaFin].
/// - puntual: bloquea un espacio con hora inicio/fin en un día concreto.
enum HitoTipo { diario, mensual, puntual }

extension HitoTipoX on HitoTipo {
  String get value => name;
  String get label {
    switch (this) {
      case HitoTipo.diario:
        return 'Diario';
      case HitoTipo.mensual:
        return 'Mensual';
      case HitoTipo.puntual:
        return 'Puntual';
    }
  }

  static HitoTipo fromString(String s) {
    switch (s) {
      case 'diario':
        return HitoTipo.diario;
      case 'mensual':
        return HitoTipo.mensual;
      case 'puntual':
        return HitoTipo.puntual;
      default:
        throw ArgumentError('Tipo de hito desconocido: $s');
    }
  }
}

enum HitoEstado { pendiente, completado, vencido }

extension HitoEstadoX on HitoEstado {
  String get label {
    switch (this) {
      case HitoEstado.pendiente:
        return 'Pendiente';
      case HitoEstado.completado:
        return 'Completado';
      case HitoEstado.vencido:
        return 'Vencido';
    }
  }
}

class Hito {
  final int? id;
  final String titulo;
  final String? descripcion;
  final HitoTipo tipo;
  final DateTime fechaInicio; // solo fecha (normalizada)
  final DateTime fechaFin; // solo fecha
  final String? horaInicio; // "HH:mm"
  final String? horaFin; // "HH:mm"
  final Set<int> diasSemana; // 1=Lun..7=Dom (DateTime.weekday)
  final bool completado; // para diario/puntual; mensual usa completions
  final DateTime? fechaCompletado;
  final String? categoria;
  final int? color; // ARGB
  final int? recordatorioMin; // minutos antes, null = sin recordatorio
  final DateTime createdAt;
  final DateTime updatedAt;

  const Hito({
    this.id,
    required this.titulo,
    this.descripcion,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    this.horaInicio,
    this.horaFin,
    this.diasSemana = const {},
    this.completado = false,
    this.fechaCompletado,
    this.categoria,
    this.color,
    this.recordatorioMin,
    required this.createdAt,
    required this.updatedAt,
  });

  Hito copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    HitoTipo? tipo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? Function()? horaInicio,
    String? Function()? horaFin,
    Set<int>? diasSemana,
    bool? completado,
    DateTime? Function()? fechaCompletado,
    String? Function()? categoria,
    int? Function()? color,
    int? Function()? recordatorioMin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Hito(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      horaInicio: horaInicio != null ? horaInicio() : this.horaInicio,
      horaFin: horaFin != null ? horaFin() : this.horaFin,
      diasSemana: diasSemana ?? this.diasSemana,
      completado: completado ?? this.completado,
      fechaCompletado:
          fechaCompletado != null ? fechaCompletado() : this.fechaCompletado,
      categoria: categoria != null ? categoria() : this.categoria,
      color: color != null ? color() : this.color,
      recordatorioMin:
          recordatorioMin != null ? recordatorioMin() : this.recordatorioMin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ¿Este hito ocurre el día [dia] (fecha normalizada)?
  bool ocurreEl(DateTime dia) {
    final d = DateTime(dia.year, dia.month, dia.day);
    final ini = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    if (d.isBefore(ini) || d.isAfter(fin)) return false;
    switch (tipo) {
      case HitoTipo.diario:
      case HitoTipo.puntual:
        return d.isAtSameMomentAs(ini);
      case HitoTipo.mensual:
        if (diasSemana.isEmpty) return false;
        return diasSemana.contains(d.weekday);
    }
  }

  /// Minutos desde medianoche para ordenar. Sin hora -> al final (null).
  int? get minutosInicio => _hhmmToMin(horaInicio);
  int? get minutosFin => _hhmmToMin(horaFin);

  static int? _hhmmToMin(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String weekdaysToCsv(Set<int> days) {
    final sorted = days.toList()..sort();
    return sorted.join(',');
  }

  static Set<int> weekdaysFromCsv(String? csv) {
    if (csv == null || csv.trim().isEmpty) return {};
    return csv
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((e) => e >= 1 && e <= 7)
        .toSet();
  }

  Color get colorValue =>
      color != null ? Color(color!) : const Color(0xFF1A237E);

  HitoEstado estadoPara(DateTime fecha, {required bool completadoDia}) {
    if (completadoDia) return HitoEstado.completado;
    final hoy = DateTime.now();
    final h = DateTime(hoy.year, hoy.month, hoy.day);
    final d = DateTime(fecha.year, fecha.month, fecha.day);
    if (d.isBefore(h)) return HitoEstado.vencido;
    return HitoEstado.pendiente;
  }
}

/// Un hito instanciado en un día concreto de la agenda.
class HitoAgendaItem {
  final Hito hito;
  final DateTime fecha; // día normalizado
  final bool completadoDia;

  const HitoAgendaItem({
    required this.hito,
    required this.fecha,
    required this.completadoDia,
  });

  HitoEstado get estado => hito.estadoPara(fecha, completadoDia: completadoDia);

  int get ordenHora => hito.minutosInicio ?? 24 * 60 + 1;
}

/// Progreso de un hito recurrente en un mes: "12/15 sesiones completadas".
class HitoProgreso {
  final int hitoId;
  final int totalSesiones;
  final int completadas;

  const HitoProgreso({
    required this.hitoId,
    required this.totalSesiones,
    required this.completadas,
  });

  String get label => '$completadas/$totalSesiones sesiones';
  String get labelCorta => '$completadas/$totalSesiones';
  double get proporcion =>
      totalSesiones == 0 ? 0 : completadas / totalSesiones;
}
