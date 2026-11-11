import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../views/admin/admin_main_shell.dart';
import '../../views/appointments/appointment_form_view.dart';
import '../../views/auth/login_view.dart';
import '../../views/auth/register_view.dart';
import '../../views/clinic/service_form_view.dart';
import '../../views/clinic/vet_form_view.dart';
import '../../views/owner/owner_main_shell.dart';
import '../../views/pets/pet_detail_view.dart';
import '../../views/pets/pet_form_view.dart';
import '../../views/records/record_detail_view.dart';
import '../../views/records/record_form_view.dart';
import '../../views/shared/local_file_viewer_view.dart';
import '../../views/shared/local_files_view.dart';
import '../../data/models/appointment_model.dart';
import '../../data/models/medical_record_model.dart';
import '../../data/models/pet_model.dart';
import '../../data/models/service_model.dart';
import '../../data/models/veterinarian_model.dart';

class AppRouter {
  static GoRouter createRouter(AuthViewModel authVM) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authVM,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final isAuth = authVM.isAuthenticated;
        final onAuthPage = loc == '/login' || loc == '/register';

        if (!isAuth) {
          return onAuthPage ? null : '/login';
        }

        // Tunggu profil termuat dari Supabase sebelum mengarahkan dashboard role
        if (authVM.profile == null && authVM.isLoading) {
          return null;
        }

        // Sudah login tapi masih di halaman login/register atau root
        if (onAuthPage || loc == '/') {
          return authVM.isAdmin ? '/admin' : '/owner';
        }

        // Sinkronkan rute saat role admin/pet_owner berubah atau dicegah cross-role
        if (loc.startsWith('/admin') && !authVM.isAdmin) {
          return '/owner';
        }
        if (loc.startsWith('/owner') && authVM.isAdmin) {
          return '/admin';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterView(),
        ),
        GoRoute(
          path: '/owner',
          builder: (context, state) => const OwnerMainShell(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminMainShell(),
        ),
        GoRoute(
          path: '/pets/form',
          builder: (context, state) {
            final pet = state.extra as PetModel?;
            return PetFormView(pet: pet);
          },
        ),
        GoRoute(
          path: '/pets/detail',
          builder: (context, state) {
            final pet = state.extra as PetModel;
            return PetDetailView(pet: pet);
          },
        ),
        GoRoute(
          path: '/appointments/form',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is AppointmentModel) {
              return AppointmentFormView(appointment: extra);
            }
            return AppointmentFormView(initialPetId: extra as String?);
          },
        ),
        GoRoute(
          path: '/records/form',
          builder: (context, state) {
            final record = state.extra as MedicalRecordModel?;
            return RecordFormView(record: record);
          },
        ),
        GoRoute(
          path: '/records/detail',
          builder: (context, state) {
            final record = state.extra as MedicalRecordModel;
            return RecordDetailView(record: record);
          },
        ),
        GoRoute(
          path: '/services/form',
          builder: (context, state) {
            final service = state.extra as ServiceModel?;
            return ServiceFormView(service: service);
          },
        ),
        GoRoute(
          path: '/vets/form',
          builder: (context, state) {
            final vet = state.extra as VeterinarianModel?;
            return VetFormView(vet: vet);
          },
        ),
        GoRoute(
          path: '/files',
          builder: (context, state) => const LocalFilesView(),
        ),
        GoRoute(
          path: '/files/viewer',
          builder: (context, state) {
            final path = state.extra as String;
            return LocalFileViewerView(filePath: path);
          },
        ),
      ],
    );
  }
}
