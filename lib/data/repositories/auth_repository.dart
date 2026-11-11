import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthRepository {
  final SupabaseClient? _injectedClient;

  AuthRepository({SupabaseClient? client}) : _injectedClient = client;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  String? get accessToken => currentSession?.accessToken;
  String? get refreshToken => currentSession?.refreshToken;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<ProfileModel?> fetchCurrentProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<List<ProfileModel>> fetchProfiles() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('full_name', ascending: true);
    return (data as List<dynamic>)
        .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Sesi pengguna tidak valid');

    await _client.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': phone?.trim(),
    }).eq('id', uid);
  }
}
