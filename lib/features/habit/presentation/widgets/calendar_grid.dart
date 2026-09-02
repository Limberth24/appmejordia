import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../providers/habit_providers.dart';
import 'day_cell.dart';

class CalendarGrid extends ConsumerWidget {
  final void Function(DateTime date, int? estado) onDayTap;

  const CalendarGrid({super.key, required this.onDayTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final registrosAsync = ref.watch(registrosMesProvider);
    final today = AppDateUtils.normalize(DateTime.now());
    final focusDays = AppDateUtils.calendarDays(focusedMonth);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 2.2,
            children: List.generate(7, (i) {
              final label = AppDateUtils.weekdaysShort[i];
              final isSunday = i == 6;
              return Center(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        fontWeight: isSunday ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.5,
                        color: isSunday ? AppColors.primary : AppColors.onSurfaceVariant)),
              );
            }),
          ),
          const SizedBox(height: 8),
          registrosAsync.when(
            loading: () => const SizedBox(height: 280, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SizedBox(height: 280, child: Center(child: Text('Error: $e'))),
            data: (registros) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, childAspectRatio: 1, crossAxisSpacing: 4, mainAxisSpacing: 8),
                itemCount: 35,
                itemBuilder: (context, i) {
                  final date = focusDays[i];
                  final isPlaceholder = date.month != focusedMonth.month;
                  final isToday = AppDateUtils.isSameDay(date, today);
                  final iso = AppDateUtils.toIso(date);
                  final estado = registros[iso];
                  return DayCell(
                    date: date,
                    isCurrentMonth: !isPlaceholder,
                    isToday: isToday,
                    isPlaceholder: isPlaceholder,
                    estado: isPlaceholder ? null : estado,
                    onTap: isPlaceholder ? null : () => onDayTap(date, estado),
                  );
                },
              );
            },
          ),
          registrosAsync.when(
            data: (registros) {
              final last35 = focusDays[34];
              final daysInMonth = AppDateUtils.daysInMonth(focusedMonth.year, focusedMonth.month);
              final lastDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, daysInMonth);
              if (lastDayOfMonth.isAfter(last35)) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7, childAspectRatio: 1, crossAxisSpacing: 4, mainAxisSpacing: 8),
                    itemCount: 7,
                    itemBuilder: (context, i) {
                      final date = focusDays[35 + i];
                      final isPlaceholder = date.month != focusedMonth.month;
                      final isToday = AppDateUtils.isSameDay(date, today);
                      final iso = AppDateUtils.toIso(date);
                      final estado = registros[iso];
                      if (isPlaceholder) return const SizedBox();
                      return DayCell(
                          date: date,
                          isCurrentMonth: true,
                          isToday: isToday,
                          isPlaceholder: false,
                          estado: estado,
                          onTap: () => onDayTap(date, estado));
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
