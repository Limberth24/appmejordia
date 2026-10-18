import 'package:intl/intl.dart';

import '../../domain/entities/hito.dart';

class HitoModel extends Hito {
  const HitoModel({
    super.id,
    required super.titulo,
    super.descripcion,
    required super.tipo,
    required super.fechaInicio,
    required super.fechaFin,
    super.horaInicio,
    super.horaFin,
    super.diasSemana = const {},
    super.completado = false,
    super.fechaCompletado,
    super.categoria,
    super.color,
    super.recordatorioMin,
    required super.createdAt,
    required super.updatedAt,
  });

  static final _isoDay = DateFormat('yyyy-MM-dd');

  static String dayToIso(DateTime d) =>
      _isoDay.format(DateTime(d.year, d.month, d.day));

  static DateTime dayFromIso(String s) {
    final dt = DateTime.parse(s);
    return DateTime(dt.year, dt.month, dt.day);
  }

  factory HitoModel.fromMap(Map<String, dynamic> m) {
    return HitoModel(
      id: m['id'] as int?,
      titulo: (m['titulo'] as String?) ?? '',
      descripcion: m['descripcion'] as String?,
      tipo: HitoTipoX.fromString(m['tipo'] as String),
      fechaInicio: dayFromIso(m['fecha_inicio'] as String),
      fechaFin: dayFromIso(m['fecha_fin'] as String),
      horaInicio: m['hora_inicio'] as String?,
      horaFin: m['hora_fin'] as String?,
      diasSemana: Hito.weekdaysFromCsv(m['dias_semana'] as String?),
      completado: (m['completado'] as int? ?? 0) == 1,
      fechaCompletado: m['fecha_completado'] == null
          ? null
          : DateTime.tryParse(m['fecha_completado'] as String),
      categoria: m['categoria'] as String?,
      color: m['color'] as int?,
      recordatorioMin: m['recordatorio_min'] as int?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'titulo': titulo.trim(),
      'descripcion': descripcion?.trim().isEmpty == true ? null : descripcion?.trim(),
      'tipo': tipo.value,
      'fecha_inicio': dayToIso(fechaInicio),
      'fecha_fin': dayToIso(fechaFin),
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'dias_semana':
          diasSemana.isEmpty ? null : Hito.weekdaysToCsv(diasSemana),
      'completado': completado ? 1 : 0,
      'fecha_completado': fechaCompletado?.toIso8601String(),
      'categoria': categoria,
      'color': color,
      'recordatorio_min': recordatorioMin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (includeId && id != null) map['id'] = id;
    return map;
  }

  factory HitoModel.fromEntity(Hito e) {
    return HitoModel(
      id: e.id,
      titulo: e.titulo,
      descripcion: e.descripcion,
      tipo: e.tipo,
      fechaInicio: e.fechaInicio,
      fechaFin: e.fechaFin,
      horaInicio: e.horaInicio,
      horaFin: e.horaFin,
      diasSemana: e.diasSemana,
      completado: e.completado,
      fechaCompletado: e.fechaCompletado,
      categoria: e.categoria,
      color: e.color,
      recordatorioMin: e.recordatorioMin,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }
}
