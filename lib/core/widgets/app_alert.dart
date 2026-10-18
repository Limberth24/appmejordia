import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Widget _botonCancelar({
  required String label,
  required VoidCallback? onPressed,
}) {
  return Expanded(
    child: SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.surfaceContainer,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    ),
  );
}

Widget _botonSolido({
  required String label,
  required Color bg,
  required Color fg,
  required VoidCallback? onPressed,
}) {
  return Expanded(
    child: SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    ),
  );
}

Widget _cuerpo({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String message,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 48, color: iconColor),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 14,
          height: 1.4,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ],
  );
}

Future<void> showAppAlert({
  required BuildContext context,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String message,
  String okLabel = 'Entendido',
  Color okBg = AppColors.primary,
  Color okFg = Colors.white,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      content: _cuerpo(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
      ),
      actions: [
        Row(
          children: [
            _botonSolido(
              label: okLabel,
              bg: okBg,
              fg: okFg,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<bool> showAppConfirm({
  required BuildContext context,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String message,
  String cancelLabel = 'Cancelar',
  String confirmLabel = 'Eliminar',
  Color confirmBg = AppColors.error,
  Color confirmFg = Colors.white,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      content: _cuerpo(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
      ),
      actions: [
        Row(
          children: [
            _botonCancelar(
              label: cancelLabel,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            const SizedBox(width: 12),
            _botonSolido(
              label: confirmLabel,
              bg: confirmBg,
              fg: confirmFg,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ],
    ),
  );
  return res ?? false;
}
