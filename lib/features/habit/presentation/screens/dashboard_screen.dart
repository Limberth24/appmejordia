import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/registro.dart';
import '../../../hitos/presentation/providers/hito_providers.dart';
import '../../../hitos/presentation/screens/misiones_dia_screen.dart';
import '../../../hitos/presentation/screens/registrar_hito_screen.dart';
import '../../../hitos/presentation/widgets/hitos_historial.dart';
import '../../../hitos/presentation/widgets/hitos_mes_view.dart';
import '../providers/habit_providers.dart';
import '../sheets/registro_sheet.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/monthly_summary.dart';
import '../widgets/stitch_bottom_nav.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // La app abre en el nav de Mes (objetivo diario).
  int _navIndex = 1;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _handleDayTap(DateTime date, int? estado) async {
    if (AppDateUtils.isFuture(date)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('No puedes registrar días futuros'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    HapticFeedback.selectionClick();
    // "Lo Logré" solo si los hitos de hoy están al 100% (solo aplica a hoy).
    var puedeLograr = true;
    final esHoy = AppDateUtils.isSameDay(date, DateTime.now());
    if (esHoy) {
      try {
        final items = await ref.read(agendaHoyProvider.future);
        puedeLograr = items.every((e) => e.completadoDia);
      } catch (_) {
        puedeLograr = true;
      }
    }
    if (!mounted) return;
    showRegistroSheet(
      context,
      date: date,
      estadoActual: estado,
      puedeLograr: puedeLograr,
      onVerMisiones: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MisionesDiaScreen(fecha: date))),
      onSelect: (nuevoEstado) async {
        final iso = AppDateUtils.toIso(date);
        await ref.read(habitActionsProvider).upsert(iso, nuevoEstado);
        var extra = '';
        if (nuevoEstado == 0 && esHoy) {
          // Al fallar: los diarios pendientes pasan a mañana.
          final movidos =
              await ref.read(hitoActionsProvider).reprogramarPendientes(date);
          if (movidos > 0) {
            extra =
                ' • $movidos hito${movidos == 1 ? '' : 's'} pasado${movidos == 1 ? '' : 's'} a mañana';
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(nuevoEstado == 1 ? '¡Excelente! Día marcado como éxito' : 'Día marcado como fallado$extra'),
              backgroundColor: nuevoEstado == 1 ? AppColors.secondary : AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        }
      },
      onDelete: estado != null
          ? () async {
              final iso = AppDateUtils.toIso(date);
              await ref.read(habitActionsProvider).delete(iso);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Registro eliminado'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final rachaAsync = ref.watch(rachaProvider);
    final habitNameAsync = ref.watch(habitNameProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: AppColors.primaryContainer,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppColors.primaryContainer, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 1))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white)),
                  const SizedBox(width: 10),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('MejorDía', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, height: 1.1)),
                    Text('Beta', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Color(0xB3FFFFFF))),
                  ]),
                ]),
                Row(children: [
                  rachaAsync.when(
                    data: (racha) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
                        child: Row(children: [
                          const Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFFF635A)),
                          const SizedBox(width: 4),
                          Text('${racha.actual}', style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))
                        ])),
                    loading: () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
                        child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                    error: (_, _) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
                        child: const Row(children: [Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFFF635A)), SizedBox(width: 4), Text('0', style: TextStyle(color: Colors.white))])),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(width: 32, height: 32, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.settings_rounded, size: 18, color: Colors.white))),
                ]),
              ],
            ),
          ),
        ),
      ),
      body: _navIndex == 1
          ? _buildMesTab(focusedMonth, rachaAsync, habitNameAsync)
          : _navIndex == 2
              ? _buildHistoryTab()
              : const HitosMesView(),
      bottomNavigationBar: StitchBottomNav(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i)),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RegistrarHitoScreen())),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Registrar hito', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600)))
          : _navIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    final today = AppDateUtils.normalize(DateTime.now());
                    final registros = ref.read(registrosMesProvider).value;
                    final iso = AppDateUtils.toIso(today);
                    final estado = registros?[iso];
                    _handleDayTap(today, estado);
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Registrar hoy', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w600)))
              : null,
    );
  }

  Widget _buildMesTab(DateTime focusedMonth, AsyncValue<RachaInfo> rachaAsync, AsyncValue<String> habitNameAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _legacyHabitContent(focusedMonth, rachaAsync, habitNameAsync),
        ),
      ),
    );
  }

  /// Objetivo diario (vista Mes): se muestra tal cual, sin desplegable.
  Widget _legacyHabitContent(DateTime focusedMonth, AsyncValue<RachaInfo> rachaAsync, AsyncValue<String> habitNameAsync) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3))),
      child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(AppDateUtils.formatMonthYear(focusedMonth), style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  Row(children: [
                    _monthNavButton(icon: Icons.chevron_left_rounded, onTap: () => ref.read(habitActionsProvider).prevMonth()),
                    const SizedBox(width: 4),
                    _monthNavButton(icon: Icons.chevron_right_rounded, onTap: () => ref.read(habitActionsProvider).nextMonth()),
                  ]),
                ]),
                const SizedBox(height: 4),
                habitNameAsync.when(
                  data: (name) => Text('${_greeting()}${name.isEmpty ? '' : ' • $name'}',
                      style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant)),
                  loading: () => Text(_greeting(), style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 13, color: AppColors.onSurfaceVariant)),
                  error: (_, _) => Text(_greeting(), style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 13, color: AppColors.onSurfaceVariant)),
                ),
                const SizedBox(height: 12),
                rachaAsync.when(
                  data: (racha) => IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: _streakCard(label: 'Racha actual', value: racha.actual, icon: Icons.local_fire_department_rounded, color: AppColors.primary, subtitle: 'Hoy')),
                    const SizedBox(width: 12),
                    Expanded(child: _streakCard(label: 'Mejor racha', value: racha.mejorDelMes, icon: Icons.emoji_events_rounded, color: AppColors.secondary, subtitle: 'Histórica: ${racha.mejorHistorica}')),
                  ])),
                  loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (e, _) => Text('Error racha: $e'),
                ),
                const SizedBox(height: 12),
                CalendarGrid(onDayTap: _handleDayTap),
                const SizedBox(height: 12),
                Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                  _legendPill(color: AppColors.secondary, label: 'Éxito'),
                  _legendPill(color: AppColors.error, label: 'Fracaso'),
                  _legendPillOutline(label: 'Sin registrar'),
                ]),
                const SizedBox(height: 12),
                const MonthlySummary(),
              ],
            ),
          ),
    );
  }

  Widget _monthNavButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(width: 26, height: 26, decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: AppColors.onSurfaceVariant)));
  }

  Widget _streakCard({required String label, required int value, required IconData icon, required Color color, String? subtitle}) {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.12)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: color)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: color)),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$value', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 22, fontWeight: FontWeight.w700, height: 1, color: color)),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('días', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w500, color: color.withOpacity(0.9)))),
          ]),
          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant))],
        ]));
  }

  Widget _legendPill({required Color color, required String label}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColors.onSurfaceVariant)),
        ]));
  }

  Widget _legendPillOutline({required String label}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.surfaceContainerHighest.withOpacity(0.5), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle, border: Border.all(color: AppColors.outline.withOpacity(0.2)))),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColors.onSurfaceVariant)),
        ]));
  }

  Widget _buildHistoryTab() {
    final focused = ref.watch(focusedMonthProvider);
    final resumenAsync = ref.watch(resumenMensualProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Historial • ${AppDateUtils.formatMonthYear(focused)}', style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        const SizedBox(height: 12),
        resumenAsync.when(
          data: (r) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Éxitos', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)), Text('${r.exitos}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.secondary))])),
                Container(width: 1, height: 36, color: AppColors.outlineVariant.withOpacity(0.4)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Fallos', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)), Text('${r.fracasos}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.error))])),
                const SizedBox(width: 16),
                Container(width: 1, height: 36, color: AppColors.outlineVariant.withOpacity(0.4)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)), Text('${r.total}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary))])),
              ])),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
        const SizedBox(height: 16),
        const Expanded(child: HitosHistorial()),
        const SizedBox(height: 16),
      ]),
        ),
      ),
    );
  }

}
