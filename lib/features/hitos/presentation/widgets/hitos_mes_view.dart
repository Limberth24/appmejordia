import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../habit/presentation/providers/habit_providers.dart';
import '../../domain/entities/hito.dart';
import '../providers/hito_providers.dart';
import '../screens/registrar_hito_screen.dart';
import 'hito_meta_card.dart';

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

String _fechaCorta(DateTime d) => '${d.day} de ${_meses[d.month - 1]}';

/// Vista mensual de hitos con datos reales (diseño "Hitos del Mes").
class HitosMesView extends ConsumerStatefulWidget {
  const HitosMesView({super.key});

  @override
  ConsumerState<HitosMesView> createState() => _HitosMesViewState();
}

class _MetaVm {
  final Hito hito;
  final int total;
  final int hechas;
  final HitoEstado estado;
  final String subtitulo;
  final String unidad;

  const _MetaVm({
    required this.hito,
    required this.total,
    required this.hechas,
    required this.estado,
    required this.subtitulo,
    required this.unidad,
  });
}

class _HitosMesViewState extends ConsumerState<HitosMesView> {
  /// false = Día (hoy), true = Mes.
  bool _verMes = false;
  int? _busyId;

  @override
  Widget build(BuildContext context) {
    final focused = ref.watch(focusedMonthProvider);
    final mensualesAsync = ref.watch(progresosMensualesProvider);
    final todosAsync = ref.watch(allHitosProvider);
    final hoyAsync = ref.watch(agendaHoyProvider);

    final mensuales = mensualesAsync.valueOrNull;
    final todos = todosAsync.valueOrNull;
    final hoyItems = hoyAsync.valueOrNull;

    Widget content;
    if (mensualesAsync.hasError) {
      content = _errorBox('${mensualesAsync.error}');
    } else if (todosAsync.hasError) {
      content = _errorBox('${todosAsync.error}');
    } else if (mensuales == null || todos == null || hoyItems == null) {
      content = const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      final hoyMap = {for (final e in hoyItems) e.hito.id: e.completadoDia};
      content = _contenido(focused, mensuales, todos, hoyItems, hoyMap);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: content,
        ),
      ),
    );
  }

  /// Subtítulo con la hora de inicio y fin cuando el hito lleva horario,
  /// más el tipo (Mensual / Agenda / Diario) para identificarlo.
  String _subConHora(Hito h, String alternativa) {
    final hi = h.horaInicio ?? '';
    final hf = h.horaFin ?? '';
    if (hi.isEmpty || hf.isEmpty) return alternativa;
    return '$hi–$hf • ${_tipoCorto(h.tipo)}';
  }

  String _tipoCorto(HitoTipo t) {
    switch (t) {
      case HitoTipo.mensual:
        return 'Mensual';
      case HitoTipo.puntual:
        return 'Agenda';
      case HitoTipo.diario:
        return 'Diario';
    }
  }

  List<_MetaVm> _metasMes(
    DateTime focused,
    List<({Hito hito, HitoProgreso progreso})> mensuales,
    List<Hito> todos,
  ) {
    final out = <_MetaVm>[];
    for (final e in mensuales) {
      final total = e.progreso.totalSesiones;
      final hechas = e.progreso.completadas;
      final done = total > 0 && hechas >= total;
      out.add(_MetaVm(
        hito: e.hito,
        total: total,
        hechas: hechas,
        estado:
            done ? HitoEstado.completado : HitoEstado.pendiente,
        subtitulo: done
            ? 'Meta completada'
            : _subConHora(
                e.hito, 'Límite: ${_fechaCorta(e.hito.fechaFin)}'),
        unidad: total == 1 ? 'sesión' : 'sesiones',
      ));
    }
    final hoy = AppDateUtils.normalize(DateTime.now());
    for (final h in todos) {
      if (h.tipo == HitoTipo.mensual) continue;
      final f = AppDateUtils.normalize(h.fechaInicio);
      if (f.year != focused.year || f.month != focused.month) continue;
      final done = h.completado;
      final estado = done
          ? HitoEstado.completado
          : (AppDateUtils.normalize(h.fechaFin).isBefore(hoy)
              ? HitoEstado.vencido
              : HitoEstado.pendiente);
      out.add(_MetaVm(
        hito: h,
        total: 1,
        hechas: done ? 1 : 0,
        estado: estado,
        subtitulo: done
            ? 'Completado'
            : _subConHora(
                h,
                estado == HitoEstado.vencido
                    ? 'Venció el ${_fechaCorta(h.fechaFin)}'
                    : 'Límite: ${_fechaCorta(h.fechaFin)}'),
        unidad: 'día',
      ));
    }
    return out;
  }

  /// Metas del día (hoy): cada hito cuenta como una sesión del día.
  List<_MetaVm> _metasDia(List<HitoAgendaItem> hoyItems) {
    return hoyItems.map((e) {
      final done = e.completadoDia;
      final estado = done
          ? HitoEstado.completado
          : e.hito.estadoPara(e.fecha, completadoDia: false);
      return _MetaVm(
        hito: e.hito,
        total: 1,
        hechas: done ? 1 : 0,
        estado: estado,
        subtitulo: done
            ? 'Completado'
            : _subConHora(e.hito, 'Para hoy'),
        unidad: 'día',
      );
    }).toList();
  }

  Widget _contenido(
    DateTime focused,
    List<({Hito hito, HitoProgreso progreso})> mensuales,
    List<Hito> todos,
    List<HitoAgendaItem> hoyItems,
    Map<int?, bool> hoyMap,
  ) {
    final metasMes = _metasMes(focused, mensuales, todos);
    final metasDia = _metasDia(hoyItems);
    // En Mes solo se muestran los que faltan completar (lista corta);
    // en Día se ven los de hoy con su estado.
    final ocultosMes = metasMes
        .where((m) => m.estado == HitoEstado.completado)
        .length;
    final base = _verMes ? metasMes : metasDia;
    final metas = _verMes
        ? base.where((m) => m.estado != HitoEstado.completado).toList()
        : base;
    final total = base.length;
    final logrados =
        base.where((m) => m.estado == HitoEstado.completado).length;
    final enProgreso = total - logrados;
    final totalSes = base.fold<int>(0, (a, m) => a + m.total);
    final hechasSes = base.fold<int>(0, (a, m) => a + m.hechas);
    final pct = totalSes == 0 ? 0.0 : hechasSes / totalSes;
    final today = AppDateUtils.normalize(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titulo(focused, today, logrados, total),
        const SizedBox(height: 16),
        _rendimiento(pct, logrados, enProgreso, _verMes),
        const SizedBox(height: 16),
        _filtros(),
        if (_verMes && ocultosMes > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                '$ocultosMes completado${ocultosMes == 1 ? '' : 's'} este mes',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: metas.isEmpty
              ? _vacioModo()
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: metas.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final m = metas[i];
                    final registradoHoy =
                        hoyMap[m.hito.id] ?? false;
                    return HitoMetaCard(
                      hito: m.hito,
                      total: m.total,
                      hechas: m.hechas,
                      estado: m.estado,
                      subtitulo: m.subtitulo,
                      unidad: m.unidad,
                      ocurreHoy: m.hito.ocurreEl(today),
                      registradoHoy: registradoHoy,
                      busyRegistrar: _busyId == m.hito.id,
                      onRegistrar: () => _registrarHoy(m.hito),
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RegistrarHitoScreen(
                                inicial: m.hito)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _titulo(
      DateTime focused, DateTime today, int logrados, int total) {
    final enMes = _verMes;
    final lineaSup = enMes
        ? AppDateUtils.formatMonthYear(focused).toUpperCase()
        : 'HOY, ${today.day} DE ${_meses[today.month - 1].toUpperCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.secondary),
            const SizedBox(width: 6),
            Text(
              lineaSup,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              enMes ? 'Hitos del Mes' : 'Hitos del Día',
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              '$logrados de $total listos',
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Consolida tus hábitos diarios para alcanzar un mes perfecto.',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 14,
            height: 1.4,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _rendimiento(
      double pct, int logrados, int enProgreso, bool enMes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enMes ? 'RENDIMIENTO MENSUAL' : 'RENDIMIENTO DIARIO',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        color: AppColors.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: '${(pct * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
                          text: ' completado',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryContainer
                      .withValues(alpha: 0.4),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    size: 26, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.secondary),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.surfaceContainerLow),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dotRow(AppColors.secondary, '$logrados logrados'),
                _dotRow(AppColors.primaryContainer,
                    '$enProgreso en progreso'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dotRow(Color dot, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _filtros() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Metas en curso',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filtroPill('Día', !_verMes,
                  () => setState(() => _verMes = false)),
              _filtroPill('Mes', _verMes,
                  () => setState(() => _verMes = true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filtroPill(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active
                ? AppColors.onSurface
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _vacioModo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Center(
        child: Text(
          _verMes ? 'Sin hitos este mes.' : 'Nada programado para hoy.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('Error hitos: $e'),
    );
  }

  Future<void> _registrarHoy(Hito hito) async {
    final today = AppDateUtils.normalize(DateTime.now());
    setState(() => _busyId = hito.id);
    try {
      await ref.read(hitoActionsProvider).toggle(
          today, HitoAgendaItem(hito: hito, fecha: today, completadoDia: false));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Día registrado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}
