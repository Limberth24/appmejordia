import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/hito.dart';
import '../providers/hito_providers.dart';
import '../sheets/hito_form_sheet.dart';
import 'hito_card.dart';

/// Vista de agenda diaria: hitos del día ordenados por hora con check.
class AgendaDiaria extends ConsumerStatefulWidget {
  const AgendaDiaria({super.key});

  @override
  ConsumerState<AgendaDiaria> createState() => _AgendaDiariaState();
}

class _AgendaDiariaState extends ConsumerState<AgendaDiaria> {
  int? _busyId;

  @override
  Widget build(BuildContext context) {
    final dia = ref.watch(agendaDayProvider);
    final agendaAsync = ref.watch(agendaDiaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dayStrip(dia),
        const SizedBox(height: 12),
        agendaAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => _errorBox(e.toString()),
          data: (items) {
            if (items.isEmpty) return _emptyBox(dia);
            final done = items.where((i) => i.completadoDia).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _progressCard(done, items.length),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return HitoCard(
                      item: item,
                      busy: _busyId == item.hito.id,
                      onToggle: () => _toggle(dia, item),
                      onEdit: () => showHitoFormSheet(context, inicial: item.hito),
                      onDelete: () => _confirmDelete(item.hito.id!),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _dayStrip(DateTime dia) {
    final today = AppDateUtils.normalize(DateTime.now());
    final days = List.generate(7, (i) => today.add(Duration(days: i - 3)));
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final d = days[i];
          final selected = AppDateUtils.isSameDay(d, dia);
          final isToday = AppDateUtils.isSameDay(d, today);
          return InkWell(
            onTap: () => ref.read(hitoActionsProvider).setDay(d),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppDateUtils.weekdaysShort[d.weekday - 1],
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.onSurface,
                    ),
                  ),
                  if (isToday)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Resumen visual del día: cuántos hitos van y barra de progreso.
  Widget _progressCard(int done, int total) {
    final pct = total == 0 ? 0.0 : done / total;
    final allDone = total > 0 && done == total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: allDone
            ? AppColors.secondary.withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDone
              ? AppColors.secondary.withValues(alpha: 0.35)
              : AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allDone
                    ? Icons.check_circle_rounded
                    : Icons.today_rounded,
                size: 20,
                color: allDone ? AppColors.secondary : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allDone ? '¡Día completado!' : '$done de $total hitos',
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(DateTime dia) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_task_rounded,
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
            'El ${AppDateUtils.formatFull(dia)} está libre.\nAgrega tu primer hito del día.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showHitoFormSheet(context, fechaInicial: dia),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar hito'),
            ),
          ),
        ],
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
      child: Text('Error agenda: $e'),
    );
  }

  Future<void> _toggle(DateTime dia, HitoAgendaItem item) async {
    setState(() => _busyId = item.hito.id);
    try {
      await ref.read(hitoActionsProvider).toggle(dia, item);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar hito?'),
        content: const Text('Se eliminará el hito y sus completados.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(hitoActionsProvider).eliminar(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hito eliminado')),
        );
      }
    }
  }
}
