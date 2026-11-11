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

class OwnerMainShell extends StatefulWidget {
  const OwnerMainShell({super.key});

  @override
  State<OwnerMainShell> createState() => _OwnerMainShellState();
}

class _OwnerMainShellState extends State<OwnerMainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PetListView(),
    AppointmentListView(),
    RecordListView(),
    ClinicTabView(),
    ProfileView(),
  ];

  void _refreshTab(int idx) {
    switch (idx) {
      case 0:
        context.read<PetViewModel>().fetchPets();
        break;
      case 1:
        context.read<AppointmentViewModel>().fetchAppointments();
        break;
      case 2:
        context.read<MedicalRecordViewModel>().fetchRecords();
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
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Hewan',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Medis',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital),
            label: 'Klinik',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
