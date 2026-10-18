import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class RegistroSheet extends StatelessWidget {
  final DateTime date;
  final int? estadoActual;
  final void Function(int estado) onSelect;
  final VoidCallback? onDelete;

  /// Abre el listado de misiones del día (estilo Google Calendar).
  final VoidCallback? onVerMisiones;

  /// Si es false, "Lo Logré" sale deshabilitado (hitos de hoy incompletos).
  final bool puedeLograr;

  const RegistroSheet({
    super.key,
    required this.date,
    required this.estadoActual,
    required this.onSelect,
    this.onDelete,
    this.onVerMisiones,
    this.puedeLograr = true,
  });

  String _formatDate(DateTime d) {
    final fmt = DateFormat("d 'de' MMMM", 'es');
    final raw = fmt.format(d);
    if (raw.isEmpty) return raw;
    final parts = raw.split(' ');
    if (parts.length == 3) {
      parts[2] = parts[2][0].toUpperCase() + parts[2].substring(1);
      return parts.join(' ');
    }
    return raw[0].toUpperCase() + raw.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 48,
              height: 4,
              decoration:
                  BoxDecoration(color: AppColors.outlineVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 20),
          Text(_formatDate(date),
              style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
          const SizedBox(height: 6),
          const Text('¿Cómo te fue con tu hábito hoy?',
              style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant)),
          if (!puedeLograr) ...[
            const SizedBox(height: 8),
            const Text('Completa tus hitos de hoy al 100% para marcarlo como logrado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: puedeLograr
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onSelect(1);
                    }
                  : null,
              icon: const Icon(Icons.check_circle_rounded, size: 22),
              label: const Text('Lo Logré'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: AppColors.onSecondaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                textStyle: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                onSelect(0);
              },
              icon: const Icon(Icons.cancel_rounded, size: 22),
              label: const Text('Fallé'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorContainer,
                foregroundColor: AppColors.onErrorContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                textStyle: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (onVerMisiones != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  onVerMisiones!.call();
                },
                icon: const Icon(Icons.calendar_view_day_rounded, size: 22),
                label: const Text('Ver misiones del día'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
            ),
            child: const Text('CANCELAR'),
          ),
          if (estadoActual != null && onDelete != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                onDelete!.call();
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Eliminar registro'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error, textStyle: const TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showRegistroSheet(
  BuildContext context, {
  required DateTime date,
  required int? estadoActual,
  required void Function(int estado) onSelect,
  VoidCallback? onDelete,
  VoidCallback? onVerMisiones,
  bool puedeLograr = true,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.inverseSurface.withOpacity(0.5),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: RegistroSheet(
          date: date,
          estadoActual: estadoActual,
          onSelect: onSelect,
          onDelete: onDelete,
          onVerMisiones: onVerMisiones,
          puedeLograr: puedeLograr),
    ),
  );
}
