import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/hito.dart';

/// Tarjeta de meta mensual (diseño "Hitos del Mes"): barra de color de
/// prioridad, icono, título, chip de estado, barra fina de progreso
/// y botón "Realizado".
class HitoMetaCard extends StatelessWidget {
  final Hito hito;
  final int total;
  final int hechas;
  final HitoEstado estado;
  final String subtitulo;
  final String unidad;

  /// ¿El hito ocurre hoy? (si no, no se muestra "Realizado").
  final bool ocurreHoy;

  /// ¿Ya se registró hoy? (botón en estado "Registrado").
  final bool registradoHoy;
  final bool busyRegistrar;
  final VoidCallback? onRegistrar;
  final VoidCallback? onEdit;

  const HitoMetaCard({
    super.key,
    required this.hito,
    required this.total,
    required this.hechas,
    required this.estado,
    required this.subtitulo,
    this.unidad = 'sesiones',
    this.ocurreHoy = false,
    this.registradoHoy = false,
    this.busyRegistrar = false,
    this.onRegistrar,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final done = estado == HitoEstado.completado;
    final pct = total == 0 ? 0.0 : hechas / total;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Color de prioridad elegido al registrar el hito.
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: hito.colorValue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(11, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _iconBox(done),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hito.titulo,
                                    style: const TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(_subIcon(done),
                                          size: 13,
                                          color: _subColor()),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          subtitulo,
                                          style: const TextStyle(
                                            fontFamily: 'Hanken Grotesk',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _chip(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor:
                                AppColors.surfaceContainer,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              done
                                  ? AppColors.secondary
                                  : AppColors.primaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (done)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$hechas de $total $unidad',
                                style: const TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${(pct * 100).round()}%',
                                style: const TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 13,
                                    color:
                                        AppColors.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$hechas / $total',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    TextSpan(text: ' $unidad'),
                                  ],
                                ),
                              ),
                              if (ocurreHoy && !registradoHoy)
                                OutlinedButton.icon(
                                  onPressed: busyRegistrar
                                      ? null
                                      : onRegistrar,
                                  icon: busyRegistrar
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2),
                                        )
                                      : const Icon(Icons.check_rounded,
                                          size: 16,
                                          color: AppColors.secondary),
                                  label: const Text(
                                    'Realizado',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        AppColors.onSurface,
                                    side: const BorderSide(
                                        color: AppColors
                                            .surfaceContainerHigh),
                                    backgroundColor:
                                        AppColors.surfaceContainer,
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                              // Ya registrado hoy: el botón desaparece.
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBox(bool done) {
    final Color bg;
    final Color border;
    final Color fg;
    final IconData icon;
    if (done) {
      bg = AppColors.secondaryContainer.withValues(alpha: 0.5);
      border = AppColors.secondary.withValues(alpha: 0.2);
      fg = AppColors.secondary;
      icon = Icons.check_circle_rounded;
    } else if (estado == HitoEstado.vencido) {
      bg = AppColors.errorContainer.withValues(alpha: 0.5);
      border = AppColors.error.withValues(alpha: 0.2);
      fg = AppColors.error;
      icon = Icons.event_busy_rounded;
    } else {
      bg = AppColors.primaryFixed.withValues(alpha: 0.6);
      border = AppColors.primaryFixedDim.withValues(alpha: 0.4);
      fg = AppColors.primary;
      icon = _tipoIcon(hito.tipo);
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Icon(icon, size: 20, color: fg),
    );
  }

  IconData _tipoIcon(HitoTipo t) {
    switch (t) {
      case HitoTipo.diario:
        return Icons.today_rounded;
      case HitoTipo.mensual:
        return Icons.repeat_rounded;
      case HitoTipo.puntual:
        return Icons.event_rounded;
    }
  }

  IconData _subIcon(bool done) {
    if (done) return Icons.check_rounded;
    if (estado == HitoEstado.vencido) return Icons.error_outline_rounded;
    return Icons.schedule_rounded;
  }

  Color _subColor() {
    if (estado == HitoEstado.completado) return AppColors.secondary;
    if (estado == HitoEstado.vencido) return AppColors.error;
    return AppColors.onSurfaceVariant;
  }

  Widget _chip() {
    final Color bg;
    final Color fg;
    final String label;
    switch (estado) {
      case HitoEstado.completado:
        bg = AppColors.secondary.withValues(alpha: 0.10);
        fg = AppColors.secondary;
        label = 'Completado';
        break;
      case HitoEstado.vencido:
        bg = AppColors.error.withValues(alpha: 0.10);
        fg = AppColors.error;
        label = 'Vencido';
        break;
      case HitoEstado.pendiente:
        bg = AppColors.primaryFixed;
        fg = AppColors.primary;
        label = 'En curso';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
