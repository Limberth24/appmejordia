import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:appmejordia/features/habit/domain/entities/registro.dart';
import 'package:appmejordia/features/habit/presentation/providers/habit_providers.dart';
import 'package:appmejordia/features/hitos/domain/entities/hito.dart';
import 'package:appmejordia/features/hitos/presentation/providers/hito_providers.dart';
import 'package:appmejordia/features/hitos/presentation/widgets/hitos_historial.dart';
import 'package:appmejordia/features/habit/presentation/screens/dashboard_screen.dart';

Hito _hitoMensual(int id, String titulo) {
  final hoy = DateTime.now();
  return Hito(
    id: id,
    titulo: titulo,
    tipo: HitoTipo.mensual,
    fechaInicio: DateTime(hoy.year, hoy.month, 1),
    fechaFin: DateTime(hoy.year, hoy.month + 1, 0),
    horaInicio: '10:00',
    horaFin: '11:00',
    diasSemana: const {1, 2, 3, 4, 5, 6, 7},
    categoria: 'Salud',
    color: 0xFF1B6D24,
    createdAt: hoy,
    updatedAt: hoy,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('HitosHistorial pinta rango, stats y lista sin errores',
      (tester) async {
    final fakeMap = {
      '2026-10-05': [_hitoMensual(1, 'Gimnasio')],
      '2026-10-06': [_hitoMensual(1, 'Gimnasio'), _hitoMensual(2, 'Leer')],
    };
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realizadosRangoProvider.overrideWith(
            (ref) => Future.value(fakeMap),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HitosHistorial()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    Object? ex;
    var count = 0;
    do {
      ex = tester.takeException();
      if (ex != null) {
        count++;
        // ignore: avoid_print
        print('EXC $count: ${'$ex'.split('\n').take(8).join(' | ')}');
      }
    } while (ex != null && count < 10);
    expect(count, 0);
    expect(find.text('Hitos realizados'), findsOneWidget);
    expect(find.text('Realizados'), findsOneWidget);
    expect(find.text('Días activos'), findsOneWidget);
    // 3 realizados en 2 días.
    expect(find.text('3'), findsWidgets);
    expect(find.text('Gimnasio'), findsWidgets);
    expect(find.text('Leer'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 120)));

  testWidgets('Dashboard -> Historial no crashea (flujo del usuario)',
      (tester) async {
    final fakeMap = {
      '2026-10-06': [_hitoMensual(1, 'Gimnasio')],
    };
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          realizadosRangoProvider.overrideWith(
            (ref) => Future.value(fakeMap),
          ),
          resumenMensualProvider.overrideWith(
            (ref) => Future.value(
                const ResumenMensual(exitos: 5, fracasos: 1)),
          ),
          rachaProvider.overrideWith(
            (ref) => Future.value(const RachaInfo(
                actual: 5, mejorDelMes: 7, mejorHistorica: 12)),
          ),
          habitNameProvider.overrideWith(
            (ref) => Future.value('Mi Objetivo'),
          ),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    // Igual que el usuario: tocar la pestaña Historial.
    await tester.tap(find.text('Historial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Hitos realizados'), findsOneWidget);
    expect(find.textContaining('Historial'), findsWidgets);
  }, timeout: const Timeout(Duration(seconds: 180)));
}
