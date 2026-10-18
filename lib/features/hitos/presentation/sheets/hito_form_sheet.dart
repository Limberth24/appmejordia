import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/hito.dart';
import '../providers/hito_providers.dart';
import '../widgets/dias_semana_selector.dart';

Future<void> showHitoFormSheet(
  BuildContext context, {
  Hito? inicial,
  DateTime? fechaInicial,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _HitoForm(inicial: inicial, fechaInicial: fechaInicial),
    ),
  );
}

class _HitoForm extends ConsumerStatefulWidget {
  final Hito? inicial;
  final DateTime? fechaInicial;
  const _HitoForm({this.inicial, this.fechaInicial});

  @override
  ConsumerState<_HitoForm> createState() => _HitoFormState();
}

class _HitoFormState extends ConsumerState<_HitoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titulo;
  late TextEditingController _descripcion;
  late HitoTipo _tipo;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  Set<int> _dias = {};
  String? _categoria;
  int? _color;
  int? _recordatorio;
  bool _saving = false;
  String? _conflictoMsg;

  bool get isEdit => widget.inicial != null;

  @override
  void initState() {
    super.initState();
    final ini = widget.inicial;
    final base =
        AppDateUtils.normalize(widget.fechaInicial ?? DateTime.now());
    _titulo = TextEditingController(text: ini?.titulo ?? '');
    _descripcion = TextEditingController(text: ini?.descripcion ?? '');
    _tipo = ini?.tipo ?? HitoTipo.diario;
    _fechaInicio = ini != null
        ? AppDateUtils.normalize(ini.fechaInicio)
        : base;
    _fechaFin = ini != null ? AppDateUtils.normalize(ini.fechaFin) : base;
    _horaInicio = _parseTOD(ini?.horaInicio);
    _horaFin = _parseTOD(ini?.horaFin);
    _dias = Set<int>.from(ini?.diasSemana ?? {base.weekday});
    _categoria = ini?.categoria;
    _color = ini?.color ?? hitoColores.first;
    _recordatorio = ini?.recordatorioMin;
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
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _checkConflicto() async {
    if (_tipo != HitoTipo.puntual ||
        _horaInicio == null ||
        _horaFin == null) {
      setState(() => _conflictoMsg = null);
      return;
    }
    try {
      final lista = await ref.read(hitoRepositoryProvider).conflictos(
            fecha: _fechaInicio,
            horaInicio: _todToHhmm(_horaInicio)!,
            horaFin: _todToHhmm(_horaFin)!,
            excluirId: widget.inicial?.id,
          );
      setState(() {
        _conflictoMsg = lista.isEmpty
            ? null
            : 'Conflicto con "${lista.first.titulo}" '
                '(${lista.first.horaInicio}-${lista.first.horaFin})';
      });
    } catch (_) {
      setState(() => _conflictoMsg = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 640),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isEdit ? 'Editar hito' : 'Nuevo hito',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<HitoTipo>(
                segments: const [
                  ButtonSegment(
                      value: HitoTipo.diario,
                      label: Text('Diario'),
                      icon: Icon(Icons.today_rounded, size: 16)),
                  ButtonSegment(
                      value: HitoTipo.mensual,
                      label: Text('Mensual'),
                      icon: Icon(Icons.repeat_rounded, size: 16)),
                  ButtonSegment(
                      value: HitoTipo.puntual,
                      label: Text('Puntual'),
                      icon: Icon(Icons.event_rounded, size: 16)),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) {
                  setState(() => _tipo = s.first);
                  _checkConflicto();
                },
              ),
              const SizedBox(height: 12),
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
                  Expanded(child: _fechaTile('Inicio', _fechaInicio, (d) {
                    setState(() {
                      _fechaInicio = d;
                      if (_tipo != HitoTipo.mensual) _fechaFin = d;
                    });
                  })),
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
                      child: _horaTile('Hora inicio${_tipo == HitoTipo.puntual ? ' *' : ''}',
                          _horaInicio, (t) {
                    setState(() => _horaInicio = t);
                    _checkConflicto();
                  })),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _horaTile('Hora fin${_tipo == HitoTipo.puntual ? ' *' : ''}',
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
              if (_tipo == HitoTipo.mensual) ...[
                const SizedBox(height: 12),
                const Text('Días de la semana *',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DiasSemanaSelector(
                  seleccionados: _dias,
                  onChanged: (s) => setState(() => _dias = s),
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
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v),
              ),
              const SizedBox(height: 12),
              const Text('Color',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _recordatorio,
                decoration: const InputDecoration(
                  labelText: 'Recordatorio',
                  border: OutlineInputBorder(),
                ),
                items: hitoRecordatorios
                    .map((m) => DropdownMenuItem<int?>(
                        value: m, child: Text(recordatorioLabel(m))))
                    .toList(),
                onChanged: (v) => setState(() => _recordatorio = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _guardar,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded),
                  label: Text(isEdit ? 'Guardar cambios' : 'Crear hito'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fechaTile(String label, DateTime value, ValueChanged<DateTime> onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) {
          onPick(AppDateUtils.normalize(picked));
        }
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
              DateFormat('dd/MM/yyyy').format(value),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _horaTile(
      String label, TimeOfDay? value, ValueChanged<TimeOfDay?> onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
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
    if (_tipo == HitoTipo.mensual && _dias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Elige al menos un día de la semana')));
      return;
    }
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
        descripcion:
            _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
        tipo: _tipo,
        fechaInicio: _fechaInicio,
        fechaFin: _tipo == HitoTipo.mensual ? _fechaFin : _fechaInicio,
        horaInicio: _todToHhmm(_horaInicio),
        horaFin: _todToHhmm(_horaFin),
        diasSemana: _tipo == HitoTipo.mensual ? _dias : {},
        completado: widget.inicial?.completado ?? false,
        fechaCompletado: widget.inicial?.fechaCompletado,
        categoria: _categoria,
        color: _color,
        recordatorioMin: _recordatorio,
        createdAt: widget.inicial?.createdAt ?? now,
        updatedAt: now,
      );
      final actions = ref.read(hitoActionsProvider);
      if (isEdit) {
        await actions.actualizar(hito);
      } else {
        await actions.crear(hito);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEdit ? 'Hito actualizado' : 'Hito creado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
