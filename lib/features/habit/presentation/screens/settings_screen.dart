import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/habit_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _controller;
  bool _initialized = false;
  final _formKey = GlobalKey<FormState>();
  bool _backupBusy = false;
  String? _lastBackupPath;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitNameAsync = ref.watch(habitNameProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Configuración', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            Text('Personaliza tu objetivo', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xB3FFFFFF))),
          ]),
          centerTitle: false,
        ),
      ),
      body: habitNameAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (name) {
          if (!_initialized) {
            _controller = TextEditingController(text: name);
            _initialized = true;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.verified_user_rounded, size: 20, color: AppColors.primary)),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Tu objetivo es único y privado. Todo se guarda solo en tu dispositivo.', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant, height: 1.4))),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Nombre de tu objetivo', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                    const SizedBox(height: 6),
                    const Text('Ej: Hacer ejercicio, No fumar, Meditar 10 min', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _controller,
                      maxLength: 40,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) {
                        if (v == null || v.trim().length < 2) return 'Mínimo 2 caracteres';
                        if (v.trim().length > 40) return 'Máximo 40 caracteres';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Ej: Mi Objetivo',
                        prefixIcon: const Icon(Icons.flag_rounded, color: AppColors.primary),
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          final newName = _controller.text.trim();
                          await ref.read(habitActionsProvider).setHabitName(newName);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Objetivo actualizado a "$newName"'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Guardar cambios', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurfaceVariant,
                            side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600)),
                        child: const Text('Cancelar'),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.25))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.backup_rounded, size: 18, color: AppColors.primary)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Respaldo', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                        Text('Guarda tu progreso antes de desinstalar', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _backupBusy ? null : _exportBackup,
                      icon: _backupBusy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.upload_rounded, size: 18),
                      label: Text(_backupBusy ? 'Procesando...' : 'Exportar copia a Descargas',
                          style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _backupBusy ? null : _importBackup,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Importar copia', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  if (_lastBackupPath != null) ...[
                    const SizedBox(height: 10),
                    Text('Última copia: $_lastBackupPath',
                        style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 8),
                  const Text('Si Android no permite guardar directo, se abrirá Compartir para que elijas Guardar en Descargas / Drive.',
                      style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant, height: 1.4)),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.25))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Información', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.storage_rounded, 'Almacenamiento local'),
                  _infoRow(Icons.offline_bolt_rounded, 'Funciona sin internet'),
                  _infoRow(Icons.lock_rounded, 'Privado, sin permisos extra'),
                ]),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('MejorDía v1.2.0 • MVP', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.outline, letterSpacing: 0.5))),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => _backupBusy = true);
    try {
      final result = await BackupService.exportBackup();
      if (!mounted) return;
      setState(() => _lastBackupPath = result.publicPath ?? result.tempPath);

      if (result.publicPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Copia guardada en:\n${result.publicPath}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Elige "Guardar en Descargas" o Drive en el menú Compartir.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        await BackupService.shareBackupFile(result.tempPath);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo exportar: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importBackup() async {
    try {
      final picked = await BackupService.pickBackupFile();
      if (picked == null || !mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restaurar respaldo?'),
          content: const Text('Se reemplazará tu progreso actual con la copia elegida.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;

      setState(() => _backupBusy = true);
      try {
        await BackupService.restoreBackup(picked);
        if (!mounted) return;
        // Refrescar toda la UI con los datos restaurados.
        ref.invalidate(habitNameProvider);
        ref.invalidate(registrosMesProvider);
        ref.invalidate(allRegistrosProvider);
        ref.invalidate(resumenMensualProvider);
        ref.invalidate(rachaProvider);
        setState(() => _initialized = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Respaldo restaurado correctamente.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No se pudo importar: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      } finally {
        if (mounted) setState(() => _backupBusy = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir el archivo: $e')));
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
        ]));
  }
}
