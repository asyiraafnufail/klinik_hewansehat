import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/appointment_model.dart';
import '../data/repositories/appointment_repository.dart';

class AppointmentViewModel extends ChangeNotifier {
  final AppointmentRepository _repo;

  List<AppointmentModel> _appointments = [];
  AppointmentStatus? _statusFilter;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _fetchSeq = 0;
  Timer? _searchDebounce;

  AppointmentViewModel({AppointmentRepository? repo})
      : _repo = repo ?? AppointmentRepository();

  List<AppointmentModel> get appointments => _appointments;
  AppointmentStatus? get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setFilter(AppointmentStatus? status) {
    if (_statusFilter == status && _appointments.isNotEmpty) return;
    _statusFilter = status;
    // Bersihkan data segera saat ganti section agar data filter lama tidak muncul sebentar
    _appointments = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    fetchAppointments();
  }

  void setSearch(String query) {
    _searchDebounce?.cancel();
    if (_searchQuery == query && _appointments.isNotEmpty) return;
    _searchQuery = query;
    _appointments = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      fetchAppointments();
    });
  }

  Future<void> fetchAppointments() async {
    final seq = ++_fetchSeq;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _repo.fetchAppointments(
        search: _searchQuery,
        statusFilter: _statusFilter,
      );
      if (seq != _fetchSeq) return;
      _appointments = results;
    } catch (e) {
      if (seq != _fetchSeq) return;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (seq == _fetchSeq) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> saveAppointment({
    String? id,
    required String petId,
    required String ownerId,
    required String? vetId,
    required String? serviceId,
    required DateTime date,
    required String time,
    required String reason,
    AppointmentStatus status = AppointmentStatus.pending,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = AppointmentModel(
        id: id ?? '',
        petId: petId,
        ownerId: ownerId,
        vetId: vetId,
        serviceId: serviceId,
        appointmentDate: date,
        appointmentTime: time,
        status: status,
        reason: reason.trim(),
      );

      if (id == null || id.isEmpty) {
        await _repo.createAppointment(item);
      } else {
        await _repo.updateAppointment(item);
      }
      await fetchAppointments();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus({
    required String id,
    required AppointmentStatus status,
    String? cancellationReason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.updateStatus(
        id: id,
        status: status,
        cancellationReason: cancellationReason,
      );
      await fetchAppointments();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAppointment(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteAppointment(id);
      _appointments.removeWhere((a) => a.id == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _searchDebounce?.cancel();
    _fetchSeq++;
    _appointments = [];
    _statusFilter = null;
    _searchQuery = '';
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
