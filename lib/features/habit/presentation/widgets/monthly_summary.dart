import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/habit_providers.dart';

class MonthlySummary extends ConsumerWidget {
  const MonthlySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenAsync = ref.watch(resumenMensualProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative chart line - subtle svg simulation via CustomPaint
          Positioned(
            bottom: 0,
            right: 0,
            child: Opacity(
              opacity: 0.08,
              child: CustomPaint(
                size: const Size(128, 64),
                painter: _ChartPainter(color: AppColors.secondary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: resumenAsync.when(
              loading: () => const SizedBox(height: 64, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => Text('Error resumen: $e'),
              data: (resumen) {
                final pct = resumen.porcentajeExito;
                final pctText = '${(pct * 100).round()}%';
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resumen Mensual',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('${resumen.exitos} Éxitos',
                                  style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                              const SizedBox(width: 8),
                              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.outlineVariant, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text('${resumen.fracasos} Fallos',
                                  style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Circular progress 48x48
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              value: resumen.total == 0 ? 0 : pct,
                              strokeWidth: 5,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            resumen.total == 0 ? '0%' : pctText,
                            style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Color color;
  _ChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.15, size.height * 0.55);
    path.lineTo(size.width * 0.35, size.height * 0.65);
    path.lineTo(size.width * 0.55, size.height * 0.25);
    path.lineTo(size.width * 0.75, size.height * 0.45);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
