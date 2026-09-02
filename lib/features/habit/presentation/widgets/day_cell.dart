import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DayCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isPlaceholder;
  final int? estado;
  final VoidCallback? onTap;

  const DayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isPlaceholder,
    required this.estado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isPlaceholder) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox());
    }

    Widget circle;
    if (estado == 1) {
      circle = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      );
    } else if (estado == 0) {
      circle = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
      );
    } else {
      final isPlainNumber = estado == null && date.day == 1 && date.weekday != DateTime.monday;
      if (isPlainNumber) {
        return AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Center(
              child: Text(
                '${date.day}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant),
              ),
            ),
          ),
        );
      }
      final bool todayRing = isToday;
      if (todayRing) {
        return AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${date.day}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      circle = Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
        child: Center(
          child: Text('${date.day}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant, fontFamily: 'Hanken Grotesk')),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(999), child: Center(child: circle)),
    );
  }
}
