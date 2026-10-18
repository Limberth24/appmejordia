import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../domain/entities/hito.dart';
import '../providers/hito_providers.dart';

/// Pantalla para crear o editar un hito (no modal, con retroceso).
/// Usa el mismo lenguaje visual de "registrar hoy": título grande,
/// subtítulo y botones píldora de 56px.
class RegistrarHitoScreen extends ConsumerStatefulWidget {
  final Hito? inicial;
  final DateTime? fechaInicial;

  const RegistrarHitoScreen({super.key, this.inicial, this.fechaInicial});

  @override
  ConsumerState<RegistrarHitoScreen> createState() =>
      _RegistrarHitoScreenState();
}

class _RegistrarHitoScreenState extends ConsumerState<RegistrarHitoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titulo;
  late TextEditingController _descripcion;
  late HitoTipo _tipo;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  String? _categoria;
  int? _color;
  bool _saving = false;
  String? _conflictoMsg;

  bool get isEdit => widget.inicial != null;

  /// Foco fantasma (sin teclado): al abrir un picker el foco va aquí,
  /// así al cerrarse no se restaura al campo anterior ni parpadea el teclado.
  final _dummyFocus = FocusNode(skipTraversal: true);

  /// Suelta el foco ahora y al terminar el frame: al cerrar un picker,
  /// Flutter devuelve el foco al campo donde estaba (ej. descripción);
  /// el post-frame lo limpia para que no quede en ningún campo.
  void _soltarFoco() {
    FocusScope.of(context).requestFocus(_dummyFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (FocusManager.instance.primaryFocus != _dummyFocus) {
        FocusScope.of(context).requestFocus(_dummyFocus);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final ini = widget.inicial;
    final base =
        AppDateUtils.normalize(widget.fechaInicial ?? DateTime.now());
    _titulo = TextEditingController(text: ini?.titulo ?? '');
    _descripcion = TextEditingController(text: ini?.descripcion ?? '');
    _tipo = ini?.tipo ?? HitoTipo.diario;
    _fechaInicio =
        ini != null ? AppDateUtils.normalize(ini.fechaInicio) : base;
    _fechaFin = ini != null ? AppDateUtils.normalize(ini.fechaFin) : base;
    _horaInicio = _parseTOD(ini?.horaInicio);
    _horaFin = _parseTOD(ini?.horaFin);
    _categoria = ini?.categoria;
    _color = ini?.color ?? hitoColores.first;
    _checkConflicto();
  }

  TimeOfDay? _parseTOD(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final p = hhmm.split(':');
    if (p.length != 2) return null;
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String? _todToHhmm(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _dummyFocus.dispose();
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _checkConflicto() async {
    if (_horaInicio == null || _horaFin == null) {
      if (mounted) setState(() => _conflictoMsg = null);
      return;
    }
    try {
      final lista = await ref
          .read(hitoRepositoryProvider)
          .conflictosHito(_candidato(), excluirId: widget.inicial?.id);
      if (!mounted) return;
      setState(() {
        _conflictoMsg = lista.isEmpty
            ? null
            : 'Choca con "${lista.first.titulo}" '
                '(${lista.first.horaInicio}-${lista.first.horaFin})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _conflictoMsg = null);
    }
  }

  /// Hito con los datos actuales del formulario (para validar choques).
  Hito _candidato() {
    final now = DateTime.now();
    return Hito(
      id: widget.inicial?.id,
      titulo:
          _titulo.text.trim().isEmpty ? 'Sin título' : _titulo.text.trim(),
      tipo: _tipo,
      fechaInicio: _fechaInicio,
      fechaFin: _tipo == HitoTipo.mensual ? _fechaFin : _fechaInicio,
      horaInicio: _todToHhmm(_horaInicio),
      horaFin: _todToHhmm(_horaFin),
      // El mensual vale para todos los días del rango (sin selector).
      diasSemana:
          _tipo == HitoTipo.mensual ? const {1, 2, 3, 4, 5, 6, 7} : {},
      createdAt: widget.inicial?.createdAt ?? now,
      updatedAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(
          isEdit ? 'Editar hito' : 'Registrar hito',
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEdit
                        ? 'Ajusta los datos de tu hito'
                        : '¿Qué quieres lograr?',
                    style: const TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Elige el tipo y completa los datos. Puedes editarlo cuando quieras.',
                    style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _tipoTile(HitoTipo.diario,
                              Icons.today_rounded, 'Diario', 'Un día')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _tipoTile(HitoTipo.mensual,
                              Icons.repeat_rounded, 'Mensual', 'Todo el mes')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _tipoTile(HitoTipo.puntual,
                              Icons.event_rounded, 'Agenda', 'Ej: reunión')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titulo,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) {
                      if (v == null || v.trim().length < 2) {
                        return 'Mínimo 2 caracteres';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ej: Correr 30 min',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextFormField(
                    controller: _descripcion,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _fechaTile(
                        _tipo == HitoTipo.mensual ? 'Inicio' : 'Fecha',
                        _fechaInicio,
                        (d) {
                          setState(() {
                            _fechaInicio = d;
                            if (_tipo != HitoTipo.mensual) _fechaFin = d;
                          });
                        },
                        editable: _tipo != HitoTipo.diario,
                      )),
                      const SizedBox(width: 8),
                      if (_tipo == HitoTipo.mensual)
                        Expanded(child: _fechaTile('Fin', _fechaFin, (d) {
                          setState(() => _fechaFin = d);
                        })),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _horaTile(
                              'Hora inicio${_tipo == HitoTipo.puntual ? ' *' : ''}',
                              _horaInicio, (t) {
                        setState(() => _horaInicio = t);
                        _checkConflicto();
                      })),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _horaTile(
                              'Hora fin${_tipo == HitoTipo.puntual ? ' *' : ''}',
                              _horaFin, (t) {
                        setState(() => _horaFin = t);
                        _checkConflicto();
                      })),
                    ],
                  ),
                  if (_conflictoMsg != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _conflictoMsg!,
                              style: const TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoria,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: hitoCategorias
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _categoria = v),
                  ),
                  const SizedBox(height: 12),
                  const Text('Color de prioridad',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  const Text('Se muestra en tus metas en curso.',
                      style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: hitoColores.map((c) {
                      final sel = _color == c;
                      return InkWell(
                        onTap: () => setState(() => _color = c),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sel ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: sel
                              ? const Icon(Icons.check_rounded,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _guardar,
                      icon: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onSecondaryContainer))
                          : const Icon(Icons.check_circle_rounded, size: 22),
                      label: Text(isEdit ? 'Guardar cambios' : 'Crear hito'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryContainer,
                        foregroundColor: AppColors.onSecondaryContainer,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      textStyle: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5),
                    ),
                    child: const Text('CANCELAR'),
                  ),
                  if (isEdit && widget.inicial?.id != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _eliminar,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18),
                        label: const Text('Eliminar hito'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side:
                              const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Selector de tipo en cuadraditos (no píldoras).
  Widget _tipoTile(HitoTipo t, IconData icon, String label, String desc) {
    final sel = _tipo == t;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        if (_tipo == t) return;
        _soltarFoco();
        setState(() {
          _tipo = t;
          if (t == HitoTipo.diario && widget.inicial == null) {
            // El diario es espontáneo: siempre es el mismo día (hoy).
            final hoy = AppDateUtils.normalize(DateTime.now());
            _fechaInicio = hoy;
            _fechaFin = hoy;
          }
          if (t != HitoTipo.mensual) {
            _fechaFin = _fechaInicio;
          }
        });
        _checkConflicto();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.outlineVariant,
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 24,
                color: sel ? Colors.white : AppColors.primary),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.onSurface)),
            Text(desc,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 10,
                    color: sel
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _fechaTile(String label, DateTime value,
      ValueChanged<DateTime> onPick,
      {bool editable = true}) {
    return InkWell(
      canRequestFocus: false,
      onTap: editable
          ? () async {
              // Suelta el foco para que al cerrar el picker el teclado
              // no salte a otro campo (ej. descripción).
              _soltarFoco();
              final picked = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              _soltarFoco();
              if (picked != null) {
                onPick(AppDateUtils.normalize(picked));
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: editable ? null : AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant)),
                ),
                if (!editable)
                  const Icon(Icons.lock_outline_rounded,
                      size: 12, color: AppColors.onSurfaceVariant),
              ],
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(value),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: editable
                      ? AppColors.onSurface
                      : AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _horaTile(
      String label, TimeOfDay? value,       ValueChanged<TimeOfDay?> onPick) {
    return InkWell(
      canRequestFocus: false,
      onTap: () async {
        _soltarFoco();
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        _soltarFoco();
        onPick(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.onSurfaceVariant)),
            Text(
              value == null ? '--:--' : value.format(context),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipo == HitoTipo.puntual &&
        (_horaInicio == null || _horaFin == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Un hito puntual necesita hora de inicio y fin')));
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final hito = Hito(
        id: widget.inicial?.id,
        titulo: _titulo.text.trim(),
        descripcion: _descripcion.text.trim().isEmpty
            ? null
            : _descripcion.text.trim(),
        tipo: _tipo,
        fechaInicio: _fechaInicio,
        fechaFin: _tipo == HitoTipo.mensual ? _fechaFin : _fechaInicio,
        horaInicio: _todToHhmm(_horaInicio),
        horaFin: _todToHhmm(_horaFin),
        // El mensual vale para todos los días del rango (sin selector).
        diasSemana:
            _tipo == HitoTipo.mensual ? const {1, 2, 3, 4, 5, 6, 7} : {},
        completado: widget.inicial?.completado ?? false,
        fechaCompletado: widget.inicial?.fechaCompletado,
        categoria: _categoria,
        color: _color,
        createdAt: widget.inicial?.createdAt ?? now,
        updatedAt: now,
      );
      // Ningún horario puede chocar con otro (diario, mensual o agenda).
      if (_tieneHoras(hito)) {
        final choques = await ref
            .read(hitoRepositoryProvider)
            .conflictosHito(hito, excluirId: hito.id);
        if (choques.isNotEmpty) {
          if (mounted) setState(() => _saving = false);
          await _dialogoChoque(choques);
          return;
        }
      }
      final actions = ref.read(hitoActionsProvider);
      if (isEdit) {
        await actions.actualizar(hito);
      } else {
        await actions.crear(hito);
      }
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEdit ? 'Hito actualizado' : 'Hito creado')));
    } on StateError catch (e) {
      // Respaldo de la capa de datos ante choques de horario.
      if (mounted) setState(() => _saving = false);
      await _dialogoChoqueMsg(e.message);
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _tieneHoras(Hito h) =>
      (h.horaInicio ?? '').isNotEmpty && (h.horaFin ?? '').isNotEmpty;

  /// Elimina el hito desde la pantalla de edición (con confirmación).
  Future<void> _eliminar() async {
    final id = widget.inicial?.id;
    if (id == null) return;
    final ok = await showAppConfirm(
      context: context,
      icon: Icons.warning_rounded,
      iconColor: AppColors.error,
      title: 'Eliminar hito?',
      message:
          'Se eliminará el hito y todos sus días registrados. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      confirmBg: AppColors.error,
      confirmFg: Colors.white,
    );
    if (ok != true || !mounted) return;
    await ref.read(hitoActionsProvider).eliminar(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hito eliminado')),
    );
    Navigator.pop(context);
  }

  /// Modal de validación: ningún horario puede solaparse con otro.
  Future<void> _dialogoChoque(List<Hito> choques) {    final detalle = choques
        .take(3)
        .map((h) => '• "${h.titulo}" (${h.horaInicio}–${h.horaFin})')
        .join('\n');
    return _dialogoChoqueMsg(
        'Ningún horario puede chocar con otro.\n\n$detalle\n\nCambia la hora o la fecha.');
  }

  Future<void> _dialogoChoqueMsg(String msg) {
    return showAppAlert(
      context: context,
      icon: Icons.warning_rounded,
      iconColor: AppColors.error,
      title: 'Horario ocupado',
      message: msg,
      okLabel: 'Entendido',
      okBg: AppColors.error,
      okFg: Colors.white,
    );
  }
}
