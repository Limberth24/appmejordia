import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/hito.dart';
import '../providers/hito_providers.dart';
import 'registrar_hito_screen.dart';

const _meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre'
];

const _diasSemana = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo'
];

/// Vista de día estilo Google Calendar (solo lectura): sección "Todo el día",
/// línea de tiempo por horas con los hitos como bloques de color y línea
/// roja de la hora actual. Tocar un hito no hace nada: es solo pantalla.
class MisionesDiaScreen extends ConsumerStatefulWidget {
  final DateTime fecha;

  const MisionesDiaScreen({super.key, required this.fecha});

  @override
  ConsumerState<MisionesDiaScreen> createState() => _MisionesDiaScreenState();
}

class _MisionesDiaScreenState extends ConsumerState<MisionesDiaScreen> {
  static const double _horaAlto = 64;
  static const double _ejeAncho = 58;
  static const double _totalAlto = 24 * _horaAlto;

  late final DateTime _dia = AppDateUtils.normalize(widget.fecha);
  final _scroll = ScrollController();
  bool _scrollInicial = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agendaAsync = ref.watch(agendaPorFechaProvider(_dia));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Misiones del día',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: agendaAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: _contenido,
      ),
    );
  }

  Widget _contenido(List<HitoAgendaItem> items) {
    final esHoy = AppDateUtils.isSameDay(_dia, DateTime.now());
    final conHora = items
        .where((e) => (e.hito.horaInicio ?? '').isNotEmpty)
        .toList();
    final sinHora = items
        .where((e) => (e.hito.horaInicio ?? '').isEmpty)
        .toList();
    final done = items.where((e) => e.completadoDia).length;
    _programarScroll(esHoy, conHora);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(esHoy, done, items.length),
        Expanded(
          child: items.isEmpty
              ? _vacio(esHoy)
              : SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.only(top: 4, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (sinHora.isNotEmpty)
                        _seccionTodoElDia(sinHora),
                      _lineaTiempo(conHora, esHoy),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ---------- Encabezado ----------

  Widget _header(bool esHoy, int done, int total) {
    final pct = total == 0 ? 0.0 : done / total;
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_dia.day}',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: esHoy ? AppColors.primary : AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esHoy
                          ? 'HOY'
                          : _diasSemana[_dia.weekday - 1].toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: esHoy
                            ? AppColors.secondary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${_meses[_dia.month - 1]} ${_dia.year}',
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total == 0 ? 'Sin misiones' : '$done de $total',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  if (total > 0)
                    const Text(
                      'completadas',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppColors.surfaceContainer,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Todo el día ----------

  Widget _seccionTodoElDia(List<HitoAgendaItem> sinHora) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TODO EL DÍA',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final e in sinHora) ...[
            _todoElDiaTile(e),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _todoElDiaTile(HitoAgendaItem e) {
    final h = e.hito;
    final done = e.completadoDia;
    return Container(
      decoration: BoxDecoration(
        color: done ? AppColors.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: done ? AppColors.secondary : h.colorValue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.titulo,
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: done
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Todo el día • ${h.tipo.label}',
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: _checkCircle(done)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Línea de tiempo ----------

  Widget _lineaTiempo(List<HitoAgendaItem> conHora, bool esHoy) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _ejeAncho,
          height: _totalAlto,
          child: Stack(
            children: [
              for (var h = 1; h < 24; h++)
                Positioned(
                  top: h * _horaAlto - 8,
                  right: 8,
                  child: Text(
                    '${h.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                left: BorderSide(color: AppColors.surfaceContainerHigh),
              ),
            ),
            height: _totalAlto,
            child: Stack(
              children: [
                for (var h = 0; h <= 24; h++)
                  Positioned(
                    top: (h * _horaAlto).clamp(0, _totalAlto - 1),
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      color: _lineaColor(h),
                    ),
                  ),
                for (final e in conHora) _bloque(e),
                if (esHoy) _lineaAhora(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Cada 3 horas la línea es más marcada para orientar la vista.
  Color _lineaColor(int hora) =>
      AppColors.outlineVariant.withValues(alpha: hora % 3 == 0 ? 0.5 : 0.3);

  Widget _bloque(HitoAgendaItem e) {
    final h = e.hito;
    final ini = h.minutosInicio!;
    final fin = h.minutosFin ?? ini + 30;
    final top = ini / 60 * _horaAlto;
    final alto = ((fin - ini).clamp(20, 24 * 60) / 60 * _horaAlto)
        .clamp(26.0, _totalAlto - top);
    final done = e.completadoDia;
    final compacto = alto < 44;
    final color = done ? AppColors.secondary : h.colorValue;
    final hora = h.horaFin != null && h.horaFin!.isNotEmpty
        ? '${h.horaInicio} – ${h.horaFin}'
        : h.horaInicio!;

    return Positioned(
      top: top + 1,
      left: 3,
      right: 14,
      height: alto,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: compacto ? 4 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (done) ...[
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    h.titulo,
                    maxLines: compacto ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (!compacto)
              Text(
                hora,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _lineaAhora() {
    final ahora = DateTime.now();
    final top = (ahora.hour * 60 + ahora.minute) / 60 * _horaAlto;
    return Positioned(
      top: (top - 5).clamp(0, _totalAlto - 10),
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Container(height: 2, color: AppColors.error)),
        ],
      ),
    );
  }

  // ---------- Estados ----------

  Widget _vacio(bool esHoy) {
    final pasado = _dia.isBefore(AppDateUtils.normalize(DateTime.now()));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available_rounded,
                  size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nada programado',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              esHoy
                  ? 'Hoy no hay misiones registradas.'
                  : 'No hay misiones para este día.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (!pasado) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          RegistrarHitoScreen(fechaInicial: _dia)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar hito'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _checkCircle(bool done) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.secondary : Colors.transparent,
        border: Border.all(
          color: done ? AppColors.secondary : AppColors.outline,
          width: 2,
        ),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
          : null,
    );
  }

  // ---------- Scroll ----------

  void _programarScroll(bool esHoy, List<HitoAgendaItem> conHora) {
    if (_scrollInicial) return;
    _scrollInicial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      double objetivo;
      if (esHoy) {
        final ahora = DateTime.now();
        objetivo =
            (ahora.hour * 60 + ahora.minute) / 60 * _horaAlto - 150;
      } else if (conHora.isNotEmpty) {
        objetivo = conHora.first.hito.minutosInicio! / 60 * _horaAlto - 100;
      } else {
        objetivo = 0;
      }
      _scroll.jumpTo(
          objetivo.clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }
}
