import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/storage/local_file_service.dart';
import '../data/models/medical_record_model.dart';
import '../data/repositories/medical_record_repository.dart';

class MedicalRecordViewModel extends ChangeNotifier {
  final MedicalRecordRepository _repo;
  final LocalFileService _localFileService;

  List<MedicalRecordModel> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _fetchSeq = 0;
  Timer? _searchDebounce;

  MedicalRecordViewModel({
    MedicalRecordRepository? repo,
    LocalFileService? localFileService,
  })  : _repo = repo ?? MedicalRecordRepository(),
        _localFileService = localFileService ?? LocalFileService();

  List<MedicalRecordModel> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setSearch(String query) {
    _searchDebounce?.cancel();
    _records = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      fetchRecords(search: query);
    });
  }

  Future<void> fetchRecords({String search = '', bool clearFirst = false}) async {
    final seq = ++_fetchSeq;
    if (clearFirst) {
      _records = [];
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _repo.fetchRecords(search: search);
      if (seq != _fetchSeq) return;
      _records = results;
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

  Future<bool> saveRecord({
    String? id,
    String? appointmentId,
    required String petId,
    String? vetId,
    required String diagnosis,
    required String treatment,
    String? prescription,
    String? clinicalNotes,
    required DateTime recordDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final record = MedicalRecordModel(
        id: id ?? '',
        appointmentId: appointmentId,
        petId: petId,
        vetId: vetId,
        diagnosis: diagnosis.trim(),
        treatment: treatment.trim(),
        prescription: prescription?.trim(),
        clinicalNotes: clinicalNotes?.trim(),
        recordDate: recordDate,
      );

      if (id == null || id.isEmpty) {
        await _repo.createRecord(record);
      } else {
        await _repo.updateRecord(record);
      }
      await fetchRecords();
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

  Future<bool> deleteRecord(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteRecord(id);
      _records.removeWhere((r) => r.id == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simpan ringkasan rekam medis ke file lokal perangkat (Syarat File Storage Poin 9)
  Future<String> exportToLocalFile(MedicalRecordModel record) async {
    final dateStr = record.recordDate.toIso8601String().split('T').first;
    final petSlug = (record.petName ?? 'hewan').replaceAll(' ', '_');
    final filename = 'rekam_medis_${petSlug}_$dateStr.txt';
    final file = await _localFileService.saveFile(
      filename: filename,
      content: record.toExportText(),
    );
    return file.path;
  }

  void clear() {
    _searchDebounce?.cancel();
    _fetchSeq++;
    _records = [];
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
