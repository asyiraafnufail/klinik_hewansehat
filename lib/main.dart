import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/appointment_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/clinic_viewmodel.dart';
import 'viewmodels/local_file_viewmodel.dart';
import 'viewmodels/medical_record_viewmodel.dart';
import 'viewmodels/pet_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isSupabaseConfigured = false;
  if (!SupabaseConfig.url.contains('YOUR_SUPABASE') &&
      !SupabaseConfig.anonKey.contains('YOUR_SUPABASE')) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
      isSupabaseConfigured = true;
    } catch (_) {
      isSupabaseConfigured = false;
    }
  }

  runApp(KlinikApp(isConfigured: isSupabaseConfigured));
}

class KlinikApp extends StatefulWidget {
  final bool isConfigured;
  const KlinikApp({super.key, required this.isConfigured});

  @override
  State<KlinikApp> createState() => _KlinikAppState();
}

class _KlinikAppState extends State<KlinikApp> {
  AuthViewModel? _authVM;
  PetViewModel? _petVM;
  AppointmentViewModel? _apptVM;
  MedicalRecordViewModel? _recordVM;
  ClinicViewModel? _clinicVM;
  GoRouter? _router;
  RealtimeChannel? _realtimeChannel;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    if (widget.isConfigured) {
      _authVM = AuthViewModel(listenAuth: true);
      _petVM = PetViewModel();
      _apptVM = AppointmentViewModel();
      _recordVM = MedicalRecordViewModel();
      _clinicVM = ClinicViewModel();
      _router = AppRouter.createRouter(_authVM!);
      _authVM!.addListener(_onAuthChanged);
      _authVM!.loadProfile();
    }
  }

  void _onAuthChanged() {
    final auth = _authVM;
    if (auth == null) return;
    final uid = auth.currentUserId;

    if (!auth.isAuthenticated || uid == null) {
      if (_lastUserId != null) {
        _lastUserId = null;
        _unsubscribeRealtime();
        _petVM?.clear();
        _apptVM?.clear();
        _recordVM?.clear();
        _clinicVM?.clear();
      }
      return;
    }

    if (uid != _lastUserId) {
      _lastUserId = uid;
      _subscribeRealtime();
    }
  }

  void _subscribeRealtime() {
    _unsubscribeRealtime();
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('public:realtime_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            callback: (payload) {
              if (!mounted) return;
              switch (payload.table) {
                case 'pets':
                  _petVM?.fetchPets();
                  break;
                case 'appointments':
                  _apptVM?.fetchAppointments();
                  break;
                case 'medical_records':
                  _recordVM?.fetchRecords();
                  break;
                case 'services':
                  _clinicVM?.fetchServices();
                  break;
                case 'veterinarians':
                  _clinicVM?.fetchVets();
                  break;
                case 'profiles':
                  _authVM?.loadProfile();
                  if (_authVM?.isAdmin == true) {
                    _authVM?.fetchProfiles();
                  }
                  break;
              }
            },
          )
          .subscribe();
    } catch (_) {
      // Realtime optional fallback; manual & tab-switch sync tetap aktif
    }
  }

  void _unsubscribeRealtime() {
    final channel = _realtimeChannel;
    if (channel != null) {
      _realtimeChannel = null;
      try {
        Supabase.instance.client.removeChannel(channel);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _authVM?.removeListener(_onAuthChanged);
    _unsubscribeRealtime();
    _authVM?.dispose();
    _petVM?.dispose();
    _apptVM?.dispose();
    _recordVM?.dispose();
    _clinicVM?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isConfigured || _authVM == null || _router == null) {
      return MaterialApp(
        title: 'Klinik Hewan Sehat',
        theme: AppTheme.lightTheme,
        home: const _SetupConfigScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: _authVM!),
        ChangeNotifierProvider<PetViewModel>.value(value: _petVM!),
        ChangeNotifierProvider<AppointmentViewModel>.value(value: _apptVM!),
        ChangeNotifierProvider<MedicalRecordViewModel>.value(value: _recordVM!),
        ChangeNotifierProvider<ClinicViewModel>.value(value: _clinicVM!),
        ChangeNotifierProvider(create: (_) => LocalFileViewModel()),
      ],
      child: MaterialApp.router(
        title: 'Klinik Hewan Sehat',
        theme: AppTheme.lightTheme,
        routerConfig: _router!,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class _SetupConfigScreen extends StatelessWidget {
  const _SetupConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Klinik Hewan Sehat')),
      body: GlassBackground(
        child: Center(
          child: FadeSlideIn(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: AppTheme.glassBoxDecoration(radius: 24),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_sync, size: 64, color: AppTheme.primaryTeal),
                    const SizedBox(height: 16),
                    const Text(
                      'Konfigurasi Supabase Diperlukan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buka file lib/core/config/supabase_config.dart lalu masukkan Project URL dan Anon Key dari project Supabase Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'lib/core/config/supabase_config.dart',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
