import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_hewansehat/core/theme/app_theme.dart';
import 'package:klinik_hewansehat/data/models/appointment_model.dart';
import 'package:klinik_hewansehat/data/repositories/appointment_repository.dart';
import 'package:klinik_hewansehat/main.dart';
import 'package:klinik_hewansehat/viewmodels/appointment_viewmodel.dart';
import 'package:klinik_hewansehat/viewmodels/auth_viewmodel.dart';
import 'package:klinik_hewansehat/views/auth/login_view.dart';
import 'package:provider/provider.dart';

class _FakeAppointmentRepo extends AppointmentRepository {
  @override
  Future<List<AppointmentModel>> fetchAppointments({
    String search = '',
    AppointmentStatus? statusFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return [
      AppointmentModel(
        id: '1',
        petId: 'p1',
        ownerId: 'o1',
        vetId: null,
        serviceId: null,
        appointmentDate: DateTime(2026, 4, 1),
        appointmentTime: '09:00',
        status: statusFilter ?? AppointmentStatus.pending,
        reason: 'Cek rutin',
      ),
    ];
  }
}

void main() {
  testWidgets('App renders setup screen when Supabase not configured', (WidgetTester tester) async {
    await tester.pumpWidget(const KlinikApp(isConfigured: false));
    await tester.pumpAndSettle();

    expect(find.text('Konfigurasi Supabase Diperlukan'), findsOneWidget);
    expect(find.text('Klinik Hewan Sehat'), findsOneWidget);
    expect(find.textContaining('supabase_config.dart'), findsWidgets);
  });

  testWidgets('LoginView renders symmetrically on narrow phone size without overflow', (WidgetTester tester) async {
    final authVM = AuthViewModel(listenAuth: false);

    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: authVM,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Klinik Hewan Sehat'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FadeSlideIn and BouncyTap render and animate without errors', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: FadeSlideIn(
            index: 0,
            child: BouncyTap(
              onTap: () => tapped = true,
              child: const Text('Halo Hewan'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halo Hewan'), findsOneWidget);
    await tester.tap(find.text('Halo Hewan'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('Shared glass primitives render and transition cleanly', (WidgetTester tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    int currentTab = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: GlassBackground(
              child: Column(
                children: [
                  GlassSearchBar(
                    controller: controller,
                    hintText: 'Cari...',
                    onChanged: (_) {},
                    onClear: controller.clear,
                  ),
                  const StatusPillBadge(
                    label: 'Aktif',
                    textColor: AppTheme.primaryDark,
                    bgColor: AppTheme.primarySoft,
                    borderColor: Color(0xFF99F6E4),
                  ),
                  Expanded(
                    child: SmoothIndexedStack(
                      index: currentTab,
                      children: const [
                        GlassEmptyState(icon: Icons.pets_rounded, title: 'Tab 1'),
                        Center(child: Text('Tab 2')),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => currentTab = 1),
                    child: const Text('Switch'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tab 1'), findsOneWidget);
    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();
    expect(find.text('Tab 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GlassSkeletonList renders and pulses without overflow or errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: GlassSkeletonList(itemCount: 3),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GlassSkeletonCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  test('AppointmentViewModel clears stale data immediately on setFilter', () async {
    final vm = AppointmentViewModel(repo: _FakeAppointmentRepo());
    await vm.fetchAppointments();
    expect(vm.appointments, hasLength(1));

    vm.setFilter(AppointmentStatus.confirmed);
    // Data sebelumnya langsung dikosongkan dan loading aktif agar skeleton tampil
    expect(vm.appointments, isEmpty);
    expect(vm.isLoading, isTrue);

    await Future.delayed(const Duration(milliseconds: 50));
    expect(vm.isLoading, isFalse);
    expect(vm.appointments, hasLength(1));
    expect(vm.appointments.first.status, AppointmentStatus.confirmed);
  });
}
