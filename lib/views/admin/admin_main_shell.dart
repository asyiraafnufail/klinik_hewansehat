import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/appointment_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/clinic_viewmodel.dart';
import '../../viewmodels/medical_record_viewmodel.dart';
import '../../viewmodels/pet_viewmodel.dart';
import '../appointments/appointment_list_view.dart';
import '../clinic/clinic_tab_view.dart';
import '../pets/pet_list_view.dart';
import '../records/record_list_view.dart';
import '../shared/profile_view.dart';

class AdminMainShell extends StatefulWidget {
  const AdminMainShell({super.key});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AppointmentListView(),
    RecordListView(),
    PetListView(),
    ClinicTabView(),
    ProfileView(),
  ];

  void _refreshTab(int idx) {
    switch (idx) {
      case 0:
        context.read<AppointmentViewModel>().fetchAppointments();
        break;
      case 1:
        context.read<MedicalRecordViewModel>().fetchRecords();
        break;
      case 2:
        context.read<PetViewModel>().fetchPets();
        break;
      case 3:
        context.read<ClinicViewModel>().fetchAll();
        break;
      case 4:
        context.read<AuthViewModel>().loadProfile();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SmoothIndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          _refreshTab(idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Medis',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Pasien',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_suggest_outlined),
            selectedIcon: Icon(Icons.settings_suggest),
            label: 'Klinik',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}
