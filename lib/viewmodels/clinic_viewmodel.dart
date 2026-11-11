import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/service_model.dart';
import '../data/models/veterinarian_model.dart';
import '../data/repositories/clinic_repository.dart';

class ClinicViewModel extends ChangeNotifier {
  final ClinicRepository _repo;

  List<ServiceModel> _services = [];
  List<VeterinarianModel> _vets = [];
  bool _isServicesLoading = false;
  bool _isVetsLoading = false;
  String? _errorMessage;
  int _servicesSeq = 0;
  int _vetsSeq = 0;
  Timer? _serviceDebounce;
  Timer? _vetDebounce;

  ClinicViewModel({ClinicRepository? repo}) : _repo = repo ?? ClinicRepository();

  List<ServiceModel> get services => _services;
  List<VeterinarianModel> get vets => _vets;
  bool get isLoading => _isServicesLoading || _isVetsLoading;
  bool get isServicesLoading => _isServicesLoading;
  bool get isVetsLoading => _isVetsLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAll() async {
    final sSeq = ++_servicesSeq;
    final vSeq = ++_vetsSeq;
    _isServicesLoading = true;
    _isVetsLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.fetchServices(),
        _repo.fetchVeterinarians(),
      ]);
      if (sSeq == _servicesSeq) {
        _services = results[0] as List<ServiceModel>;
      }
      if (vSeq == _vetsSeq) {
        _vets = results[1] as List<VeterinarianModel>;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (sSeq == _servicesSeq) _isServicesLoading = false;
      if (vSeq == _vetsSeq) _isVetsLoading = false;
      notifyListeners();
    }
  }

  void searchServices(String query) {
    _serviceDebounce?.cancel();
    _services = [];
    _isServicesLoading = true;
    _errorMessage = null;
    notifyListeners();

    _serviceDebounce = Timer(const Duration(milliseconds: 260), () {
      fetchServices(search: query);
    });
  }

  Future<void> fetchServices({String search = ''}) async {
    final seq = ++_servicesSeq;
    _isServicesLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _repo.fetchServices(search: search);
      if (seq != _servicesSeq) return;
      _services = res;
    } catch (e) {
      if (seq != _servicesSeq) return;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (seq == _servicesSeq) {
        _isServicesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> saveService(ServiceModel service) async {
    _isServicesLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (service.id.isEmpty) {
        await _repo.createService(service);
      } else {
        await _repo.updateService(service);
      }
      await fetchServices();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isServicesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteService(String id) async {
    _isServicesLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.deleteService(id);
      _services.removeWhere((s) => s.id == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isServicesLoading = false;
      notifyListeners();
    }
  }

  void searchVets(String query) {
    _vetDebounce?.cancel();
    _vets = [];
    _isVetsLoading = true;
    _errorMessage = null;
    notifyListeners();

    _vetDebounce = Timer(const Duration(milliseconds: 260), () {
      fetchVets(search: query);
    });
  }

  Future<void> fetchVets({String search = ''}) async {
    final seq = ++_vetsSeq;
    _isVetsLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _repo.fetchVeterinarians(search: search);
      if (seq != _vetsSeq) return;
      _vets = res;
    } catch (e) {
      if (seq != _vetsSeq) return;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (seq == _vetsSeq) {
        _isVetsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> saveVet(VeterinarianModel vet) async {
    _isVetsLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (vet.id.isEmpty) {
        await _repo.createVeterinarian(vet);
      } else {
        await _repo.updateVeterinarian(vet);
      }
      await fetchVets();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isVetsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteVet(String id) async {
    _isVetsLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repo.deleteVeterinarian(id);
      _vets.removeWhere((v) => v.id == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isVetsLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _serviceDebounce?.cancel();
    _vetDebounce?.cancel();
    _servicesSeq++;
    _vetsSeq++;
    _services = [];
    _vets = [];
    _isServicesLoading = false;
    _isVetsLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _serviceDebounce?.cancel();
    _vetDebounce?.cancel();
    super.dispose();
  }
}
