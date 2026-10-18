import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/hito.dart';
import '../providers/hito_providers.dart';

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

/// Historial de hitos realizados en un rango: estadísticas + lista por día.
class HitosHistorial extends ConsumerWidget {
  const HitosHistorial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rango = ref.watch(rangoHistorialProvider);
    final dataAsync = ref.watch(realizadosRangoProvider);

    // El Expanded de la lista es hijo DIRECTO de esta Column acotada:
    // nunca anidar Expanded dentro de otra Column sin altura.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _headerCard(context, ref, rango, dataAsync),
        const SizedBox(height: 8),
        Expanded(
          child: dataAsync.when(
            loading: () => _listCard(
              const Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => _listCard(Center(child: Text('Error: $e'))),
            data: (map) => _listCard(_lista(map)),
          ),
        ),
      ],
    );
  }

  Widget _card(Widget child) {
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
      child: child,
    );
  }

  Widget _headerCard(
      BuildContext context,
      WidgetRef ref,
      ({DateTime ini, DateTime fin}) rango,
      AsyncValue<Map<String, List<Hito>>> dataAsync) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hitos realizados',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _rangoTile(
                      context, ref, 'Desde', rango.ini, true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _rangoTile(
                      context, ref, 'Hasta', rango.fin, false)),
            ],
          ),
          const SizedBox(height: 12),
          dataAsync.when(
            loading: () => const SizedBox(
                height: 52,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2))),
            error: (_, _) => const SizedBox.shrink(),
            data: (map) => _stats(rango, map),
          ),
        ],
      ),
    );
  }

  Widget _listCard(Widget child) => _card(child);

  Widget _rangoTile(BuildContext context, WidgetRef ref, String label,
      DateTime value, bool esIni) {
    return InkWell(
      onTap: () async {
        final rango = ref.read(rangoHistorialProvider);
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: AppDateUtils.normalize(DateTime.now()),
        );
        if (picked == null) return;
        final d = AppDateUtils.normalize(picked);
        var ini = esIni ? d : rango.ini;
        var fin = esIni ? rango.fin : d;
        if (fin.isBefore(ini)) {
          if (esIni) {
            fin = ini;
          } else {
            ini = fin;
          }
        }
        // Rango máximo de 62 días para listas manejables.
        if (fin.difference(ini).inDays > 61) {
          if (esIni) {
            fin = ini.add(const Duration(days: 61));
          } else {
            ini = fin.subtract(const Duration(days: 61));
          }
        }
        ref.read(rangoHistorialProvider.notifier).state =
            (ini: ini, fin: fin);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(
              _fechaCorta(value),
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _stats(
      ({DateTime ini, DateTime fin}) rango, Map<String, List<Hito>> map) {
    final dias = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final total = map.values.fold<int>(0, (a, l) => a + l.length);
    final diasRango = rango.fin.difference(rango.ini).inDays + 1;
    final pctDias = diasRango == 0
        ? 0
        : ((dias.length / diasRango) * 100).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
              child: _stat('Realizados', '$total', AppColors.secondary)),
          Container(
              width: 1,
              height: 32,
              color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Expanded(
              child: _stat(
                  'Días activos', '${dias.length}', AppColors.primary)),
          Container(
              width: 1,
              height: 32,
              color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Expanded(
              child: _stat('Días con logro', '$pctDias%',
                  AppColors.primary)),
        ],
      ),
    );
  }

  Widget _lista(Map<String, List<Hito>> map) {
    final dias = map.keys.toList()..sort((a, b) => b.compareTo(a));
    if (dias.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Sin hitos realizados en este rango.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: dias.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final iso = dias[i];
        final p = iso.split('-');
        final dia = DateTime(
            int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        final items = map[iso]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                AppDateUtils.formatFull(dia),
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            ...items.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _fila(h),
                )),
          ],
        );
      },
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 11,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }

  Widget _fila(Hito h) {
    final hi = h.horaInicio ?? '';
    final hf = h.horaFin ?? '';
    final hora =
        hi.isNotEmpty && hf.isNotEmpty ? '$hi–$hf' : null;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: h.colorValue, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.titulo,
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (hora != null)
                  Text(
                    hora,
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.secondary),
        ],
      ),
    );
  }
}
