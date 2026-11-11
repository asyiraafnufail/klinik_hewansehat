import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/profile_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;

  ProfileModel? _profile;
  List<ProfileModel> _profiles = [];
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel({AuthRepository? repo, bool listenAuth = true})
      : _repo = repo ?? AuthRepository() {
    if (listenAuth) {
      _initAuthListener();
    }
  }

  ProfileModel? get profile => _profile;
  List<ProfileModel> get profiles => _profiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _repo.currentUser != null;
  bool get isAdmin => _profile?.isAdmin ?? false;
  bool get isPetOwner => _profile?.isPetOwner ?? true;
  String? get currentUserId => _repo.currentUser?.id;

  // Syarat Panduan Kategori 1: Access Token (JWT) & Refresh Token
  String? get accessToken => _repo.accessToken;
  String? get refreshToken => _repo.refreshToken;

  void _initAuthListener() {
    // Dengarkan perubahan state auth
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        await loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _profile = null;
        _profiles = [];
        notifyListeners();
      }
    });
  }

  Future<void> fetchProfiles() async {
    try {
      _profiles = await _repo.fetchProfiles();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repo.fetchCurrentProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.signIn(email: email, password: password);
      await loadProfile();
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repo.signUp(email: email, password: password, fullName: fullName);
      if (res.session != null) {
        await loadProfile();
      }
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.signOut();
      _profile = null;
      _profiles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(Object error) {
    if (error is AuthApiException) {
      if (error.code == 'email_address_invalid') {
        return 'Format/domain email ditolak server Supabase. Gunakan email riil atau buat lewat dashboard.';
      }
      if (error.code == 'user_already_exists') {
        return 'Email sudah terdaftar, silakan gunakan email lain.';
      }
      return error.message;
    }
    final str = error.toString();
    if (str.contains('Invalid login credentials')) {
      return 'Email atau password salah';
    }
    if (str.contains('User already registered')) {
      return 'Email sudah terdaftar, silakan gunakan email lain';
    }
    return str.replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
  }
}
