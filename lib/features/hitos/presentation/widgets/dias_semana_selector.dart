import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

const _labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// Selector de días de semana para hitos recurrentes (1=Lun..7=Dom).
class DiasSemanaSelector extends StatelessWidget {
  final Set<int> seleccionados;
  final ValueChanged<Set<int>> onChanged;

  const DiasSemanaSelector({
    super.key,
    required this.seleccionados,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final day = i + 1;
        final active = seleccionados.contains(day);
        return InkWell(
          onTap: () {
            final next = Set<int>.from(seleccionados);
            if (active) {
              next.remove(day);
            } else {
              next.add(day);
            }
            onChanged(next);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              _labels[i],
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        );
      }),
    );
  }
}
