import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/habit_providers.dart';

class StreakHeader extends ConsumerWidget {
  const StreakHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitNameAsync = ref.watch(habitNameProvider);
    final rachaAsync = ref.watch(rachaProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          habitNameAsync.when(
            data: (name) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag_rounded, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Objetivo actual',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0.8)),
                      const SizedBox(height: 2),
                      Text(name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16, height: 1.2)),
                    ],
                  ),
                ),
                _greetingChip(),
              ],
            ),
            loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, _) => const Text('Mi Objetivo'),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          rachaAsync.when(
            data: (racha) => Row(
              children: [
                Expanded(child: _streakCard(context, 'Racha actual', racha.actual, Icons.local_fire_department, AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _streakCard(context, 'Mejor racha', racha.mejorDelMes, Icons.emoji_events_rounded, AppColors.secondary, subtitle: 'Histórica: ${racha.mejorHistorica}')),
              ],
            ),
            loading: () => const SizedBox(height: 84, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Text('Error racha: $e'),
          ),
        ],
      ),
    );
  }

  Widget _greetingChip() {
    final hour = DateTime.now().hour;
    String greet = 'Buenos días';
    if (hour >= 12 && hour < 19) greet = 'Buenas tardes';
    if (hour >= 19) greet = 'Buenas noches';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_rounded, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(greet, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _streakCard(BuildContext context, String label, int value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$value',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, height: 1, color: color)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('días', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
          ]
        ],
      ),
    );
  }
}
