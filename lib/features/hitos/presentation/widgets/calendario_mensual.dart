import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../habit/presentation/providers/habit_providers.dart';
import '../../domain/entities/hito.dart';
import '../providers/hito_providers.dart';

/// Calendario mensual de hitos: puntos por día + progreso "12/15 sesiones".
class CalendarioMensual extends ConsumerWidget {
  final void Function(DateTime dia)? onDayTap;

  const CalendarioMensual({super.key, this.onDayTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = ref.watch(focusedMonthProvider);
    final agendaAsync = ref.watch(agendaMesProvider);
    final progresosAsync = ref.watch(progresosMensualesProvider);
    final selected = ref.watch(agendaDayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
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
                  Text(
                    AppDateUtils.formatMonthYear(focused),
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      _navBtn(context, ref, -1),
                      const SizedBox(width: 4),
                      _navBtn(context, ref, 1),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                childAspectRatio: 2.2,
                children: List.generate(
                  7,
                  (i) {
                    final isSunday = i == 6;
                    return Center(
                      child: Text(
                        AppDateUtils.weekdaysShort[i],
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 11,
                          fontWeight:
                              isSunday ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: 0.5,
                          color: isSunday
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              agendaAsync.when(
                loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Error: $e'),
                data: (map) => _grid(context, ref, focused, map, selected),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        progresosAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (lista) {
            if (lista.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progreso mensual recurrente',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...lista.map((e) => _progresoRow(e.hito, e.progreso)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _navBtn(BuildContext context, WidgetRef ref, int delta) {
    return InkWell(
      onTap: () {
        final cur = ref.read(focusedMonthProvider);
        ref.read(habitActionsProvider).setMonth(
            DateTime(cur.year, cur.month + delta, 1));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          delta < 0 ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          size: 18,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _grid(
    BuildContext context,
    WidgetRef ref,
    DateTime focused,
    Map<String, List<HitoAgendaItem>> map,
    DateTime selected,
  ) {
    final days = AppDateUtils.calendarDays(focused);
    final today = AppDateUtils.normalize(DateTime.now());
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 8,
      ),
      itemCount: 42,
      itemBuilder: (ctx, i) {
        final d = days[i];
        final inMonth = d.month == focused.month;
        if (!inMonth) return const AspectRatio(aspectRatio: 1, child: SizedBox());
        final iso =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final items = map[iso] ?? const <HitoAgendaItem>[];
        final done = items.where((e) => e.completadoDia).length;
        final hasItems = items.isNotEmpty;
        final allDone = hasItems && done == items.length;
        final isSel = AppDateUtils.isSameDay(d, selected);
        final isToday = AppDateUtils.isSameDay(d, today);

        // Estilo del calendario anterior (círculos): seleccionado = primario,
        // día completado = verde, resto = gris, hoy = anillo primario.
        Widget circle = Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSel
                ? AppColors.primary
                : (allDone
                    ? AppColors.secondary
                    : AppColors.surfaceVariant),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${d.day}',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12,
                fontWeight: (isSel || allDone)
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: (isSel || allDone)
                    ? Colors.white
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        );

        if (isToday && !isSel && !allDone) {
          circle = Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${d.day}',
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }

        return AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            onTap: () {
              ref.read(hitoActionsProvider).setDay(d);
              if (onDayTap != null) onDayTap!(d);
            },
            borderRadius: BorderRadius.circular(999),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  circle,
                  if (hasItems)
                    Positioned(
                      right: -3,
                      bottom: 1,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.white
                              : (allDone
                                  ? Colors.white
                                  : AppColors.primary),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.12),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${items.length}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSel
                                  ? AppColors.primary
                                  : (allDone
                                      ? AppColors.secondary
                                      : Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _progresoRow(Hito hito, HitoProgreso p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: hito.colorValue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hito.titulo,
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Text(
                p.labelCorta,
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p.proporcion,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          Text(
            p.label,
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
