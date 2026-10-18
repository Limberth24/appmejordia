import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/hito.dart';

class HitoCard extends StatelessWidget {
  final HitoAgendaItem item;
  final bool busy;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HitoCard({
    super.key,
    required this.item,
    this.busy = false,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hito = item.hito;
    final estado = item.estado;
    final done = estado == HitoEstado.completado;
    final vencido = estado == HitoEstado.vencido;
    final accent = hito.colorValue;

    final horaLabel = _horaLabel(hito);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        // La tarjeta entera registra: tocarla marca o desmarca el hito.
        onTap: busy ? null : onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: done ? AppColors.surfaceContainerLow : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : AppColors.outlineVariant.withValues(alpha: 0.35),
            ),
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
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: done ? AppColors.secondary : accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 0, 12),
                  child: Center(child: _toggleButton(done)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hito.titulo,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: done
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (horaLabel.isNotEmpty || hito.categoria != null) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (horaLabel.isNotEmpty)
                                _pill(Icons.schedule_rounded, horaLabel),
                              if (hito.categoria != null &&
                                  hito.categoria!.isNotEmpty)
                                _pill(Icons.label_rounded, hito.categoria!),
                              _pill(_tipoIcon(hito.tipo), hito.tipo.label),
                            ],
                          ),
                        ],
                        if (hito.descripcion != null &&
                            hito.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            hito.descripcion!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (vencido)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Vencido: ya pasó este día',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _estadoChip(estado),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            tooltip: 'Editar',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined,
                                size: 18,
                                color: AppColors.onSurfaceVariant),
                            onPressed: onEdit,
                          ),
                        if (onDelete != null)
                          IconButton(
                            tooltip: 'Eliminar',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.error),
                            onPressed: onDelete,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Botón grande y visible para marcar el hito (el gesto principal).
  Widget _toggleButton(bool done) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.secondary : Colors.transparent,
        border: Border.all(
          color: done ? AppColors.secondary : AppColors.outline,
          width: 2,
        ),
      ),
      child: busy
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: done ? Colors.white : AppColors.secondary,
              ),
            )
          : (done
              ? const Icon(Icons.check_rounded,
                  size: 18, color: Colors.white)
              : null),
    );
  }

  String _horaLabel(Hito h) {
    if (h.horaInicio != null &&
        h.horaInicio!.isNotEmpty &&
        h.horaFin != null &&
        h.horaFin!.isNotEmpty) {
      return '${h.horaInicio} - ${h.horaFin}';
    }
    if (h.horaInicio != null && h.horaInicio!.isNotEmpty) {
      return h.horaInicio!;
    }
    return '';
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

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoChip(HitoEstado estado) {
    Color bg;
    Color fg;
    switch (estado) {
      case HitoEstado.completado:
        bg = AppColors.secondary.withValues(alpha: 0.12);
        fg = AppColors.secondary;
        break;
      case HitoEstado.vencido:
        bg = AppColors.error.withValues(alpha: 0.10);
        fg = AppColors.error;
        break;
      case HitoEstado.pendiente:
        bg = AppColors.primary.withValues(alpha: 0.08);
        fg = AppColors.primary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        estado.label,
        style: TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
